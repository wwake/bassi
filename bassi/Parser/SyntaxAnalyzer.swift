//
//  SyntaxAnalyzer.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

public class SyntaxAnalyzer {
  func parse(_ parser: BasicParser, _ tokens: ArraySlice<Token>) -> Parse {
    return parser.parse(tokens)
  }
}
