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

    case .print(let values):
      return doPrint(output, values)

    case .number(_):
      return "TODO"
    }
  }

  fileprivate func doPrint(_ output: String, _ values : [Expression]) -> String {
    var result = output

    for value in values {
      if case .number(let token) = value {
        if case .integer(let i) = token {
          result.append(String(i) + " ")
        }
      }
    }
    result.append("\n")
    return result
  }
}
