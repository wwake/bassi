//
//  Parser.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation
import pcombo

public class SyntaxAnalyzer {
  let maxLineNumber = 99999

  var lexer: Lexer = Lexer("")

  var tokens: [Token] = []
  var index = -1

  var token: Token {
    tokens[index]
  }

  var lineNumber = 0
  var columnNumber = 0

  let relops: [TokenType] = [.equals, .lessThan, .lessThanOrEqualTo, .notEqual, .greaterThan, .greaterThanOrEqualTo]

  let tokenToSimpleStatement: [TokenType : Statement] = [
    .end : .end,
    .remark : .skip,
    .restore : .restore,
    .return : .return,
    .stop : .stop
  ]

  var variableParser: Bind<Token, Expression> = Bind()
  var expressionParser : Bind<Token, Expression> = Bind()

  var commaVariablesParser: Bind<Token, [Expression]> = Bind()
  var assignParser: Bind<Token, Statement> = Bind()

  init() {

    defer {
      let parser =
        match(.variable) <&> <?>(
          match(.leftParend) &>
          expressionParser <&& match(.comma)
          <& match(.rightParend)
        ) |> makeVariableOrArray
      variableParser.bind(parser.parse)

      expressionParser.bind(makeExpressionParser().parse)

      let commaVariables =
        variableParser <&& match(.comma)
        <%> "At least one variable is required"
      commaVariablesParser.bind(commaVariables.parse)

      let assign =
      (  variableParser
         <& match(.equals, "Assignment is missing '='")
      ) <&> expressionParser
      |&> requireMatchingTypes
      |> { Statement.assign($0.0, $0.1) }

      assignParser.bind(assign.parse)
    }
  }

  func nextToken() {
    index += 1
  }

  fileprivate func indexOf(_ token: Token) -> Array<Token>.Index {
    return tokens.firstIndex(of: token)!
  }

  fileprivate func require(_ expected: TokenType, _ message: String) throws {
    if token.type != expected {
      throw ParseError.error(token, message)
    }
    nextToken()
  }

  // TODO - DELETE ME when the wrappers go away
  func requireVariable() throws -> String {
    guard case .variable = token.type else {
      throw ParseError.error(token, "Variable is required")
    }
    let variable = token.string!
    nextToken()
    return variable
  }

  func parse(_ input: String) -> Parse {
    lexer = Lexer(input)

    tokens = lexer.line()
    index = 0

    return singleLine()
  }

  func singleLine() -> Parse {
    do {
      return try line()
    } catch {
      if case .error(let errorToken, let message) = error as! ParseError {
        return Parse(
          errorToken.line,
          [.error(errorToken.line, errorToken.column, message)])
      }
      return Parse(0, [.error(0, 0, "\(error)")])
    }
  }

  func line() throws -> Parse  {
    if case .integer = token.type {
      let lineNumber = LineNumber(token.float)
      nextToken()

      if lineNumber <= 0 || lineNumber > maxLineNumber {
        throw ParseError.error(token, "Line number must be between 1 and \(maxLineNumber)")
      }

      let statementsParser = WrapOld(self, statement) <&& match(.colon)

      let statementParse = try WrapNew(self, statementsParser).parse()

      try require(.eol, "Extra characters at end of line")

      return Parse(LineNumber(lineNumber), statementParse)
    }
    let errorToken = token.type
    nextToken()
    throw ParseError.error(token, "Line number is required; found \(errorToken)")
  }

  func makeInputStatement(_ argument: (Token?, [Expression])) -> Statement {
    let (tokenOptional, exprs) = argument

    let prompt = tokenOptional == nil ? "" : tokenOptional!.string!

    return .input(prompt, exprs)
  }


  func oneOf(_ tokens: [TokenType], _ message : String = "Expected symbol not found") -> satisfy<Token> {
    satisfy(message) { Set(tokens).contains($0.type) }
  }

  let tokenNames : [TokenType : String] =
    [
      .leftParend: "'('",
      .rightParend : "')'",
      .variable: "variable name"
    ]

  func match(_ tokenType: TokenType) -> satisfy<Token> {
    let tokenDescription = tokenNames[tokenType] ?? "expected character"
    return match(tokenType, "Missing \(tokenDescription)")
  }

  func match(_ tokenType: TokenType, _ message: String) -> satisfy<Token> {
    return satisfy(message) { $0.type == tokenType }
  }

  func simpleStatement(_ token: Token) -> Statement {
    tokenToSimpleStatement[token.type]!
  }

  func statement() throws -> Statement {
    let oneWordStatement = oneOf([.end, .remark, .restore, .return, .stop]) |> simpleStatement

    let dataParser =
    match(.data)
    &> match(.string, "Expected a data value") <&& match(.comma)
    |> makeData


    let defPart =
    match(.def)
    &> match(.fn, "DEF requires a name of the form FNx")
    &> match(.variable, "DEF requires a name of the form FNx")
    <& match(.leftParend)

    let variablePart =
    match(.variable, "Variable is required")
    <& match(.rightParend, "DEF requires ')' after parameter")
    <& match(.equals, "DEF requires '=' after parameter definition")

    let tokens = defPart <&> variablePart

    let defineParser =
    AndThenTuple(tokens, expressionParser)
    |&> checkDefStatement


    let dim1Parser =
    (match(.variable)
     <& match(.leftParend)
    )
    <&> expressionParser <&& match(.comma)
    <& match(.rightParend)
    |> makeDimension

    let dimParser =
    match(.dim)
    &> dim1Parser <&& match(.comma)
    |> { Statement.dim($0) }


    let forParser =
    (match(.for)
     &> match(.variable)
     <& match(.equals, "'=' is required")
    )
    <&> expressionParser
    <&> (
      match(.to, "'TO' is required")
      &> expressionParser
    )
    <&> <?>(match(.step) &> expressionParser)
    |&> makeForStatement


    let gosubParser =
    match(.gosub)
    &> match(.integer, "Missing target of GOSUB")
    |> { Statement.gosub(LineNumber($0.float)) }


    let gotoParser =
    match(.goto)
    &> match(.integer, "Missing target of GOTO")
    |> { Statement.goto(LineNumber($0.float)) }


    let ifPrefix =
    match(.if)
    &> expressionParser
    <& match(.then, "Missing 'THEN'")
    |&> requireFloatType

    let ifParser =
    (ifPrefix <&> match(.integer) |&> ifGoto)
    <|>
    (ifPrefix <&> WrapOld(self, statement) <&& match(.colon)
     |&> ifStatements)


    var defaultPrompt = Token(line: 0, column: 0, type: .string)
    defaultPrompt.string = ""

    let promptPlusVariables =
    match(.string)
    <& match(.semicolon, "? Semicolon required after prompt")
    <&> commaVariablesParser

    let inputParser =
    match(.input)
    &>
    (    promptPlusVariables
         <|> inject(defaultPrompt) <&> commaVariablesParser
    )
    |> makeInputStatement


    let letParser =
    match(.let)
    &> (
      assignParser
      <%> "LET is missing variable to assign to"
    )


    let nextParser =
    match(.next)
    &> match(.variable, "Variable is required")
    |> { Statement.next($0.string) }


    let onParser =
    ( match(.on)
      &> expressionParser
    )
    <&> oneOf([.goto, .gosub], "ON statement requires GOTO or GOSUB")
    <&> (
      match(.integer) <&& match(.comma)
      <%> "ON statement requires comma-separated list of line numbers"
    )
    |> makeOnStatement


    let printParser =
    match(.print)
    &> <*>(
      ( match(.semicolon) |> { _ in Printable.thinSpace })
      <|> (match(.comma) |> { _ in Printable.tab })
      <|> (expressionParser |> { Printable.expr($0) })
      <%> "Expected start of expression"
    )
    |> makePrintStatement


    let readParser =
    match(.read) &> commaVariablesParser |> { Statement.read($0) }


    let statementParser =
    oneWordStatement
    <|> assignParser
    <|> dataParser
    <|> defineParser
    <|> dimParser
    <|> forParser
    <|> gosubParser
    <|> gotoParser
    <|> ifParser
    <|> inputParser
    <|> letParser
    <|> nextParser
    <|> onParser
    <|> printParser
    <%> "Unknown statement"

    do {
      return try WrapNew(self, oneWordStatement).parse()
    } catch {
      // fall through; let old parser handle it
    }

    var result: Statement

    switch token.type {
    case .data:
      result = try WrapNew(self, dataParser).parse()

    case .def:
      result = try WrapNew(self, defineParser).parse()

    case .dim:
      return try WrapNew(self, dimParser).parse()

    case .for:
      result = try WrapNew(self, forParser).parse()

    case .gosub:
      result = try WrapNew(self, gosubParser).parse()

    case .goto:
      result = try WrapNew(self, gotoParser).parse()

    case .`if`:
      result = try WrapNew(self, ifParser).parse()

    case .input:
      result = try WrapNew(self, inputParser).parse()

    case .`let`:
      result = try WrapNew(self, letParser).parse()

    case .next:
      result = try WrapNew(self, nextParser).parse()

    case .on:
      result = try  WrapNew(self, onParser).parse()

    case .print:
      result = try WrapNew(self, printParser).parse()

    case .read:
      result = try WrapNew(self, readParser).parse()

    case .variable:
      result = try WrapNew(self, assignParser).parse()

    default:
      nextToken()
      throw ParseError.error(token, "Unknown statement")
    }

    return result
  }

  func requireMatchingTypes(_ argument: (Expression, Expression), _ remaining: ArraySlice<Token>) -> ParseResult<Token, (Expression, Expression)> {
    let (left, right) = argument
    if left.type() != right.type() {
      return .failure(remaining.startIndex, "Type mismatch")
    }
    return .success(argument, remaining)
  }

  func makeData(_ tokens: [Token]) -> Statement {
    let strings = tokens.map { $0.string! }
    return .data(strings)
  }

  func data() throws -> Statement {
    let dataParser =
      match(.data)
    &> match(.string, "Expected a data value") <&& match(.comma)
    |> makeData

    return try WrapNew(self, dataParser).parse()
  }

  func checkDefStatement(_ argument: ((Token, Token), Expression), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Statement> {
    let (tokens, expr) = argument
    let (nameToken, parameterToken) = tokens

    let name = nameToken.string!

    if name.count != 1 {
      return .failure(indexOf(nameToken),  "DEF function name cannot be followed by extra letters")
    }

    do {
      try requireFloatType(expr)
    } catch ParseError.error(let token, let message) {
      return .failure(indexOf(token), message)
    } catch {
      return .failure(indexOf(parameterToken), "Can't happen: unexpected error in requireFloatType()")
    }

    let result = Statement.def(
      "FN"+name,
      parameterToken.string,
      expr,
      .function([.number], .number))
    return .success(result, remaining)
  }

  func ifGoto(_ argument: (Expression, Token), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Statement> {
    let (expr, token) = argument
    return .success(.ifGoto(expr, LineNumber(token.float!)), remaining)
  }

  func ifStatements(_ argument: (Expression, [Statement]), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Statement> {
    let (expr, statements) = argument
    return .success(.`if`(expr, statements), remaining)
  }

  func requireFloatType(_ expr: Expression, _ remaining: ArraySlice<Token>) -> ParseResult<Token, Expression> {
    if expr.type() == .number { return .success(expr, remaining) }

    return .failure(remaining.startIndex, "Numeric type is required")
  }

  func makeOnStatement(_ argument: ((Expression, Token), [Token])) -> Statement {
    let ((expr, typeToken), targetTokens) = argument

    let targets = targetTokens.map { LineNumber($0.float) }

    return typeToken.type == .goto
      ? .onGoto(expr, targets)
      : .onGosub(expr, targets)
  }

  func makePrintStatement(_ arguments: [Printable]) -> Statement {
    var values = arguments

    if values.count == 0 {
      return Statement.print([.newline])
    }

    if values.last! != .thinSpace && values.last != .tab {
      values.append(.newline)
    }

    return Statement.print(values)
  }

  func typeFor(_ name: String) -> `Type` {
    name.last! == "$" ? .string : .number
  }

  fileprivate func requireFloatType(_ expr: Expression) throws {
    if expr.type() != .number {
      throw ParseError.error(token, "Numeric type is required")
    }
  }

  fileprivate func requireFloatTypes(
    _ left: Expression,
    _ right: Expression) throws {
      if left.type() != .number || right.type() != .number {
        throw ParseError.error(token, "Type mismatch")
      }
    }

  fileprivate func requireMatchingTypes(
    _ left: Expression,
    _ right: Expression) throws {
      if left.type() != right.type() {
        throw ParseError.error(token, "Type mismatch")
      }
    }

  func makeExpressionParser() -> Bind<Token, Expression> {
    let parenthesizedParser =
    match(.leftParend) &> expressionParser <& match(.rightParend)

    let numberParser = match(.number) |> { Expression.number($0.float) }

    let integerParser = match(.integer) |> { Expression.number($0.float) }

    let stringParser = match(.string) |> { Expression.string($0.string!) }

    let predefFunctionParser =
    match(.predefined) <&>
    (
      match(.leftParend) &>
      expressionParser <&& match(.comma)
      <& match(.rightParend)
    )
    <&| checkPredefinedCall
    |> makePredefinedFunctionCall

    let udfFunctionParser =
    (
      match(.fn) &>
      match(.variable, "Call to FNx must have letter after FN")
      <& match(.leftParend)
    )
    <&> expressionParser
    <& match(.rightParend)
    <&| checkUserDefinedCall
    |> makeUserDefinedCall

    let factorParser =
    parenthesizedParser <|> numberParser <|> integerParser <|> stringParser
    <|> variableParser <|> predefFunctionParser <|> udfFunctionParser
    <%> "Expected start of expression"

    let powerParser =
    factorParser <&&> match(.exponent)
    <&| requireFloatTypes
    |> makeBinaryExpression

    let negationParser =
    <*>match(.minus) <&> powerParser
    <&| requireFloatType
    |> makeUnaryExpression

    let termParser =
    negationParser <&&> (match(.times) <|> match(.divide))
    <&| requireFloatTypes
    |> makeBinaryExpression

    let subexprParser =
    termParser <&&> (match(.plus) <|> match(.minus))
    <&| requireFloatTypes
    |> makeBinaryExpression

    let relationalParser =
    subexprParser <&> <?>(oneOf(relops) <&> subexprParser)
    <&| requireMatchingTypes
    |> makeRelationalExpression

    let boolNotParser =
    <*>match(.not) <&> relationalParser
    <&| requireFloatType
    |> makeUnaryExpression

    let boolAndParser =
    boolNotParser <&&> match(.and)
    <&| requireFloatTypes
    |> makeBinaryExpression

    let boolOrParser =
    boolAndParser <&&> match(.or)
    <&| requireFloatTypes
    |> makeBinaryExpression

    return Bind(boolOrParser.parse)
  }

  func requireFloatType(_ argument: ([Token], Expression)) -> (Int, String)? {
    let (tokens, expr) = argument
    if tokens.isEmpty { return nil }
    if expr.type() == .number { return nil }
    return (indexOf(tokens.last!), "Numeric type is required")
  }

  func requireMatchingTypes(_ argument: (Expression, (Token, Expression)?)) -> (Int, String)? {
    let (left, tokenRight) = argument
    if tokenRight == nil { return nil }

    let (token, right) = tokenRight!
    if left.type() == right.type() { return nil }

    return (indexOf(token), "Type mismatch")
  }

  func requireFloatTypes(_ argument: (Expression, [(Token, Expression)])) -> (Int, String)? {

    let (firstExpr, pairs) = argument
    if pairs.isEmpty { return nil }

    let (token, _) = pairs[0]
    let tokenPosition = indexOf(token)

    if firstExpr.type() != .number { return (tokenPosition, "Type mismatch")}

    let failureIndex = pairs.firstIndex { (_, expr) in
      expr.type() != .number
    }

    if failureIndex == nil { return nil }

    return (indexOf(pairs[failureIndex!].0), "Type mismatch")
  }

  func makeUnaryExpression(_ argument: ([Token], Expression)) -> Expression {
    let (tokens, expr) = argument
    if tokens.isEmpty { return expr }

    return tokens
      .reversed()
      .reduce(expr) { (exprSoFar, token) in
        .op1(token.type, exprSoFar)
    }
  }

  func makeBinaryExpression(_ argument: (Expression, [(Token, Expression)])) -> Expression {

    let (firstExpr, pairs) = argument

    return pairs.reduce(firstExpr) { (leftSoFar, opExpr) in
        let (token, right) = opExpr
        return .op2(token.type, leftSoFar, right)
    }
  }

  func makeRelationalExpression(_ argument: (Expression, (Token, Expression)?)) -> Expression {
    let (left, tokenRight) = argument
    if tokenRight == nil { return left }

    let (token, right) = tokenRight!
    return .op2(token.type, left, right)
  }

  func makeNumber(_ token: Token) -> Expression {
    return Expression.number(token.float)
  }

  func makeVariableOrArray(_ argument: (Token, [Expression]?)) -> Expression {
    let (token, exprs) = argument

    let name = token.string!
    let type : `Type` = name.last! == "$" ? .string : .number

    if exprs == nil {
      return .variable(name, type)
    }

    return .arrayAccess(name, type, exprs!)
  }

  func makePredefinedFunctionCall(_ argument: (Token, [Expression])) -> Expression {
    let (token, exprs) = argument

    let name = token.string!
    let type = token.resultType

    guard case .function(let parameterTypes, let resultType) = type else {
      return .missing // can't happen
    }

    var actualArguments = exprs
    while actualArguments.count < parameterTypes.count {
      actualArguments.append(.missing)
    }

    return .predefined(name, actualArguments, resultType)
  }

  fileprivate func predefinedFunctionCall(_ name: Name, _ type: `Type`) throws -> Expression  {

    let predefFunctionParser =
    match(.predefined) <&>
    (
      match(.leftParend) &>
        expressionParser <&& match(.comma)
      <& match(.rightParend)
     )
    <&| checkPredefinedCall
    |> makePredefinedFunctionCall

    return try WrapNew(self, predefFunctionParser).parse()
  }

  func checkPredefinedCall(_ argument: (Token, [Expression])) -> (Int, String)? {
    let (token, exprs) = argument

    let type = token.resultType

    guard case .function(let parameterTypes, _) = type else {
      return (indexOf(token), "Can't happen - predefined has inconsistent type")
    }

    var actualArguments = exprs
    while actualArguments.count < parameterTypes.count {
      actualArguments.append(.missing)
    }

    do {
      try typeCheck(token, parameterTypes, actualArguments)
    } catch ParseError.error(let token, let message) {
      return (indexOf(token) + 2, message)  // error is in args, not .predefined
    } catch {
      return (indexOf(token), "Internal error in type checking")
    }
    return nil
  }

  fileprivate func typeCheck(
    _ token: Token,
    _ parameterTypes: [`Type`],
    _ arguments: [Expression]) throws {

      if parameterTypes.count < arguments.count {
        throw ParseError.error(token, "Function not called with correct number of arguments")
      }

      try zip(parameterTypes, arguments)
        .forEach { (parameterType, argument) in
          if !isCompatible(parameterType, argument.type()) {
            throw ParseError.error(token, "Type mismatch")
          }
        }
    }

  fileprivate func isCompatible(
    _ parameterType: `Type`,
    _ argumentType: `Type`) -> Bool {
      if parameterType == argumentType {
        return true
      }
      if case .opt(let innerType) = parameterType {
        if innerType == argumentType {
          return true
        }
        if argumentType == .missing {
          return true
        }
      }
      return false
    }

  func checkUserDefinedCall(_ argument: (Token, Expression)) -> (Int, String)? {
    let (token, expr) = argument

    do {
      try typeCheck(token, [.number], [expr])
    } catch ParseError.error(let token, let message) {
      return (indexOf(token), message)
    } catch {
      return (indexOf(token), "Internal error in type checking")
    }

    return nil
  }

  func makeUserDefinedCall(_ argument: (Token, Expression)) -> Expression {
    let (token, expr) = argument
    let parameter = token.string!
    return .userdefined("FN" + parameter, expr)
  }

  func makeDimension(_ argument: (Token, [Expression])) -> DimInfo {
    let (token, dimensions) = argument

    let arrayName = token.string!
    return DimInfo(arrayName, dimensions, typeFor(arrayName))
  }

  func makeForStatement(_ argument: (((Token, Expression), Expression), Expression?), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Statement> {
    let (((variable, initial), final), stepOptional) = argument

    let step = stepOptional == nil ? Expression.number(1) : stepOptional!

    do {
      try requireFloatType(initial)
      try requireFloatType(final)
      try requireFloatType(step)
    } catch ParseError.error(let token, let message) {
      return .failure(indexOf(token), message)
    } catch {
      return .failure(0, "Can't happen: requireFloatType() failed")
    }

    let statement = Statement.for(variable.string, initial, final, step)
    return .success(statement, remaining)
  }
}
