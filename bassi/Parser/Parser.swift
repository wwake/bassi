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
}

public class Parser {
  let lexer: Lexer
  var token: Token
  var errorMessages: [ParseError] = []

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
    if case .integer = token {
      let lineNumber = token
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
    try factor()
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
    } else {
      let value = Expression.number(token)
      nextToken()
      return value
    }
  }
}
