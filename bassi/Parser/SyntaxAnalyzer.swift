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

  func parse(_ input: String) -> Parse {
    lexer = Lexer(input)
    parser = OldParser(lexer)
    return parser.parse()
  }
}
