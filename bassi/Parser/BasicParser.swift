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

    let variableParser =
    (
      match(.variable, "Expected variable")
      |> { ($0.string!, $0.string!.last! == "$" ? Type.string : .number)}
    )
    <&> <?>(
      match(.leftParend)
      &> expressionParser <&& match(.comma)
      <& match(.rightParend)
    )
    |> { (nameType, exprs) -> Expression in
      let (name, type) = nameType
      guard let exprs = exprs else {
        return .variable(name, type)
      }
      return .arrayAccess(name, type, exprs)
    }

    let parenthesizedParser =
    match(.leftParend) &> expressionParser <& match(.rightParend, "Missing ')'")

    let predefinedFunctionCallParser =
    match(.predefined)
    <& match(.leftParend)
    <&> expressionParser <&& match(.comma)
    <& match(.rightParend, "Missing ')'")
    |&> formPredefinedCall

    let userDefinedFunctionCallParser =
    match(.fn)
    &> match(.variable, "Call to FNx must have letter after FN")
    <& match(.leftParend, "Missing '('")
    <&> expressionParser
    <& match(.rightParend, "Missing ')'")
    |&> formUserDefinedFunctionCall

    let factorParser =
        parenthesizedParser
    <|> match(.number) |> { Expression.number($0.float) }
    <|> match(.integer) |> { Expression.number($0.float) }
    <|> match(.string) |> { Expression.string($0.string) }
    <|> variableParser
    <|> predefinedFunctionCallParser
    <|> userDefinedFunctionCallParser
    <%> "Expected start of expression"

    let powerParser =
    factorParser <&&> match(.exponent)
    |&> formNumericBinaryExpression

    let negativeParser =
    <*>match(.minus) <&> powerParser
    |&> formUnaryExpression

    let termParser =
    negativeParser <&&> oneOf(multiplyOps)
    |&> formNumericBinaryExpression

    let subexpressionParser =
    termParser <&&> oneOf(addOps)
    |&> formNumericBinaryExpression

    let relationalParser =
    subexpressionParser
    <&> <?>(oneOf(relationalOps) <&> subexpressionParser)
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

  func formPredefinedCall(
    _ tokenExprs: (Token, [Expression]),
    _ remaining: ArraySlice<Token>)
  -> ParseResult<Token, Expression> {
    let (token, exprs) = tokenExprs

    let type = token.resultType

    guard case .function(let parameterTypes, let resultType) = type else {
      preconditionFailure("Internal error: Function \(token.string!) has non-function type")
    }

    var arguments = exprs
    while arguments.count < parameterTypes.count {
      arguments.append(.missing)
    }

    do {
      try typeCheck(parameterTypes, arguments)

      return .success(
        .predefined(token.string, arguments, resultType),
        remaining)

    } catch ParseError.error(_, let message) {
      return .failure(remaining.startIndex - 2, message)
    } catch {
      return .failure(indexOf(token), "Can't happen - unexpected error \(error)")
    }
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

  func formUserDefinedFunctionCall(
    _ tokenExpr: (Token, Expression),
    _ remaining: ArraySlice<Token>)
  -> ParseResult<Token, Expression> {
    let (token, argument) = tokenExpr

    let parameter = token.string!

    do {
      try typeCheck([.number], [argument])
      return .success(.userdefined("FN" + parameter, argument), remaining)
    } catch ParseError.error(_, let message) {
      return .failure(remaining.startIndex - 2, message)
    } catch {
      return .failure(remaining.startIndex, "Unexpected error \(error)")
    }
  }
}
