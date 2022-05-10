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
  
  func run(_ program: String) -> String {
    return ""
  }

  func run() -> String {
    interpret1(parse, "")
  }

  func interpret1(_ parse: Parse, _ output: String) -> String {

    switch parse {
    case .error(let message):
      return output + message + "\n"

    case .program(let lines):
      return interpret1(lines[0], output)

    case .line(_, let statement):
      return interpret1(statement, output)

    case .skip:
      return output
    }
  }
}
