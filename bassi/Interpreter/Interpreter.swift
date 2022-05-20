//
//  Interpreter.swift
//  bassi
//
//  Created by Bill Wake on 5/9/22.
//

import Foundation

fileprivate func boolToFloat(
  _ x: Float,
  _ op: (Float, Float) -> Bool,
  _ y: Float) -> Float {
    return op(x, y) ? 1.0 : 0.0
  }

class Interpreter {
  let program: Program

  var lineNumber : Int

  init(_ program: Program) {
    self.program = program
    lineNumber = program.firstLineNumber()
  }

  func run() -> String {
    let line = program[lineNumber]
    let parse = Parser().parse(line)
    return step(parse, "")
  }

  func step(_ parse: Parse, _ output: String) -> String {

    switch parse {
    case .line(_, let statement):
      return step(statement, output)

    case .skip:
      return output

    case .print(let values):
      return doPrint(output, values)

    case .goto(let newLineNumber):
      lineNumber = newLineNumber
      return output
    }
  }

  let operators : [Token : (Float, Float) -> Float] =
  [.plus : {$0 + $1},
   .minus: {$0 - $1},
   .times: {$0 * $1},
   .divide: {$0 / $1},
   .exponent: { pow($0, $1)},
   .equals: { boolToFloat($0, ==, $1)},
   .notEqual: { boolToFloat($0, !=, $1)},
   .lessThan: { boolToFloat($0, <, $1)},
   .lessThanOrEqualTo: { boolToFloat($0, <=, $1)},
   .greaterThan: { boolToFloat($0, >, $1)},
   .greaterThanOrEqualTo: { boolToFloat($0, >=, $1)},
   .and: {
     let short1 = Int16($0)
     let short2 = Int16($1)
     return Float(short1 & short2)
   },
   .or: {
     let short1 = Int16($0)
     let short2 = Int16($1)
     return Float(short1 | short2)
   }
  ]

  func evaluate(_ value: Expression) -> Float {
    switch value {
    case .number(let floatValue):
      return floatValue

    case .op1(let token, let expr):
      let operand = evaluate(expr)
      if token == .minus {
        return -operand
      } else if token == .not {
        let short = Int16(operand)
        return Float(~short)
      }
      print("Can't happen - not a unary operator")
      return 0

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
