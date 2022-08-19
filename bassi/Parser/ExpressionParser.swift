//
//  ExpressionParser.swift
//  bassi
//
//  Created by Bill Wake on 8/18/22.
//

import Foundation
import pcombo

class ExpressionParser {
  let tokenNames : [TokenType : String] =
  [
    .leftParend: "'('",
    .rightParend : "')'",
    .variable: "variable name"
  ]

  let relops: [TokenType] = [.equals, .lessThan, .lessThanOrEqualTo, .notEqual, .greaterThan, .greaterThanOrEqualTo]

  var tokenMatcher: TokenMatcher

  var expressionParser : Bind<Token, Expression> = Bind()

  var match: ((TokenType, String) -> satisfy<Token>)! = nil

  var match1: ((TokenType) -> satisfy<Token>)! = nil

  var oneOf: (([TokenType], String) -> satisfy<Token>)! = nil

  var indexOf: (Token) -> Array<Token>.Index

  init(_ tokenMatcher: TokenMatcher) {
    self.tokenMatcher = tokenMatcher
    self.match = tokenMatcher.match
    self.match1 = tokenMatcher.match1
    self.oneOf = tokenMatcher.oneOf
    self.indexOf = tokenMatcher.indexOf
  }

  func make() -> Bind<Token, Expression> {
    let parenthesizedParser =
    match1(.leftParend) &> expressionParser <& match1(.rightParend)

    let numberParser = match1(.number) |> { Expression.number($0.float) }

    let integerParser = match1(.integer) |> { Expression.number($0.float) }

    let stringParser = match1(.string) |> { Expression.string($0.string!) }

    let predefFunctionParser =
    match1(.predefined) <&>
    (
      match1(.leftParend) &>
      expressionParser <&& match1(.comma)
      <& match1(.rightParend)
    )
    |&> checkPredefinedCall
    |> makePredefinedFunctionCall

    let udfFunctionParser =
    (
      match1(.fn) &>
      match(.variable, "Call to FNx must have letter after FN")
      <& match1(.leftParend)
    )
    <&> expressionParser
    <& match1(.rightParend)
    |&> checkUserDefinedCall
    |> makeUserDefinedCall

    let variableParser =
    match1(.variable) <&> <?>(
      match1(.leftParend) &>
      expressionParser <&& match1(.comma)
      <& match1(.rightParend)
    ) |> makeVariableOrArray

    let factorParser =
    parenthesizedParser <|> numberParser <|> integerParser <|> stringParser
    <|> variableParser <|> predefFunctionParser <|> udfFunctionParser
    <%> "Expected start of expression"

    let powerParser =
    factorParser <&&> match1(.exponent)
    |&> makeNumericBinaryExpression

    let negationParser =
    powerParser
    <|> <+>match1(.minus) <&> (powerParser |&> requireFloatType)
    |> makeUnaryExpression

    let termParser =
    negationParser <&&> (match1(.times) <|> match1(.divide))
    |&> makeNumericBinaryExpression

    let subexprParser =
    termParser <&&> (match1(.plus) <|> match1(.minus))
    |&> makeNumericBinaryExpression

    let relationalParser =
    subexprParser <&> <?>(oneOf(relops, "Expected relational operator") <&> subexprParser)
    |&> requireMatchingTypes
    |> makeRelationalExpression

    let boolNotParser =
    relationalParser
    <|> <+>match1(.not) <&> (relationalParser |&> requireFloatType)
    |> makeUnaryExpression

    let boolAndParser =
    boolNotParser <&&> match1(.and)
    |&> makeNumericBinaryExpression

    let boolOrParser =
    boolAndParser <&&> match1(.or)
    |&> makeNumericBinaryExpression

    expressionParser.bind(boolOrParser.parse)
    return expressionParser
  }

  func checkPredefinedCall(_ argument: (Token, [Expression]), _ remaining: ArraySlice<Token>) -> ParseResult<Token, (Token, [Expression])> {
    let (token, exprs) = argument

    let type = token.resultType

    guard case .function(let parameterTypes, _) = type else {
      return .failure(indexOf(token), "Can't happen - predefined has inconsistent type")
    }

    var actualArguments = exprs
    while actualArguments.count < parameterTypes.count {
      actualArguments.append(.missing)
    }

    do {
      try typeCheck(token, parameterTypes, actualArguments)
    } catch ParseError.error(let token, let message) {
      return .failure(indexOf(token) + 2, message)  // error is in args, not .predefined
    } catch {
      return .failure(indexOf(token), "Internal error in type checking")
    }
    return .success(argument, remaining)

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

  func makeNumericBinaryExpression(_ argument: (Expression, [(Token, Expression)]), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Expression> {
    let (firstExpr, pairs) = argument
    if pairs.isEmpty {
      return .success(firstExpr, remaining)
    }

    let (token, _) = pairs[0]
    let tokenPosition = tokenMatcher.indexOf(token)

    if firstExpr.type() != .number {
      return .failure(tokenPosition, "Type mismatch")
    }

    let failureIndex = pairs.firstIndex { (_, expr) in
      expr.type() != .number
    }

    if failureIndex != nil {
      return .failure(tokenMatcher.indexOf(pairs[failureIndex!].0), "Type mismatch")
    }

    return .success(makeBinaryExpression(argument), remaining)
  }

  func makeBinaryExpression(_ argument: (Expression, [(Token, Expression)])) -> Expression {
    let (firstExpr, pairs) = argument

    return pairs.reduce(firstExpr) { (leftSoFar, opExpr) in
      let (token, right) = opExpr
      return .op2(token.type, leftSoFar, right)
    }
  }

  func makeNumber(_ token: Token) -> Expression {
    return Expression.number(token.float)
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

  func makeRelationalExpression(_ argument: (Expression, (Token, Expression)?)) -> Expression {
    let (left, tokenRight) = argument
    if tokenRight == nil { return left }

    let (token, right) = tokenRight!
    return .op2(token.type, left, right)
  }

  func checkUserDefinedCall(_ argument: (Token, Expression), _ remaining: ArraySlice<Token>) -> ParseResult<Token, (Token, Expression)> {
    let (token, expr) = argument

    do {
      try typeCheck(token, [.number], [expr])
    } catch ParseError.error(let token, let message) {
      return .failure(indexOf(token), message)
    } catch {
      return .failure(indexOf(token), "Internal error in type checking")
    }

    return .success(argument, remaining)
  }

  func makeUserDefinedCall(_ argument: (Token, Expression)) -> Expression {
    let (token, expr) = argument
    let parameter = token.string!
    return .userdefined("FN" + parameter, expr)
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

  func requireFloatType(_ expr: Expression, _ remaining: ArraySlice<Token>) -> ParseResult<Token, Expression> {
    if expr.type() == .number { return .success(expr, remaining) }

    return .failure(remaining.startIndex, "Numeric type is required")
  }

  func requireMatchingTypes(_ argument: (Expression, (Token, Expression)?), _ remaining: ArraySlice<Token>) -> ParseResult<Token, (Expression, (Token, Expression)?)> {

    let (left, tokenRight) = argument
    if tokenRight == nil {
      return .success(argument, remaining)
    }

    let (token, right) = tokenRight!
    if left.type() == right.type() {
      return .success(argument, remaining)
    }

    return .failure(tokenMatcher.indexOf(token), "Type mismatch")
  }

  func requireMatchingTypes(_ argument: (Expression, Expression), _ remaining: ArraySlice<Token>) -> ParseResult<Token, (Expression, Expression)> {
    let (left, right) = argument

    if left.type() != right.type() {
      return .failure(remaining.startIndex, "Type mismatch")
    }
    return .success(argument, remaining)
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
          if !argument.type().isCompatible(parameterType) {
            throw ParseError.error(token, "Type mismatch")
          }
        }
    }


}
