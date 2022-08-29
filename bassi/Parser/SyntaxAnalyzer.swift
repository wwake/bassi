//
//  SyntaxAnalyzer.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

public class SyntaxAnalyzer {
  var parser: OldParser = OldParser(Lexer(""))

  func parse(_ lexer: Lexer) -> Parse {
    parser = OldParser(lexer)
    return parser.parse()
  }
}
