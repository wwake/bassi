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
    .stop : .stop
  ]

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

      let statementParse = try statements()

      try require(.eol, "Extra characters at end of line")

      return Parse(LineNumber(lineNumber), statementParse)
    }
    let errorToken = token.type
    nextToken()
    throw ParseError.error(token, "Line number is required; found \(errorToken)")
  }

  func statements() throws -> [Statement] {
    let stmt = try statement()

    if token.type != .colon {
      return [stmt]
    }

    var statements: [Statement] = [stmt]

    while token.type == .colon {
      nextToken()
      statements.append(try statement())
    }

    return statements
  }

  fileprivate func doInput() throws -> Statement {
    nextToken()

    var prompt: String = ""
    if case .string = token.type {
      prompt = token.string
      nextToken()
      try require(.semicolon, "? Semicolon required after prompt")
    }

    let variables = try commaListOfVariables()
    return .input(prompt, variables)
  }

  func oneOf(_ tokens: [TokenType]) -> satisfy<Token> {
    satisfy { Set(tokens).contains($0.type)}
  }

  func match(_ tokenType: TokenType) -> satisfy<Token> {
    satisfy { $0.type == tokenType }
  }

  func simpleStatement(_ token: Token) -> Statement {
    tokenToSimpleStatement[token.type]!
  }

  func statement() throws -> Statement {
    let oneWordStatement = oneOf([.end, .remark, .restore, .stop]) |> simpleStatement

    let dimStatement =  match(.dim) &> WrapOld(self, dim1) <&& match(.comma) |> { Statement.dim($0) }

    do {
      return try WrapNew(self, oneWordStatement).parse()
    } catch {
      // fall through; let old parser handle it
    }

    do {
      return try WrapNew(self, dimStatement).parse()
    } catch {
      // fall through; let old parser handle it
    }

    var result: Statement

    switch token.type {
    case .data:
      result = try data()

    case .def:
      result = try define()

    case .dim:
      print("can't happen")
      result = try dim()

    case .for:
      result = try doFor()

    case .gosub:
      result = try gosub()

    case .goto:
      result = try goto()

    case .`if`:
      result = try ifThen()

    case .input:
      result = try doInput()

    case .`let`:
      result = try letAssign()

    case .next:
      result = try doNext()

    case .on:
      result = try on()

    case .print:
      result = try printStatement()

    case .read:
      nextToken()
      let variables = try commaListOfVariables()
      result = .read(variables)

    case .`return`:
      result = try returnStatement()

    case .variable:
      let name = token.string
      result = try assign(name!)

    default:
      nextToken()
      throw ParseError.error(token, "Unknown statement")
    }

    return result
  }

  func assign(_ name: String) throws -> Statement {
    let variable = try variable(name)

    try require(.equals, "Assignment is missing '='")

    let expr = try expression()

    try requireMatchingTypes(variable, expr)

    return .assign(variable, expr)
  }

  func data() throws -> Statement {
    nextToken()

    var strings : [String] = []

    guard case .string = token.type else {
      throw ParseError.error(token, "Expected a data value")
    }
    strings.append(token.string)
    nextToken()

    while token.type == .comma {
      nextToken()

      guard case .string = token.type else {
        throw ParseError.error(token, "Expected a data value")
      }
      strings.append(token.string)
      nextToken()
    }

    return .data(strings)
  }

  func define() throws -> Statement {
    nextToken()

    try require(.fn, "DEF requires a name of the form FNx")

    guard case .variable = token.type else {
      throw ParseError.error(token, "DEF requires a name of the form FNx")
    }
    let name = token.string!
    nextToken()

    if name.count != 1 {
      throw ParseError.error(token, "DEF function name cannot be followed by extra letters")
    }

    try require(.leftParend, "Missing '('")

    let parameter = try requireVariable()

    try require(.rightParend, "DEF requires ')' after parameter")

    try require(.equals, "DEF requires '=' after parameter definition")

    let expr = try expression()
    try requireFloatType(expr)

    return .def(
      "FN"+name,
      parameter,
      expr,
      .function([.number], .number))
  }

  func gosub() throws -> Statement {
    nextToken()

    if case .integer = token.type {
      let lineNumber = LineNumber(token.float)
      nextToken()
      return .gosub(lineNumber)
    }

    throw ParseError.error(token, "Missing target of GOSUB")
  }

  func goto() throws -> Statement {
    nextToken()

    if case .integer = token.type {
      let lineNumber = LineNumber(token.float)
      nextToken()
      return .goto(lineNumber)
    }
    
    throw ParseError.error(token, "Missing target of GOTO")
  }

  func ifThen() throws -> Statement {
    nextToken()

    let expr = try expression()
    try requireFloatType(expr)
    
    try require(.then, "Missing 'THEN'")

    if case .integer = token.type {
      let target = LineNumber(token.float)
      nextToken()
      return .ifGoto(expr, target)
    }

    let statements = try statements()
    return .`if`(expr, statements)
  }

  func commaListOfVariables() throws -> [Expression] {
    var variables: [Expression] = []

    if case .variable = token.type {
      let name = token.string!
      let variable = try variable(name)
      variables.append(variable)
    } else {
      throw ParseError.error(token, "At least one variable is required")
    }

    while token.type == .comma {
      nextToken()

      if case .variable = token.type {
        let name = token.string!
        let variable = try variable(name)
        variables.append(variable)
      } else {
        throw ParseError.error(token, "At least one variable is required")
      }
    }

    return variables
  }

  func letAssign() throws -> Statement {
    nextToken()

    if case .variable = token.type {
      return try assign(token.string!)
    }
    throw ParseError.error(token, "LET is missing variable to assign to")
  }

  func on() throws -> Statement {
    nextToken()

    let expr = try expression()

    let savedToken = token.type
    if token.type != .goto && token.type != .gosub {
      throw ParseError.error(token, "ON statement requires GOTO or GOSUB")
    }
    nextToken()

    var targets : [LineNumber] = []

    guard case .integer = token.type else {
      throw ParseError.error(token, "ON requires at least one line number")
    }
    let target = LineNumber(token.float)
    nextToken()

    targets.append(target)

    while token.type == .comma {
      nextToken()

      guard case .integer = token.type else {
        throw ParseError.error(token, "ON requires line number after comma")
      }
      let target = LineNumber(token.float)
      nextToken()
      targets.append(target)
    }

    if savedToken == .goto {
      return .onGoto(expr, targets)
    } else {
      return .onGosub(expr, targets)
    }
  }

  func printStatement() throws -> Statement {
    nextToken()

    var values: [Printable] = []

    while token.type != .colon && token.type != .eol {
      if token.type == .semicolon {
        nextToken()
        values.append(.thinSpace)
      } else if token.type == .comma {
        nextToken()
        values.append(.tab)
      } else {
        let value = try expression()
        values.append(.expr(value))
      }
    }

    if values.count == 0 {
      return Statement.print([.newline])
    }

    if values.last! != .thinSpace && values.last != .tab {
      values.append(.newline)
    }

    return Statement.print(values)
  }

  func returnStatement() throws -> Statement {
    nextToken()
    return .`return`
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

  func expression() throws -> Expression {
    return try orExpr()
  }

  func orExpr() throws -> Expression {
    let termParser =
    WrapOld(self, power) <&&> (match(.times) <|> match(.divide))
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

    return try WrapNew(self, boolOrParser).parse()
  }

  func andExpr() throws -> Expression {
    let termParser =
    WrapOld(self, power) <&&> (match(.times) <|> match(.divide))
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

    return try WrapNew(self, boolAndParser).parse()
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
      return try variable(token.string!)
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

  fileprivate func variable(_ name: Name) throws -> Expression  {
    nextToken()

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

  func dim() throws -> Statement {
    nextToken()

    var result: [DimInfo] = []

    let dimInfo = try dim1()
    result.append(dimInfo)

    while token.type == .comma {
      nextToken()
      
      let dimInfo = try dim1()
      result.append(dimInfo)
    }

    return .dim(result)
  }

  func dim1() throws -> DimInfo {
    let arrayName = try requireVariable()

    try require(.leftParend, "Missing '('")

    var dimensions : [Expression] = []

    let expr = try expression()
    dimensions.append(expr)

    while .comma == token.type {
      nextToken()

      let expr = try expression()
      dimensions.append(expr)
    }

    try require(.rightParend, "Missing ')'")

    return DimInfo(arrayName, dimensions, typeFor(arrayName))
  }

  func doFor() throws -> Statement {
    nextToken()

    let variable = try requireVariable()

    try require(.equals, "'=' is required")

    let initial = try expression()
    try requireFloatType(initial)

    try require(.to, "'TO' is required")

    let final = try expression()
    try requireFloatType(final)

    var step = Expression.number(1)
    if token.type == .step {
      nextToken()
      step = try expression()
      try requireFloatType(step)
    }

    return .`for`(variable, initial, final, step)
  }

  func doNext() throws -> Statement {
    nextToken()

    let variable = try requireVariable()

    return .next(variable)
  }
}
