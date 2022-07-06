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

  var theToken: Token = Token(type: .unknown, line: 0, column: 0)

  var token: TokenType = .unknown
  var lineNumber = 0
  var columnNumber = 0

  let relops: [TokenType] = [.equals, .lessThan, .lessThanOrEqualTo, .notEqual, .greaterThan, .greaterThanOrEqualTo]

  func nextToken() {
    theToken = lexer.next()
    token = theToken.type
  }

  fileprivate func require(_ expected: TokenType, _ message: String) throws {
    if token != expected {
      throw ParseError.error(theToken, message)
    }
    nextToken()
  }

  func requireVariable() throws -> String {
    guard case .variable(let variable) = token else {
      throw ParseError.error(theToken, "Variable is required")
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
      if case .error(let errorToken, let message) = error as! ParseError {
        return Parse(
          errorToken.line,
          [.error(errorToken.line, errorToken.column, message)])
      }
      return Parse(0, [.error(0, 0, "\(error)")])
    }
  }

  func line() throws -> Parse  {
    if case .integer(let lineNumber) = token {
      nextToken()

      if lineNumber <= 0 || lineNumber > maxLineNumber {
        throw ParseError.error(theToken, "Line number must be between 1 and \(maxLineNumber)")
      }

      let statementParse = try statements()

      try require(.eol, "Extra characters at end of line")

      return Parse(lineNumber, statementParse)
    }
    let errorToken = token
    nextToken()
    throw ParseError.error(theToken, "Line number is required; found \(errorToken)")
  }

  func statements() throws -> [Statement] {
    let stmt = try statement()

    if token != .colon {
      return [stmt]
    }

    var statements: [Statement] = [stmt]

    while token == .colon {
      nextToken()
      statements.append(try statement())
    }

    return statements
  }

  func statement() throws -> Statement {
    var result: Statement

    switch token {
    case .def:
      result = try define()

    case .dim:
      result = try dim()

    case .for:
      result = try doFor()

    case .data:
      result = try data()

    case .end:
      nextToken()
      result = Statement.end

    case .gosub:
      result = try gosub()

    case .goto:
      result = try goto()

    case .`if`:
      result = try ifThen()

    case .input:
      nextToken()
      let variables = try commaListOfVariables()
      result = .input(variables)

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

    case .remark:
      nextToken()
      result = Statement.skip

    case .`return`:
      result = try returnStatement()

    case .variable(let name):
      result = try assign(name)

    case .stop:
      nextToken()
      result = .stop
      
    default:
      nextToken()
      throw ParseError.error(theToken, "Unknown statement")
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

    guard case let .string(contents) = token else {
      throw ParseError.error(theToken, "Expected a data value")
    }
    strings.append(contents)
    nextToken()

    while token == .comma {
      nextToken()

      guard case let .string(contents) = token else {
        throw ParseError.error(theToken, "Expected a data value")
      }
      strings.append(contents)
      nextToken()
    }

    return .data(strings)
  }

  func define() throws -> Statement {
    nextToken()

    try require(.fn, "DEF requires a name of the form FNx")

    guard case .variable(let name) = token else {
      throw ParseError.error(theToken, "DEF requires a name of the form FNx")
    }
    nextToken()

    if name.count != 1 {
      throw ParseError.error(theToken, "DEF function name cannot be followed by extra letters")
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

    if case .integer(let lineNumber) = token {
      nextToken()
      return .gosub(lineNumber)
    }

    throw ParseError.error(theToken, "Missing target of GOSUB")
  }

  func goto() throws -> Statement {
    nextToken()

    if case .integer(let lineNumber) = token {
      nextToken()
      return .goto(lineNumber)
    }
    
    throw ParseError.error(theToken, "Missing target of GOTO")
  }

  func ifThen() throws -> Statement {
    nextToken()

    let expr = try expression()
    try requireFloatType(expr)
    
    try require(.then, "Missing 'THEN'")

    if case .integer(let target) = token {
      nextToken()
      return .ifGoto(expr, target)
    }

    let statements = try statements()
    return .`if`(expr, statements)
  }

  func commaListOfVariables() throws -> [Expression] {
    var variables: [Expression] = []

    if case .variable(let name) = token {
      let variable = try variable(name)
      variables.append(variable)
    } else {
      throw ParseError.error(theToken, "At least one variable is required")
    }

    while token == .comma {
      nextToken()

      if case .variable(let name) = token {
        let variable = try variable(name)
        variables.append(variable)
      } else {
        throw ParseError.error(theToken, "At least one variable is required")
      }
    }

    return variables
  }

  func letAssign() throws -> Statement {
    nextToken()

    if case .variable(let name) = token {
      return try assign(name)
    }
    throw ParseError.error(theToken, "LET is missing variable to assign to")
  }

  func on() throws -> Statement {
    nextToken()

    let expr = try expression()

    try require(.goto, "GOTO is missing")
    
    var targets : [LineNumber] = []

    guard case .integer(let target) = token else {
      throw ParseError.error(theToken, "ON..GOTO requires at least one line number after GOTO")
    }
    nextToken()

    targets.append(target)

    while token == .comma {
      nextToken()

      guard case .integer(let target) = token else {
        throw ParseError.error(theToken, "ON..GOTO requires line number after comma")
      }
      nextToken()
      targets.append(target)
    }

    return .onGoto(expr, targets)
  }

  func printStatement() throws -> Statement {
    nextToken()

    var values: [Printable] = []

    while token != .colon && token != .eol {
      if token == .semicolon {
        nextToken()
        values.append(.thinSpace)
      } else if token == .comma {
        nextToken()
        values.append(.tab)
      } else {
        let value = try expression()
        values.append(.expr(value))
      }
    }

    if values.count == 0 {
      return Statement.print([], true)
    }

    return Statement.print(
      values,
      values.last! != .thinSpace && values.last != .tab)
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
      throw ParseError.error(theToken, "Numeric type is required")
    }
  }

  fileprivate func requireFloatTypes(
    _ left: Expression,
    _ right: Expression) throws {
      if left.type() != .number || right.type() != .number {
        throw ParseError.error(theToken, "Type mismatch")
      }
    }

  fileprivate func requireMatchingTypes(
    _ left: Expression,
    _ right: Expression) throws {
      if left.type() != right.type() {
        throw ParseError.error(theToken, "Type mismatch")
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
      throw ParseError.error(theToken, "Expected start of expression")
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

  fileprivate func predefinedFunctionCall(_ name: Name, _ type: `Type`) throws -> Expression  {
    nextToken()

    guard case .function(let parameterTypes, let resultType) = type else {
      throw ParseError.error(theToken, "Internal error: Function has non-function type")
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
        throw ParseError.error(theToken, "Function not called with correct number of arguments")
      }

      try zip(parameterTypes, arguments)
        .forEach { (parameterType, argument) in
          if !isCompatible(parameterType, argument.type()) {
            throw ParseError.error(theToken, "Type mismatch")
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
      throw ParseError.error(theToken, "Call to FNx must have letter after FN")
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

    var result: [DimInfo] = []

    let dimInfo = try dim1()
    result.append(dimInfo)

    while token == .comma {
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

    while .comma == token {
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
    if token == .step {
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
