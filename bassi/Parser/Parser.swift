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

  func line() throws -> Parse  {
    if case .integer(let floatValue) = token {
      let lineNumber = Int(floatValue)
      nextToken()

      let statementParse = try statement()
      return Parse.line(lineNumber, statementParse)
    }
    nextToken()
    throw ParseError.noLineNumber
  }

  func statement() throws -> Parse {
    if .remark == token {
      nextToken()
      return Parse.skip
    } else if .print == token {
      return try printStatement()
    }
    nextToken()
    throw ParseError.unknownStatement
  }

  func printStatement() throws -> Parse {
    var values: [Expression] = []

    nextToken()

    if case .integer = token {
      let value = try expression()
      values.append(value)
    }

    return Parse.print(values)
  }

  func expression() throws -> Expression {
    return try negation()
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

      if token == .rightParend {
        nextToken()
      } else {
        throw ParseError.missingRightParend
      }
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
