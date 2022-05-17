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
    }
  }

  let operators : [Token : (Float, Float) -> Float] =
  [.plus : {$0 + $1},
   .minus: {$0 - $1},
   .times: {$0 * $1},
   .divide: {$0 / $1},
   .exponent: { pow($0, $1)},
   .equals: { ($0 == $1) ? 1.0 : 0.0}
  ]

  func evaluate(_ value: Expression) -> Float {

    switch value {
    case .number(let floatValue):
        return floatValue

    case .op2(let token, let left, let right):
      let operand1 = evaluate(left)
      let operand2 = evaluate(right)

      return operators[token]!(operand1, operand2)
    }
  }

  func format(_ value: Expression) -> String {
    return String(format: "%.0f", evaluate(value))
  }

  fileprivate func doPrint(_ output: String, _ values : [Expression]) -> String {
    var result = output

    let printedOutput = values
      .map(format)
      .joined(separator: " ")

    result.append(printedOutput)
    result.append("\n")
    return result
  }
}
