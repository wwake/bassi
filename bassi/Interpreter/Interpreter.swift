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

  func evaluate(_ value: Expression) -> Float {

    switch value {
    case .number(let token):
      if case .integer(let i) = token {
        return Float(i)
      }
    case .op2(let token, let left, let right):
      let operand1 = evaluate(left)
      let operand2 = evaluate(right)
      if token == .plus {
        return operand1 + operand2
      } else {
        return operand1 - operand2
      }
    }

    return -1.0
  }

  func format(_ value: Expression) -> String {
    return String(format: "%.0f", evaluate(value))
  }

  fileprivate func doPrint(_ output: String, _ values : [Expression]) -> String {
    var result = output

    for value in values {
      let stringToPrint = format(value)

      result.append(stringToPrint + " ")
    }
    result.append("\n")
    return result
  }
}
