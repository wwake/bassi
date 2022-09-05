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

  let relationalOps: [TokenType] = [.equals, .lessThan, .lessThanOrEqualTo, .notEqual, .greaterThan, .greaterThanOrEqualTo]

  let addOps: [TokenType] = [.plus, .minus]
  let multiplyOps: [TokenType] = [.times, .divide]


  var singleLineParser: Bind<Token, Parse>!
  var statementsParser: Bind<Token, [Statement]>!
  var expressionParser: Bind<Token, Expression>!

  init(_ lexer: Lexer) {
    self.lexer = lexer
    self.tokens = lexer.line()

    defer {
      expressionParser = makeExpressionParser()

      let statementParser = StatementParser()
      statementsParser = statementParser.makeStatementsParser(expressionParser)
      singleLineParser = statementParser.makeSingleLineParser(statementsParser)
    }
  }

  func parse() -> Parse {
    return singleLine()
  }

  func when(_ tokenType: TokenType) -> peek<satisfy<Token>> {
    peek(match(tokenType))
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

  private func oneOf(_ tokens: [TokenType], _ message: String = "Didn't find expected value") -> satisfy<Token> {
    satisfy<Token>(message) { tokens.contains($0.type) }
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

  // TODO - remove when WrapperTests goes away
  func recursiveDescent_exampleOfSuccessfulParse() throws -> Statement {
    nextToken()
    return .`return`
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

  fileprivate func makeExpressionParser() -> Bind<Token, Expression> {
    let expressionParser = Bind<Token, Expression>()

    let powerParser =
    WrapOld(self, factor) <&&> match(.exponent)
    |&> formNumericBinaryExpression

    let negativeParser =
    <*>match(.minus) <&> powerParser
    |&> formUnaryExpression(_:_:)

    let termParser =
    negativeParser <&&> oneOf(multiplyOps)
    |&> formNumericBinaryExpression

    let subexpressionParser =
    termParser <&&> oneOf(addOps)
    |&> formNumericBinaryExpression

    let relationalParser =
    subexpressionParser
    <&> <?>(oneOf(relationalOps) <&> WrapOld(self,subexpression))
    |&> formMatchingBinaryExpression

    let negationParser =
    <*>match(.not) <&> relationalParser
    |&> formUnaryExpression

    let andExprParser =
    negationParser <&&> match(.and)
    |&> formNumericBinaryExpression

    let orExprParser =
    andExprParser <&&> match(.or)
    |&> formNumericBinaryExpression

    expressionParser.bind(orExprParser.parse)
    return expressionParser
  }

  func expression() throws -> Expression {
    return try orExpr()
  }

  func formNumericBinaryExpression(_ exprTokenExprs: (Expression, Array<(Token, Expression)>), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Expression> {

    let (expr, tokenExprs) = exprTokenExprs

    if tokenExprs.count == 0 { return .success(expr, remaining) }

    guard expr.type() == .number
       && tokenExprs.allSatisfy({(_,expr) in expr.type() == .number}) else {
      return .failure(remaining.startIndex - 1, "Numeric type is required")
    }

    let result = tokenExprs.reduce(expr) { result, tokenExpr in
      let (token, expr) = tokenExpr
      return .op2(token.type, result, expr)
    }
    return .success(result, remaining)
  }

  func formMatchingBinaryExpression(
    _ expr_OptTokenExpr: (Expression, (Token, Expression)?),
    _ remaining: ArraySlice<Token>)
  -> ParseResult<Token, Expression> {
    let (expr1, tokenExpr) = expr_OptTokenExpr

    guard let tokenExpr = tokenExpr else {
      return .success(expr1, remaining)
    }

    let (token, expr2) = tokenExpr

    guard expr1.type() == expr2.type() else {
      return .failure(remaining.startIndex - 1, "Type mismatch")
    }

    let result = Expression.op2(token.type, expr1, expr2)
    return .success(result, remaining)
  }

  func formUnaryExpression(_ tokensExpr: ([Token], Expression), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Expression> {
    let (ops, expr) = tokensExpr

    if ops.count == 0 { return .success(expr, remaining) }

    guard expr.type() == .number else {
      return .failure(remaining.startIndex - 1, "Numeric type is required")
    }

    let result = ops
      .reversed()
      .reduce(expr) { (exprSoFar, op) in .op1(op.type, exprSoFar) }

    return .success(result, remaining)
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

  fileprivate func relational() throws -> Expression {
    var left = try subexpression()

    if relationalOps.contains(token.type) {
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
