//
//  Parser.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

enum ParseError: Error {
  case notYetImplemented
  case noLineNumber
  case unknownStatement

  case missingLeftParend
  case missingRightParend
  case expectedStartOfExpression
  case extraCharactersAtEol
  case missingTarget
  case missingTHEN
  case assignmentMissingEqualSign
  case letMissingAssignment
  case typeMismatch
  case floatRequired

  case DEFfunctionMustStartWithFn
  case DEFrequiresVariableAfterFn
  case DEFfunctionNameMustBeFnFollowedBySingleLetter
  case FNrequiresParameterVariable
  case DEFrequiresRightParendAfterParameter
  case DEFrequiresEqualAfterParameter
}

public class Parser {
  var lexer: Lexer = Lexer("")
  var token: Token = .unknown
  
  var errorMessages: [ParseError] = []

  let relops: [Token] = [.equals, .lessThan, .lessThanOrEqualTo, .notEqual, .greaterThan, .greaterThanOrEqualTo]

  func errors() -> [ParseError] {
    errorMessages
  }

  func nextToken() {
    token = lexer.next()!
  }

  fileprivate func require(_ expected: Token, _ error: ParseError) throws {

    if token != expected {
      throw error
    }
  }

  func parse(_ input: String) -> Parse {
    lexer = Lexer(input)
    nextToken()
    return singleLine()
  }

  func singleLine() -> Parse {
    do {
      return try line()
    } catch {
      errorMessages.append(error as! ParseError)
      return .skip
    }
  }

  func line() throws -> Parse  {
    if case .integer(let floatValue) = token {
      let lineNumber = Int(floatValue)
      nextToken()

      let statementParse = try statement()

      try require(.eol, .extraCharactersAtEol)
      nextToken()

      return Parse.line(lineNumber, statementParse)
    }
    nextToken()
    throw ParseError.noLineNumber
  }

  func statement() throws -> Parse {
    var result: Parse

    switch token {
    case .end:
      nextToken()
      result = Parse.end
    case .remark:
      nextToken()
      result = Parse.skip
    case .print:
      result = try printStatement()
    case .goto:
      result = try goto()
    case .ifKeyword:
      result = try ifThen()
    case .letKeyword:
      result = try letAssign()
    case .variable(_):
      result = try assign()
    case .def:
      result = try define()
    default:
      nextToken()
      throw ParseError.unknownStatement
    }

    return result
  }

  func printStatement() throws -> Parse {
    nextToken()

    if token == .eol {
      return Parse.print([])
    }

    var values: [Expression] = []

    let value = try expression()
    values.append(value)

    return Parse.print(values)
  }

  func goto() throws -> Parse {
    nextToken()

    if case .number(let lineNumber) = token {
      nextToken()
      return .goto(Int(lineNumber))
    }
    
    throw ParseError.missingTarget
  }

  func ifThen() throws -> Parse {
    nextToken()

    let expr = try expression()
    try requireFloatType(expr)
    
    try require(.then, .missingTHEN)
    nextToken()

    if case .integer(let target) = token {
      nextToken()
      return .`if`(expr, target)
    }

    throw ParseError.missingTarget
  }

  func letAssign() throws -> Parse {
    nextToken()

    if case .variable(_) = token {
      return try assign()
    }
    throw ParseError.letMissingAssignment
  }

  func typeFor(_ name: String) -> `Type` {
    name.last! == "$" ? .string : .float
  }

  func assign() throws -> Parse {
    guard case .variable(let name) = token else {
      return .skip /*can't happen*/
    }
    let variable = variable(name)

    try require(.equals, .assignmentMissingEqualSign)
    nextToken()

    let expr = try expression()

    try requireMatchingTypes(variable, expr)

    return .assign(variable, expr)
  }

  func define() throws -> Parse {
    nextToken()

    try require(.fn, .DEFfunctionMustStartWithFn)
    nextToken()

    guard case .variable(let name) = token else {
      throw ParseError.DEFrequiresVariableAfterFn
    }
    nextToken()

    if name.count != 1 {
      throw ParseError.DEFfunctionNameMustBeFnFollowedBySingleLetter
    }

    try require(.leftParend, .missingLeftParend)
    nextToken()

    guard case .variable(let parameter) = token else {
      throw ParseError.FNrequiresParameterVariable
    }
    nextToken()

    try require(.rightParend, .DEFrequiresRightParendAfterParameter)
    nextToken()

    try require(.equals, .DEFrequiresEqualAfterParameter)
    nextToken()

    let expr = try expression()
    try requireFloatType(expr)

    return .def(
      "FN"+name,
      parameter,
      expr,
      .function([.float], .float))
  }

  fileprivate func requireFloatType(_ expr: Expression) throws {
    if expr.type() != .float {
      throw ParseError.floatRequired
    }
  }

  fileprivate func requireFloatTypes(
    _ left: Expression,
    _ right: Expression) throws {
      if left.type() != .float || right.type() != .float {
        throw ParseError.typeMismatch
      }
    }

  fileprivate func requireMatchingTypes(
    _ left: Expression,
    _ right: Expression) throws {
      if left.type() != right.type() {
        throw ParseError.typeMismatch
      }
    }

  func expression() throws -> Expression {
    return try orExpr()
  }

  func orExpr() throws -> Expression {
    var left = try andExpr()

    while token == .or {
      let op = token
      nextToken()

      let right = try andExpr()
      try requireFloatTypes(left, right)

      left = .op2(op, left, right)
    }
    return left
  }

  func andExpr() throws -> Expression {
    var left = try negation()

    while token == .and {
      let op = token
      nextToken()

      let right = try negation()
      try requireFloatTypes(left, right)

      left = .op2(op, left, right)
    }
    return left
  }

  func negation() throws -> Expression {
    if .not == token {
      nextToken()
      let value = try negation()
      try requireFloatType(value)
      return .op1(.not, value)
    }

    return try relational()
  }

  fileprivate func relational() throws -> Expression  {
    var left = try subexpression()

    if relops.contains(token) {
      let op = token
      nextToken()

      let right = try subexpression()

      try requireMatchingTypes(left, right)
      left = .op2(op, left, right)
    }

    return left
  }

  func subexpression() throws -> Expression {
    var left = try term()

    while token == .plus || token == .minus {
      let op = token
      nextToken()

      let right = try term()

      try requireFloatTypes(left, right)

      left = .op2(op, left, right)
    }
    return left
  }

  func term() throws -> Expression {
    var left = try power()

    while token == .times || token == .divide {
      let op = token
      nextToken()

      let right = try power()

      try requireFloatTypes(left, right)
      left = .op2(op, left, right)
    }
    return left
  }

  func power() throws -> Expression {
    if .minus ==  token {
      nextToken()
      let value = try power()
      try requireFloatType(value)
      return .op1(.minus, value)
    }
    
    var left = try factor()

    while token == .exponent {
      let op = token
      nextToken()

      let right = try factor()

      try requireFloatTypes(left, right)
      left = .op2(op, left, right)
    }
    return left
  }

  func factor() throws -> Expression {
    if token == .leftParend {
      return try parenthesizedExpression()
    } else if case .number(let floatValue) = token {
      return numericFactor(floatValue)
    } else if case .string(let text) = token {
      nextToken()
      return .string(text)
    } else if case .variable(let name) = token {
      return variable(name)
    } else if case .predefined(let name) = token {
      return try predefinedFunctionCall(name)
    } else if case .fn = token {
      return try userdefinedFunctionCall()
    } else {
      throw ParseError.expectedStartOfExpression
    }
  }

  fileprivate func parenthesizedExpression() throws -> Expression {
    nextToken()

    let expr = try expression()

    try require(.rightParend, .missingRightParend)
    nextToken()

    return expr
  }

  fileprivate func numericFactor(_ floatValue: (Float)) -> Expression {
    let value = Expression.number(floatValue)
    nextToken()
    return value
  }

  fileprivate func variable(_ name: String) -> Expression {
    nextToken()
    let theType : `Type` =
    name.last! == "$" ? .string : .float
    return .variable(name, theType)
  }

  fileprivate func predefinedFunctionCall(_ name: String) throws -> Expression  {
    nextToken()

    try require(.leftParend, .missingLeftParend)
    nextToken()

    let expr = try expression()

    try require(.rightParend, .missingRightParend)
    nextToken()

    return .predefined(name, expr)
  }

  fileprivate func userdefinedFunctionCall()  throws -> Expression {
    nextToken()

    guard case .variable(let parameter) = token else {
      throw ParseError.FNrequiresParameterVariable
    }
    nextToken()

    try require(.leftParend, .missingLeftParend)
    nextToken()

    let expr = try expression()

    try require(.rightParend, .missingRightParend)
    nextToken()

    return .userdefined("FN" + parameter, expr)
  }
}
