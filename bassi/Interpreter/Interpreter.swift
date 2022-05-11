//
//  Interpreter.swift
//  bassi
//
//  Created by Bill Wake on 5/9/22.
//

import Foundation

class Interpreter {
  let parse: Parse

  init(_ parse: Parse) {
    self.parse = parse
  }

  func run() -> String {
    interpret(parse, "")
  }

  func interpret(_ parse: Parse, _ output: String) -> String {

    switch parse {
    case .program(let lines):
      return interpret(lines[0], output)

    case .line(_, let statement):
      return interpret(statement, output)

    case .skip:
      return output

    case .print:
      return output + "\n"

    case .number(_):
      return "TODO"
    }
  }
}
