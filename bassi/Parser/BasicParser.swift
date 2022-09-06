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

  var tokens : ArraySlice<Token>

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
    |&> checkOperandsNumericIfRequired
    |&> formNumericBinaryExpression

    let negativeParser =
    <*>match(.minus) <&> powerParser
    |&> formUnaryExpression

    let termParser =
    negativeParser <&&> oneOf(multiplyOps)
    |&> checkOperandsNumericIfRequired
    |&> formNumericBinaryExpression

    let subexpressionParser =
    termParser <&&> oneOf(addOps)
    |&> checkOperandsNumericIfRequired
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
    |&> checkOperandsNumericIfRequired
    |&> formNumericBinaryExpression

    let orExprParser =
    andExprParser <&&> match(.or)
    |&> checkOperandsNumericIfRequired
    |&> formNumericBinaryExpression

    expressionParser.bind(orExprParser.parse)
    return expressionParser
  }

  func checkOperandsNumericIfRequired(_ exprTokenExprs: (Expression, Array<(Token, Expression)>), _ remaining: ArraySlice<Token>) -> ParseResult<Token, (Expression, Array<(Token, Expression)>)> {

    let (expr, tokenExprs) = exprTokenExprs

    if tokenExprs.count == 0 { return .success(exprTokenExprs, remaining) }

    guard expr.type() == .number
            && tokenExprs.allSatisfy({(_,expr) in expr.type() == .number}) else {
      return .failure(remaining.startIndex - 1, "Numeric type is required")
    }

    return .success(exprTokenExprs, remaining)
  }

  func formNumericBinaryExpression(_ exprTokenExprs: (Expression, Array<(Token, Expression)>), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Expression> {

    let (expr, tokenExprs) = exprTokenExprs

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

  fileprivate func hasTooManyArguments(_ arguments: [Expression], _ parameterTypes: [Type]) -> Bool {
    return arguments.count > parameterTypes.count
  }

  fileprivate func argumentsAreCompatible(_ arguments: [Expression], _ parameterTypes: [Type]) -> Bool {
    zip(arguments, parameterTypes)
      .allSatisfy { (argument, parameterType) in
        argument.type().conformsTo(parameterType)
      }
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

    if hasTooManyArguments(arguments, parameterTypes) {
      return .failure(remaining.startIndex - 2, "Function called with too many arguments")
    }

    if !argumentsAreCompatible(arguments, parameterTypes) {
      return .failure(remaining.startIndex - 2, "Type mismatch")
    }

    return .success(
      .predefined(token.string, arguments, resultType),
      remaining)
  }

  func formUserDefinedFunctionCall(
    _ tokenExpr: (Token, Expression),
    _ remaining: ArraySlice<Token>)
  -> ParseResult<Token, Expression> {
    let (token, argument) = tokenExpr

    let parameter = token.string!

    if !argument.type().conformsTo(.number) {
      return .failure(remaining.startIndex - 2, "Type mismatch")
    }

    return .success(.userdefined("FN" + parameter, argument), remaining)
  }
}
