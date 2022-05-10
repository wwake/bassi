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
    var lines : [Parse] = []
    while token != .atEnd {
      lines.append(line())
    }
    return Parse.program(lines)
  }

  func line() -> Parse {
    if case .line = token {
      let lineNumber = token
      token = lexer.next()!

      let statementParse = statement()
      return Parse.line(lineNumber, statementParse)
    }
    return Parse.error("no line number")
  }

  func statement() -> Parse {
    if .remark == token {
      token = lexer.next()!
      return Parse.skip
    }
    return Parse.error("unknown statement")
  }
}
