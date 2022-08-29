//
//  SyntaxAnalyzer.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

public class SyntaxAnalyzer {
  var parser: Parser = OldParser(Lexer(""))

  func parse(_ lexer: Lexer) -> Parse {
    parser = OldParser(lexer)
    return parser.parse()
  }

  func parse(_ parser: Parser) -> Parse {
    self.parser = parser
    return parser.parse()
  }
}
