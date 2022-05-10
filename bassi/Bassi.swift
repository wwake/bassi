//
//  Bassi.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

class Bassi {
  let interpreter: Interpreter

  init(_ program: String) {
    let parser = Parser(Lexer(program))
    interpreter = Interpreter(parser.parse())
  }

  func run() -> String {
    interpreter.run()
  }
}
