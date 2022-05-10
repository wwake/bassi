//
//  Parser.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

public class Parser {
  let lexer: Lexer
  var token: Token

  init(_ input: Lexer) {
    lexer = input
    token = lexer.next()!
  }
  
  func parse() -> Parse {
    return program()
  }

  func nextToken() {
    token = lexer.next()!
  }

  func program() -> Parse {
    var lines : [Parse] = []
    while token != .atEnd {
      lines.append(line())
    }
    return Parse.program(lines)
  }

  func line() -> Parse {
    if case .line = token {
      let lineNumber = token
      nextToken()

      let statementParse = statement()
      return Parse.line(lineNumber, statementParse)
    }
    nextToken()
    return Parse.error("no line number")
  }

  func statement() -> Parse {
    if .remark == token {
      nextToken()
      return Parse.skip
    }
    nextToken()
    return Parse.error("unknown statement")
  }
}
