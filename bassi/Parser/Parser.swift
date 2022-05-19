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
  case expectedNumberOrLeftParend
  case extraCharactersAtEol
}

public class Parser {
  let lexer: Lexer
  var token: Token
  var errorMessages: [ParseError] = []

  let relops: [Token] = [.equals, .lessThan, .lessThanOrEqualTo, .notEqual, .greaterThan, .greaterThanOrEqualTo]

  init(_ input: Lexer) {
    lexer = input
    token = lexer.next()!
  }
  
  func parse() -> Parse {
    return program()
  }

  func errors() -> [ParseError] {
    errorMessages
  }

  func nextToken() {
    token = lexer.next()!
  }

  func program() -> Parse {
    var lines : [Parse] = []
    do {
      while token != .atEnd {
        try lines.append(line())
      }
    } catch {
      errorMessages.append(error as! ParseError)
    }
    return Parse.program(lines)
  }

  fileprivate func require(_ expected: Token, _ error: ParseError) throws {

    if token != expected {
      throw error
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
    case .integer(_),
        .number(_),
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

    if case .integer(let lineNumber) = token {
      nextToken()
      return .goto(Int(lineNumber))
    }
    throw ParseError.unknownStatement
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
    } else if case .integer(let intValue) = token {

        let value = Expression.number(intValue)
        nextToken()
        return value
    } else if case .number(let floatValue) = token {
      let value = Expression.number(floatValue)
      nextToken()
      return value
    } else {
      throw ParseError.expectedNumberOrLeftParend
    }
  }
}
