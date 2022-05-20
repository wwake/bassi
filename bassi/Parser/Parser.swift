//
//  Parser.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

enum ParseError: Error {
  case noLineNumber
  case unknownStatement
  case missingRightParend
  case expectedStartOfExpression
  case extraCharactersAtEol
  case missingTarget
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
    default:
      nextToken()
      throw ParseError.unknownStatement
    }

    return result
  }

  func printStatement() throws -> Parse {
    var values: [Expression] = []

    nextToken()

    switch token {
    case
        .number(_),
        .minus,
        .leftParend,
        .not:

      let value = try expression()
      values.append(value)

    default: break
    }

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

  func expression() throws -> Expression {
    return try orExpr()
  }

  func orExpr() throws -> Expression {
    var left = try andExpr()

    while token == .or {
      let op = token
      nextToken()

      let right = try andExpr()

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

      left = .op2(op, left, right)
    }
    return left
  }

  func negation() throws -> Expression {
    if .not == token {
      nextToken()
      let value = try negation()
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

      left = .op2(op, left, right)
    }
    return left
  }

  func power() throws -> Expression {
    if .minus ==  token {
      nextToken()
      let value = try power()
      return .op1(.minus, value)
    }
    
    var left = try factor()

    while token == .exponent {
      let op = token
      nextToken()

      let right = try factor()

      left = .op2(op, left, right)
    }
    return left
  }

  func factor() throws -> Expression {
    if token == .leftParend {
      nextToken()

      let expr = try expression()

      try require(.rightParend, .missingRightParend)
      nextToken()

      return expr
    } else if case .number(let floatValue) = token {
      let value = Expression.number(floatValue)
      nextToken()
      return value
    } else {
      throw ParseError.expectedStartOfExpression
    }
  }
}
