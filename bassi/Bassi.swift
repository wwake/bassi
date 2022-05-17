//
//  Bassi.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

class Bassi {
  let interpreter: Interpreter

  init(_ program: Program) {
    let program2 = program
      .list()
      .joined(separator: "\n")
    let parser = Parser(Lexer(program2))
    interpreter = Interpreter(parser.parse())
  }

  func run() -> String {
    interpreter.run()
  }
}
