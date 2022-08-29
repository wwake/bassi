//
//  SyntaxAnalyzer.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

public class SyntaxAnalyzer {
  var lexer: Lexer = Lexer("")
  var parser: OldParser = OldParser(Lexer(""))

  func parse(_ lexer: Lexer) -> Parse {
    self.lexer = lexer
    parser = OldParser(lexer)
    return parser.parse()
  }
}
