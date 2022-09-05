//
//  BasicParser.swift
//  bassi
//
//  Created by Bill Wake on 8/29/22.
//

import Foundation
import pcombo

public class BasicParser : Parsing {
  let maxLineNumber = 99999

  var lexer: Lexer

  var token: Token {
    tokens[tokenIndex]
  }

  var tokens : ArraySlice<Token>
  var tokenIndex = 0

  var lineNumber = 0
  var columnNumber = 0

  let relops: [TokenType] = [.equals, .lessThan, .lessThanOrEqualTo, .notEqual, .greaterThan, .greaterThanOrEqualTo]

  var singleLineParser: Bind<Token, Parse>!
  var statementsParser: Bind<Token, [Statement]>!
  var expressionParser: Bind<Token, Expression>!

  init(_ lexer: Lexer) {
    self.lexer = lexer
    self.tokens = lexer.line()

    defer {
      expressionParser = makeExpressionParser()
      statementsParser = makeStatementsParser()
      singleLineParser = makeSingleLineParser()
    }
  }

  func when(_ tokenType: TokenType) -> peek<satisfy<Token>> {
    peek(match(tokenType))
  }

  fileprivate func makeDefStatement(_ nameParameterExpr: ((Token, String), Expression), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Statement> {
    let ((token, name), expr) = nameParameterExpr

    guard token.string.count == 1 else {
      return .failure(indexOf(token), "DEF function name cannot be followed by extra letters")
    }

    let statement = Statement.def(
        "FN"+token.string,
        name,
        expr,
        .function([.number], .number))

    return .success(statement, remaining)
  }

  fileprivate func makeExpressionParser() -> Bind<Token, Expression> {
    return Bind<Token, Expression>(WrapOld(self, expression).parse)
  }

  fileprivate func makeStatementsParser() -> Bind<Token, [Statement]> {
    let statementsParser = Bind<Token, [Statement]>()

    let variableParser =
    match(.variable, "Expected variable")
    <&> <?>(
      match(.leftParend, "Missing '('")
      &> expressionParser <&& match(.comma)
      <& match(.rightParend, "Missing ')'")
    )
    |> { (variableToken, exprs) -> Expression in
      let name = variableToken.string!

      let type : `Type` =
      name.last! == "$" ? .string : .number

      if (exprs == nil) {
        return .variable(name, type)
      } else {
        return .arrayAccess(name, type, exprs!)
      }
    }

    let requiredVariableParser = match(.variable, "Variable is required") |> { $0.string! }

    let assignParser =
       variableParser
    <& match(.equals, "Assignment is missing '='")
    <&> expressionParser
    |&> requireMatchingTypes
    |> { (lhs, rhs) in Statement.assign(lhs, rhs) }

    let dataParser =
    match(.data)
    &> match(.string, "Expected a data value") <&& match(.comma)
    |> { tokens in tokens.map {$0.string} }
    |> { strings in Statement.data(strings) }

    let defParser =
    match(.def)
    &>
    (  match(.fn, "DEF requires a name of the form FNx")
       &> match(.variable, "DEF requires a name of the form FNx")
       <& match(.leftParend, "Missing '('")
       <&> requiredVariableParser
       <& match(.rightParend, "DEF requires ')' after parameter")
    )
    <& match(.equals, "DEF requires '=' after parameter definition")
    <&> (expressionParser |&> requireFloatType)
    |&> makeDefStatement

    let dim1Parser =
       requiredVariableParser
    <& match(.leftParend, "Missing '('")
    <&> expressionParser <&& match(.comma)
    <& match(.rightParend, "Missing ')'")
    |> { (arrayName, dimensions) in
      return DimInfo(arrayName, dimensions, self.typeFor(arrayName))
    }

    let dimParser =
    match(.dim)
    &> dim1Parser <&& match(.comma)
    |> { Statement.dim($0) }

    let exprThenGoto =
    (expressionParser |&> requireFloatType)
    <& match(.then, "Missing 'THEN'")
    <&> match(.integer)
    |> {(expr, token) in Statement.ifGoto(expr, LineNumber(token.float))}

    let exprThenStatements =
    (expressionParser |&> requireFloatType)
    <& match(.then, "Missing 'THEN'")
    <&> statementsParser
    |> {(expr, stmts) in Statement.`if`(expr, stmts) }

    let forParser =
    match(.for)
    &> requiredVariableParser
    <& match(.equals, "'=' is required")
    <&> (expressionParser |&> requireFloatType)
    <& match(.to, "'TO' is required")
    <&> (expressionParser |&> requireFloatType)
    <&> <?>(
      match(.step)
      &> (expressionParser |&> requireFloatType)
    )
    |> { (varFromTo, stepOpt) -> Statement in
      let ((variable, initial), final) = varFromTo

      let step = stepOpt ?? Expression.number(1)
      return Statement.`for`(variable, initial, final, step)
    }

    let gosubParser =
    match(.gosub)
    &> match(.integer, "Missing target of GOSUB")
    |> { token in Statement.gosub(LineNumber(token.float))}

    let gotoParser =
    match(.goto)
    &> match(.integer, "Missing target of GOTO")
    |> { token in Statement.goto(LineNumber(token.float))}


    let ifThenParser =
    match(.if) &>
    (exprThenGoto <||> exprThenStatements <%> "Numeric type is required")

    let inputParser =
    match(.input)
    &> (<?>(match(.string) <& match(.semicolon, "? Semicolon required after prompt")))
    <&> variableParser <&& match(.comma)
    |> { (promptOpt, variables) -> Statement in
      let prompt = promptOpt?.string ?? ""
      return Statement.input(prompt, variables)
    }

    let letParser =
    match(.let) &> (assignParser <%> "LET is missing variable to assign to")

    let nextParser =
    match(.next)
    &> requiredVariableParser
    |> { Statement.next($0) }

    let onParser =
    match(.on)
    &> expressionParser
    <&> (match(.goto) <|> match(.gosub) <%> "ON statement requires GOTO or GOSUB")
    <&> (
      match(.integer, "ON requires a comma-separated list of line numbers")
      <&& match(.comma)
      |> { tokens in tokens.map {LineNumber($0.float)} }
    )
    |> { (exprGo, lineNumbers) -> Statement in
      let (expr, savedToken) = exprGo
      if savedToken.type == .goto {
        return .onGoto(expr, lineNumbers)
      } else {
        return .onGosub(expr, lineNumbers)
      }
    }

    let printParser =
    match(.print)
    &> <*>(
      (match(.semicolon) |> { _ in Printable.thinSpace })
      <|> (match(.comma) |> { _ in Printable.tab })
      <|> (expressionParser |> { Printable.expr($0) })
    )
    |> { printables -> Statement in
      var values = printables

      let needsNewline =
           values.count == 0
        || values.last! != .thinSpace && values.last != .tab

      if needsNewline {
        values.append(.newline)
      }

      return Statement.print(values)
    }

    let readParser =
       match(.read)
    &> variableParser <&& match(.comma)
    |> { exprs in Statement.read(exprs) }

    let statementParser =
        assignParser
    <|> dataParser
    <|> defParser
    <|> dimParser
    <|> match(.end) |> { _ in Statement.end }
    <|> forParser
    <|> gosubParser
    <|> gotoParser
    <|> ifThenParser
    <|> inputParser
    <|> letParser
    <|> nextParser
    <|> onParser
    <|> printParser
    <|> readParser
    <|> match(.remark) |> { _ in Statement.skip }
    <|> match(.restore) |> { _ in Statement.restore }
    <|> match(.return) |> { _ in Statement.return }
    <|> match(.stop) |> { _ in Statement.stop }
    <%> "Unknown statement"

    let theStatementsParser =
    statementParser <&& match(.colon, "Expected ':'")

    statementsParser.bind(theStatementsParser.parse)
    return statementsParser
  }

  fileprivate func makeSingleLineParser() -> Bind<Token, Parse> {
    let lineParser =
    ( match(.integer, "Line number is required")
      |&> lineNumberInRange
    )
    <&> statementsParser
    <& match(.eol, "Extra characters at end of line")
    |> {(lineNumber, statements) in Parse(lineNumber, statements)}

    return Bind<Token, Parse>(lineParser.parse)
  }

  func parse() -> Parse {
    return singleLine()
  }

  func nextToken() {
    tokenIndex += 1
  }

  func indexOf(_ token: Token) -> Int {
    tokens.firstIndex(of: token) ?? 0
  }

  fileprivate func require(_ expected: TokenType, _ message: String) throws {
    if token.type != expected {
      throw ParseError.error(token, message)
    }
    nextToken()
  }

  private func singleLine() -> Parse {
    let result = singleLineParser.parse(tokens)

    switch result {
    case .success(let parseResult, _):
      return parseResult

    case .failure(let errorIndex, let message):
      let errorToken = tokens[errorIndex]
      return Parse(
        errorToken.line,
        [.error(errorToken.line, errorToken.column, message)])
    }
  }

  private func match(_ type: TokenType, _ message: String = "Didn't find expected value") -> satisfy<Token> {
    satisfy<Token>(message) { $0.type == type }
  }

  // TODO - delete when the WrapperTest goes away
  func recursiveDescent_exampleOfFailedParse() throws -> Statement {
    nextToken()

    if case .integer = token.type {
      let lineNumber = LineNumber(token.float)
      nextToken()
      return .goto(lineNumber)
    }

    throw ParseError.error(token, "Missing target of GOTO")
  }

  func lineNumberInRange(_ token: Token, _ remaining: ArraySlice<Token>) -> ParseResult<Token, LineNumber> {
    let lineNumber = LineNumber(token.float)
    if lineNumber <= 0 || lineNumber > maxLineNumber {
      return .failure(indexOf(token), "Line number must be between 1 and \(maxLineNumber)")
    }
    return .success(lineNumber, remaining)
  }

  // TODO - remove when WrapperTests goes away
  func recursiveDescent_exampleOfSuccessfulParse() throws -> Statement {
    nextToken()
    return .`return`
  }

  func typeFor(_ name: String) -> `Type` {
    name.last! == "$" ? .string : .number
  }

  func requireFloatType(_ expr: Expression, _ remaining: ArraySlice<Token>) -> ParseResult<Token, Expression> {

    if expr.type() == .number {
      return .success(expr, remaining)
    }
    return .failure(remaining.startIndex-1, "Numeric type is required")
  }

  func requireMatchingTypes(_ exprExpr: (Expression, Expression), _ remaining: ArraySlice<Token>) -> ParseResult<Token, (Expression, Expression)> {
    let (left, right) = exprExpr

    if left.type() == right.type() {
      return .success(exprExpr, remaining)
    }

    return .failure(remaining.startIndex - 1, "Type mismatch")
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

  func expression() throws -> Expression {
    return try orExpr()
  }

  func orExpr() throws -> Expression {
    var left = try andExpr()

    while token.type == .or {
      let op = token.type
      nextToken()

      let right = try andExpr()
      try requireFloatTypes(left, right)

      left = .op2(op, left, right)
    }
    return left
  }

  func andExpr() throws -> Expression {
    var left = try negation()

    while token.type == .and {
      let op = token.type
      nextToken()

      let right = try negation()
      try requireFloatTypes(left, right)

      left = .op2(op, left, right)
    }
    return left
  }

  func negation() throws -> Expression {
    if .not == token.type {
      nextToken()
      let value = try negation()
      try requireFloatType(value)
      return .op1(.not, value)
    }

    return try relational()
  }

  fileprivate func relational() throws -> Expression  {
    var left = try subexpression()

    if relops.contains(token.type) {
      let op = token.type
      nextToken()

      let right = try subexpression()

      try requireMatchingTypes(left, right)
      left = .op2(op, left, right)
    }

    return left
  }

  func subexpression() throws -> Expression {
    var left = try term()

    while token.type == .plus || token.type == .minus {
      let op = token.type
      nextToken()

      let right = try term()

      try requireFloatTypes(left, right)

      left = .op2(op, left, right)
    }
    return left
  }

  func term() throws -> Expression {
    var left = try power()

    while token.type == .times || token.type == .divide {
      let op = token.type
      nextToken()

      let right = try power()

      try requireFloatTypes(left, right)
      left = .op2(op, left, right)
    }
    return left
  }

  func power() throws -> Expression {
    if .minus ==  token.type {
      nextToken()
      let value = try power()
      try requireFloatType(value)
      return .op1(.minus, value)
    }

    var left = try factor()

    while token.type == .exponent {
      let op = token.type
      nextToken()

      let right = try factor()

      try requireFloatTypes(left, right)
      left = .op2(op, left, right)
    }
    return left
  }

  func factor() throws -> Expression {
    if token.type == .leftParend {
      return try parenthesizedExpression()
    } else if case .number = token.type {
      return numericFactor(token.float)
    } else if case .integer = token.type {
      return numericFactor(token.float)
    } else if case .string = token.type {
      let text = token.string!
      nextToken()
      return .string(text)
    } else if case .variable = token.type {
      return try variable()
    } else if case .predefined = token.type {
      return try predefinedFunctionCall(token.string, token.resultType)
    } else if case .fn = token.type {
      return try userdefinedFunctionCall()
    } else {
      throw ParseError.error(token, "Expected start of expression")
    }
  }

  fileprivate func parenthesizedExpression() throws -> Expression {
    nextToken()

    let expr = try expression()

    try require(.rightParend, "Missing ')'")

    return expr
  }

  fileprivate func numericFactor(_ floatValue: (Float)) -> Expression {
    let value = Expression.number(floatValue)
    nextToken()
    return value
  }

  fileprivate func variable() throws -> Expression {
    let variableToken = token
    try require(.variable, "Expected variable")

    let name = variableToken.string!

    let type : `Type` =
    name.last! == "$" ? .string : .number

    if token.type != .leftParend {
      return .variable(name, type)
    }

    var exprs: [Expression] = []

    try require(.leftParend, "Missing '('")

    let expr = try expression()
    exprs.append(expr)

    while token.type == .comma {
      nextToken()

      let expr = try expression()
      exprs.append(expr)
    }

    try require(.rightParend, "Missing ')'")

    return .arrayAccess(name, type, exprs)
  }

  fileprivate func predefinedFunctionCall(_ name: Name, _ type: `Type`) throws -> Expression  {
    nextToken()

    guard case .function(let parameterTypes, let resultType) = type else {
      throw ParseError.error(token, "Internal error: Function has non-function type")
    }

    try require(.leftParend, "Missing '('")

    var exprs: [Expression] = []
    exprs.append(try expression())

    while token.type == .comma {
      nextToken()
      exprs.append(try expression())
    }

    while exprs.count < parameterTypes.count {
      exprs.append(.missing)
    }

    try require(.rightParend, "Missing ')'")

    try typeCheck(parameterTypes, exprs)

    return .predefined(name, exprs, resultType)
  }

  fileprivate func typeCheck(
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


  fileprivate func userdefinedFunctionCall() throws -> Expression {
    nextToken()

    guard case .variable = token.type else {
      throw ParseError.error(token, "Call to FNx must have letter after FN")
    }
    let parameter = token.string!
    nextToken()

    try require(.leftParend, "Missing '('")

    let expr = try expression()

    try require(.rightParend, "Missing ')'")

    try typeCheck([.number], [expr])

    return .userdefined("FN" + parameter, expr)
  }
}
