//
//  Parser+currentParser.swift
//  bassiTests
//
//  Created by Bill Wake on 8/29/22.
//

import Foundation
@testable import bassi

func currentParser(_ input: String) -> Parser {
  return BasicParser(Lexer(input))
}
