//
//  Interpreter.swift
//  bassi
//
//  Created by Bill Wake on 5/9/22.
//

import Foundation

fileprivate func boolToFloat(
  _ x: Value,
  _ opFloat: (Float, Float) -> Bool,
  _ opString: (String, String) -> Bool,
  _ y: Value) -> Value {
    switch x {
    case .number(let number):
      return .number(opFloat(number, y.asFloat()) ? 1.0 : 0.0)
    case .string(let string):
      return .number(opString(string, y.asString()) ? 1.0 : 0.0)
    case .function,
        .userFunction(_, _, _):
      return .number(0.0)
    }
  }

extension `Type` {
  func defaultValue() -> Value {
    switch self {
    case .number:
      return Value.number(0.0)

    case .string:
      return Value.string("")

    case .function(_, _):
      return Value.string("?? Undefined function")
    }
  }
}

class Interpreter {
  static let freeSpaceCount : Float = 100_000

  let program: Program

  var lineNumber : Int
  var done = false

  typealias Store = [String : Value]
  var globals: Store = [
    "ABS" : Value.function(Fn2n(abs)),
    "ASC" : Value.function(Fs2n( {
      if $0.count == 0 { return 0}
      return Float($0.utf8.first!)
    })),
    "ATN" : Value.function(Fn2n(atan)),
    "CHR$" : Value.function(Fn2s( { _ in
      return "wrong"
    })),
    "COS" : Value.function(Fn2n(cos)),
    "EXP":
      Value.function(Fn2n(exp)),
    "FRE":
      Value.function(Fn2n({_ in Interpreter.freeSpaceCount})),
    "INT" : Value.function(Fn2n({Float(Int($0))})),
    "LEN" : Value.function(Fs2n({Float($0.count)})),
    "LOG":
      Value.function(Fn2n(log)),
    "RND" :
      Value.function(Fn2n({_ in Float.random(in: 0.0 ..< 1.0)})),
    "SGN":
      Value.function(Fn2n({
        if $0 == 0 {
          return 0.0
        } else if $0 < 0 {
          return -1.0
        }
        return 1.0
      })),
    "SIN" : Value.function(Fn2n(sin)),
    "SQR" : Value.function(Fn2n(sqrt)),
    "TAN" : Value.function(Fn2n(tan)),
  ]

  init(_ program: Program) {
    self.program = program
    lineNumber = program.firstLineNumber()
  }

  func run() -> String {
    var output = ""

    while !done {
      let line = program[lineNumber]
      lineNumber = program.lineAfter(lineNumber)
      let parse = Parser().parse(line)
      output = step(parse, output)
    }

    return output
  }

  func step(_ parse: Parse, _ output: String) -> String {

    switch parse {
    case .line(_, let statement):
      return step(statement, output)

    case .end:
      done = true
      return output

    case .skip:
      return output

    case .print(let values):
      return doPrint(output, values)

    case .goto(let newLineNumber):
      lineNumber = newLineNumber
      return output

    case .`if`(let expr, let target):
      return doIfThen(output, expr, target)

    case .assign(let variable, let expr):
      return doAssign(output, variable, expr)

    case .def(let functionName, let parameter, let definition, let theType):
      globals[functionName] = .userFunction(parameter, definition, theType)
      return output
    }
  }

  let operators1 : [Token : (Value) -> Value] =
  [
    .minus : {.number(-($0.asFloat()))},
    .not : { .number(Float(~Int16($0.asFloat()))) }
  ]

  let operators2 : [Token : (Value, Value) -> Value] =
  [.plus : {.number($0.asFloat() + $1.asFloat())},
   .minus: {.number($0.asFloat() - $1.asFloat())},
   .times: {.number($0.asFloat() * $1.asFloat())},
   .divide: {.number($0.asFloat() / $1.asFloat())},
   .exponent: { .number(pow($0.asFloat(), $1.asFloat()))},
   .equals: { boolToFloat($0, ==, ==, $1)},
   .notEqual: { boolToFloat($0, !=, !=, $1)},
   .lessThan: { boolToFloat($0, <, <, $1)},
   .lessThanOrEqualTo: { boolToFloat($0, <=, <=, $1)},
   .greaterThan: { boolToFloat($0, >, >,  $1)},
   .greaterThanOrEqualTo: { boolToFloat($0, >=, >=, $1)},
   .and: {
     let short1 = Int16($0.asFloat())
     let short2 = Int16($1.asFloat())
     return .number(Float(short1 & short2))
   },
   .or: {
     let short1 = Int16($0.asFloat())
     let short2 = Int16($1.asFloat())
     return .number(Float(short1 | short2))
   }
  ]

  func evaluate(_ value: Expression, _ store: Store) -> Value {
    switch value {
    case .number(let floatValue):
      return Value.number(floatValue)

    case .variable(let name, let theType):
      return store[name] ?? theType.defaultValue()

    case .string(let value):
      return Value.string(value)

    case .predefined(let name, let expr, _):
      return callPredefinedFunction(store, name, expr)

    case .userdefined(let name, let expr):
      return callUserDefinedFunction(store, name, expr)

    case .op1(let token, let expr):
      let operand = evaluate(expr, store)
      return operators1[token]!(operand)

    case .op2(let token, let left, let right):
      let operand1 = evaluate(left, store)
      let operand2 = evaluate(right, store)

      return operators2[token]!(operand1, operand2)
    }
  }

  fileprivate func callPredefinedFunction(_ store: Interpreter.Store, _ name: String, _ expr: Expression) -> Value {
    let function = store[name]!
    let operand = evaluate(expr, store)

    return function.apply([operand])
  }

  fileprivate func callUserDefinedFunction(_ store: Interpreter.Store, _ name: String, _ expr: Expression) -> Value {
    let operand = evaluate(expr, store)

    guard case .userFunction(let parameter, let definition, _) = store[name]! else {
      return .string("?? Internal error - function not found")
    }

    var locals = globals
    locals[parameter] = operand

    return evaluate(definition, locals)
  }

  func format(_ input: Expression) -> String {
    let value = evaluate(input, globals)
    switch value {
    case .number(let number):
      if number == Float(Int(number)) {
        return String(format: "%.0f", number)
      } else {
        return String(format: "%f", number)
      }

    case .string(let string):
      return string

    case .function:
      return "<FUNCTION>"

    case .userFunction(_, _, _):
      return "<USER-FUNCTION>"
    }
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

  fileprivate func doIfThen(_ output: String, _ expr: Expression, _ target: Int) -> String {
    let condition = evaluate(expr, globals)
    if condition != .number(0.0) {
      lineNumber = target
    }
    return output
  }

  fileprivate func doAssign(
    _ output: String,
    _ lvalue: Expression,
    _ expr: Expression)
  -> String {
    guard case .variable(let name, _) = lvalue else {
      return "?? Improper lvalue"
    }
    let value = evaluate(expr, globals)

    globals[name] = value
    return output
  }
}
