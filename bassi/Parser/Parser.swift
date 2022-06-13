//
//  Parser.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

public class Parser {
  let maxLineNumber = 99999

  var lexer: Lexer = Lexer("")

  var token: TokenType = .unknown
  var lineNumber = 0
  var columnNumber = 0

  let relops: [TokenType] = [.equals, .lessThan, .lessThanOrEqualTo, .notEqual, .greaterThan, .greaterThanOrEqualTo]

  func nextToken() {
    let theToken = lexer.next()
    token = theToken.type
  }

  fileprivate func require(_ expected: TokenType, _ message: String) throws {
    if token != expected {
      throw ParseError.error(message)
    }
    nextToken()
  }

  func requireVariable() throws -> String {
    guard case .variable(let variable) = token else {
      throw ParseError.error("Variable is required")
    }
    nextToken()
    return variable
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
      return .error(error as! ParseError)
    }
  }

  func line() throws -> Parse  {
    if case .integer(let lineNumber) = token {
      nextToken()

      if lineNumber <= 0 || lineNumber > maxLineNumber {
        throw ParseError.error("Line number must be between 1 and \(maxLineNumber)")
      }

      let statementParse = try statement()

      try require(.eol, "Extra characters at end of line")

      return Statement.line(lineNumber, statementParse)
    }
    let errorToken = token
    nextToken()
    throw ParseError.error("Line number is required; found \(errorToken)")
  }

  func statement() throws -> Statement {
    var result: Statement

    switch token {
    case .end:
      nextToken()
      result = Statement.end

    case .remark:
      nextToken()
      result = Statement.skip

    case .print:
      result = try printStatement()

    case .goto:
      result = try goto()

    case .ifKeyword:
      result = try ifThen()

    case .letKeyword:
      result = try letAssign()

    case .variable(let name):
      result = try assign(name)

    case .def:
      result = try define()

    case .dim:
      result = try dim()

    case .for:
      result = try doFor()

    case .next:
      result = try doNext()

    default:
      nextToken()
      throw ParseError.error("Unknown statement")
    }

    return result
  }

  func printStatement() throws -> Statement {
    nextToken()

    if token == .eol {
      return Statement.print([])
    }

    var values: [Expression] = []

    let value = try expression()
    values.append(value)

    return Statement.print(values)
  }

  func goto() throws -> Statement {
    nextToken()

    if case .integer(let lineNumber) = token {
      nextToken()
      return .goto(lineNumber)
    }
    
    throw ParseError.error("Missing target of GOTO")
  }

  func ifThen() throws -> Statement {
    nextToken()

    let expr = try expression()
    try requireFloatType(expr)
    
    try require(.then, "Missing 'THEN'")

    if case .integer(let target) = token {
      nextToken()
      return .`if`(expr, target)
    }

    throw ParseError.error("Missing target of THEN")
  }

  func letAssign() throws -> Statement {
    nextToken()

    if case .variable(let name) = token {
      return try assign(name)
    }
    throw ParseError.error("LET is missing variable to assign to")
  }

  func typeFor(_ name: String) -> `Type` {
    name.last! == "$" ? .string : .number
  }

  func assign(_ name: String) throws -> Statement {
    let variable = try variable(name)

    try require(.equals, "Assignment is missing '='")

    let expr = try expression()

    try requireMatchingTypes(variable, expr)

    return .assign(variable, expr)
  }

  func define() throws -> Statement {
    nextToken()

    try require(.fn, "DEF requires a name of the form FNx")

    guard case .variable(let name) = token else {
      throw ParseError.error("DEF requires a name of the form FNx")
    }
    nextToken()

    if name.count != 1 {
      throw ParseError.error("DEF function name cannot be followed by extra letters")
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

  fileprivate func requireFloatType(_ expr: Expression) throws {
    if expr.type() != .number {
      throw ParseError.error("Numeric type is required")
    }
  }

  fileprivate func requireFloatTypes(
    _ left: Expression,
    _ right: Expression) throws {
      if left.type() != .number || right.type() != .number {
        throw ParseError.error("Type mismatch")
      }
    }

  fileprivate func requireMatchingTypes(
    _ left: Expression,
    _ right: Expression) throws {
      if left.type() != right.type() {
        throw ParseError.error("Type mismatch")
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
      return try variable(name)
    } else if case .predefined(let name, let type) = token {
      return try predefinedFunctionCall(name, type)
    } else if case .fn = token {
      return try userdefinedFunctionCall()
    } else {
      throw ParseError.error("Expected start of expression")
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

  fileprivate func variable(_ name: String) throws -> Expression  {
    nextToken()

    let type : `Type` =
    name.last! == "$" ? .string : .number

    if token != .leftParend {
      return .variable(name, type)
    }

    var exprs: [Expression] = []

    try require(.leftParend, "Missing '('")

    let expr = try expression()
    exprs.append(expr)

    while token == .comma {
      nextToken()

      let expr = try expression()
      exprs.append(expr)
    }

    try require(.rightParend, "Missing ')'")

    return .arrayAccess(name, type, exprs)
  }

  fileprivate func predefinedFunctionCall(_ name: String, _ type: `Type`) throws -> Expression  {
    nextToken()

    guard case .function(let parameterTypes, let resultType) = type else {
      throw ParseError.error("Internal error: Function has non-function type")
    }

    try require(.leftParend, "Missing '('")

    var exprs: [Expression] = []
    exprs.append(try expression())

    while token == .comma {
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
        throw ParseError.error("Function not called with correct number of arguments")
      }

      try zip(parameterTypes, arguments)
        .forEach { (parameterType, argument) in
          if !isCompatible(parameterType, argument.type()) {
            throw ParseError.error("Type mismatch")
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


  fileprivate func userdefinedFunctionCall()  throws -> Expression {
    nextToken()

    guard case .variable(let parameter) = token else {
      throw ParseError.error("Call to FNx must have letter after FN")
    }
    nextToken()

    try require(.leftParend, "Missing '('")

    let expr = try expression()

    try require(.rightParend, "Missing ')'")

    try typeCheck([.number], [expr])

    return .userdefined("FN" + parameter, expr)
  }

  func dim() throws -> Statement {
    nextToken()

    let arrayName = try requireVariable()

    try require(.leftParend, "Missing '('")

    var dimensions : [Int] = []

    guard case .integer(let size) = token else {
      throw ParseError.error("Integer dimension size is required")
    }
    nextToken()
    dimensions.append(size + 1)

    while .comma == token {
      nextToken()

      guard case .integer(let size) = token else {
        throw ParseError.error("Integer dimension size is required")
      }
      nextToken()
      dimensions.append(size + 1)
    }

    try require(.rightParend, "Missing ')'")

    return .dim(arrayName, dimensions, typeFor(arrayName))
  }

  func doFor() throws -> Statement {
    nextToken()

    let variable = try requireVariable()

    try require(.equals, "'=' is required")

    let initial = try expression()

    try require(.to, "'TO' is required")

    let final = try expression()

    var step = Expression.number(1)
    if token == .step {
      nextToken()
      step = try expression()
    }

    return .`for`(variable, initial, final, step)
  }

  func doNext() throws -> Statement {
    nextToken()

    let variable = try requireVariable()

    return .next(variable)
  }
}
