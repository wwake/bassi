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
    interpreter = Interpreter(program)
  }

  func run() -> String {
    interpreter.run()
  }
}
