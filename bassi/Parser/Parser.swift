//
//  Parser.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

enum ParseError: Error, Equatable {
  case internalError(String)
  case unknownStatement
  case notYetImplemented

  case noLineNumber
  case lineNumberRange

  case missingLeftParend
  case missingRightParend
  case expectedStartOfExpression
  case extraCharactersAtEol
  case missingTarget
  case missingTHEN
  case assignmentMissingEqualSign
  case letMissingAssignment
  case typeMismatch
  case argumentCountMismatch

  case floatRequired

  case DEFfunctionMustStartWithFn
  case DEFrequiresVariableAfterFn
  case DEFfunctionNameMustBeFnFollowedBySingleLetter
  case FNrequiresParameterVariable
  case DEFrequiresRightParendAfterParameter
  case DEFrequiresEqualAfterParameter
}

public class Parser {
  let maxLineNumber = 99999

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
    nextToken()
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
    if case .integer(let lineNumber) = token {
      nextToken()

      if lineNumber <= 0 || lineNumber > maxLineNumber {
        throw ParseError.lineNumberRange
      }

      let statementParse = try statement()

      try require(.eol, .extraCharactersAtEol)

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

    if case .integer(let lineNumber) = token {
      nextToken()
      return .goto(lineNumber)
    }
    
    throw ParseError.missingTarget
  }

  func ifThen() throws -> Parse {
    nextToken()

    let expr = try expression()
    try requireFloatType(expr)
    
    try require(.then, .missingTHEN)

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
    name.last! == "$" ? .string : .number
  }

  func assign() throws -> Parse {
    guard case .variable(let name) = token else {
      return .skip /*can't happen*/
    }
    let variable = variable(name)

    try require(.equals, .assignmentMissingEqualSign)

    let expr = try expression()

    try requireMatchingTypes(variable, expr)

    return .assign(variable, expr)
  }

  func define() throws -> Parse {
    nextToken()

    try require(.fn, .DEFfunctionMustStartWithFn)

    guard case .variable(let name) = token else {
      throw ParseError.DEFrequiresVariableAfterFn
    }
    nextToken()

    if name.count != 1 {
      throw ParseError.DEFfunctionNameMustBeFnFollowedBySingleLetter
    }

    try require(.leftParend, .missingLeftParend)

    guard case .variable(let parameter) = token else {
      throw ParseError.FNrequiresParameterVariable
    }
    nextToken()

    try require(.rightParend, .DEFrequiresRightParendAfterParameter)

    try require(.equals, .DEFrequiresEqualAfterParameter)

    let expr = try expression()
    try requireFloatType(expr)

    return .def(
      "FN"+name,
      parameter,
      expr,
      .function([.number], .number))
  }

  fileprivate func requireFloatType(_ expr: Expression) throws {
    if expr.type() != .number {
      throw ParseError.floatRequired
    }
  }

  fileprivate func requireFloatTypes(
    _ left: Expression,
    _ right: Expression) throws {
      if left.type() != .number || right.type() != .number {
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
    } else if case .integer(let intValue) = token {
      return numericFactor(Float(intValue))
    } else if case .string(let text) = token {
      nextToken()
      return .string(text)
    } else if case .variable(let name) = token {
      return variable(name)
    } else if case .predefined(let name, let type) = token {
      return try predefinedFunctionCall(name, type)
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
    name.last! == "$" ? .string : .number
    return .variable(name, theType)
  }

  fileprivate func predefinedFunctionCall(_ name: String, _ type: `Type`) throws -> Expression  {
    nextToken()

    guard case .function(let operandTypes, let resultType) = type else {
      throw ParseError.internalError("Function has non-function type")
    }

    try require(.leftParend, .missingLeftParend)

    let expr = try expression()

    try require(.rightParend, .missingRightParend)

    try typeCheck(operandTypes, [expr])

    return .predefined(name, [expr], resultType)
  }

  fileprivate func typeCheck(_ operands: [`Type`], _ exprs: [Expression]) throws {

    if operands.count != exprs.count {
      throw ParseError.argumentCountMismatch
    }

    try operands
      .enumerated()
      .forEach { (index, parameterType) in
        if parameterType != exprs[index].type() {
          throw ParseError.typeMismatch
        }
      }
  }

  fileprivate func userdefinedFunctionCall()  throws -> Expression {
    nextToken()

    guard case .variable(let parameter) = token else {
      throw ParseError.FNrequiresParameterVariable
    }
    nextToken()

    try require(.leftParend, .missingLeftParend)

    let expr = try expression()

    try require(.rightParend, .missingRightParend)

    try typeCheck([.number], [expr])

    return .userdefined("FN" + parameter, expr)
  }
}
