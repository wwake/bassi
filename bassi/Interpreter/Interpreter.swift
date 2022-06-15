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
    case .undefined, .function,
        .userFunction(_, _, _),
        .array:
      return .number(0.0)
    }
  }

func basicFormat(_ number: (Float)) -> String {
  if number == Float(Int(number)) {
    return String(format: "%.0f", number)
  } else {
    return String(format: "%f", number)
  }
}

fileprivate func midDollar(_ string: String, _ start: Int, _ length: Int) -> String {
  let count = string.count

  let rightCount = max(0, count - start + 1)
  let rightString = String(string.suffix(rightCount))
  return String(rightString.prefix(length))
}

func midFunction(_ arguments: [Value]) -> Value {
  let string = arguments[0].asString()
  let start = Int(arguments[1].asFloat())

  var length = string.count
  if arguments[2] != .undefined {
    length = Int(arguments[2].asFloat())
  }

  return Value.string(midDollar(
    string,
    start,
    length
  ))
}

extension `Type` {
  func defaultValue() -> Value {
    switch self {
    case .missing:
      return .undefined

    case .number:
      return Value.number(0.0)

    case .string:
      return Value.string("")

    case .function(_, _):
      return Value.string("?? Undefined function")

    case .opt(_):
      return Value.string("?? Opt type default")
    }
  }
}

enum InterpreterError: Error, Equatable {
  case error(LineNumber, String)
  case cantHappen(LineNumber, String)
}

struct Location {
  var lineNumber: LineNumber
  var sequencePoint: Int

  init(_ lineNumber: LineNumber, _ sequencePoint: Int) {
    self.lineNumber = lineNumber
    self.sequencePoint = sequencePoint
  }
}

class Interpreter {
  static let freeSpaceCount : Float = 100_000

  let program: Program
  let parser = Parser()

  var location: Location
  var lineNumber : LineNumber
  var nextLineNumber: LineNumber?

  var done = false

  typealias Store = [String : Value]

  typealias ForInfo = (String, Value, Value, LineNumber)

  var forLoopStack: [ForInfo] = []

  var returnStack: [LineNumber] = []

  var globals: Store = [
    "ABS" : Value.function(Fn2n(abs)),
    "ASC" : Value.function(Fs2n( {
      if $0.count == 0 { return 0}
      return Float($0.utf8.first!)
    })),
    "ATN" : Value.function(Fn2n(atan)),
    "CHR$" : Value.function(Fn2s( { return
      String(
        Character(
          UnicodeScalar(
            Int($0))!))
    })),
    "COS" : Value.function(Fn2n(cos)),
    "EXP":
      Value.function(Fn2n(exp)),
    "FRE":
      Value.function(Fn2n({_ in Interpreter.freeSpaceCount})),
    "INT" : Value.function(Fn2n({Float(Int($0))})),
    "LEFT$": Value.function(Fsn2s({
      String($0.prefix(Int($1)))
    })),
    "LEN" : Value.function(Fs2n({Float($0.count)})),
    "LOG":
      Value.function(Fn2n(log)),
    "MID$": Value.function(midFunction),
    "RIGHT$": Value.function(Fsn2s({
      String($0.suffix(Int($1)))
    })),
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
    "STR$": Value.function(Fn2s({
      basicFormat($0)
    })),
    "TAN" : Value.function(Fn2n(tan)),
    "VAL" : Value.function(Fs2n({Float($0) ?? 0})),
  ]

  init(_ program: Program) {
    self.program = program

    location = Location(0, 0)
    lineNumber = location.lineNumber

    nextLineNumber = program.firstLineNumber()
  }

  func run() throws -> String {
    var output = ""

    while !done {
      let temp = (nextLineNumber != nil) ? nextLineNumber! : program.lineAfter(location.lineNumber)
      location = Location(temp, 0)
      lineNumber = location.lineNumber
      nextLineNumber = nil

      guard let line = program[lineNumber] else {
        done = true
        return output + "? Attempted to execute non-existent line: \(lineNumber)\n"
      }

      let parse = parser.parse(line)

      output = try step(parse, output)
    }

    return output
  }

  func doGosub(_ subroutineLineNumber: LineNumber) throws {
    returnStack.append(program.lineAfter(lineNumber))
    doGoto(subroutineLineNumber)
  }

  func doReturn() throws {
    guard !returnStack.isEmpty else {
      throw InterpreterError.error(lineNumber, "RETURN called before GOSUB")
    }

    let returnTarget = returnStack.popLast()!
    doGoto(returnTarget)
  }

  fileprivate func doGoto(_ newLineNumber: LineNumber) {
    nextLineNumber = newLineNumber
  }

  func step(_ parse: Parse, _ output: String) throws -> String {
    let statement = parse.statement

    switch statement {
    case .error(let message):
      done = true
      return output + "? \(message)\n"

    case .assign(let variable, let expr):
      try doAssign(variable, expr)
      return output

    case .def(let functionName, let parameter, let definition, let theType):
      if globals[functionName] != nil {
        throw InterpreterError.error(lineNumber, "Can't redefine function " + functionName)
      }

      globals[functionName] = .userFunction(parameter, definition, theType)
      return output

    case .dim(let name, let dimensions, let type):
      if globals[name] != nil {
        throw InterpreterError.error(lineNumber, "Can't redeclare array " + name)
      }

      doDim(name, dimensions, type)
      return output

    case .`for`(let variable, let initial, let final, let step):
      try doFor(variable, initial, final, step)
      return output

    case .end:
      guard returnStack.isEmpty else {
        throw InterpreterError.error(lineNumber, "Ended program without returning from active subroutine")
      }
      done = true
      return output

    case .gosub(let lineNumber):
      try doGosub(lineNumber)
      return output

    case .goto(let newLineNumber):
      doGoto(newLineNumber)
      return output

    case .`if`(let expression, let statements):
      return try doIf(output, expression, statements)

    case .ifGoto(let expr, let target):
      try doIfGoto(expr, target)
      return output

    case .next(let variable):
      try doNext(variable)
      return output

    case .onGoto(let expr, let targets):
      try doOnGoto(expr, targets)
      return output

    case .print(let values):
      return try doPrint(output, values)

    case .`return`:
      try doReturn()
      return output

    case .sequence(let statements):
      return try doSequence(output, statements)
      
    case .skip:
      return output
    }
  }

  func doSequence(_ output: String, _ statements: [Statement]) throws -> String {
    var result = output
    try statements.forEach {
      result += try step(Parse(lineNumber, $0), "")
    }
    return result
  }

  let operators1 : [TokenType : (Value) -> Value] =
  [
    .minus : {.number(-($0.asFloat()))},
    .not : { .number(Float(~Int16($0.asFloat()))) }
  ]

  let operators2 : [TokenType : (Value, Value) -> Value] =
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

  func evaluate(_ value: Expression, _ store: Store) throws -> Value {
    switch value {
    case .missing:
      return .undefined

    case .number(let floatValue):
      return Value.number(floatValue)

    case .variable(let name, let theType):
      return store[name] ?? theType.defaultValue()

    case .string(let value):
      return Value.string(value)

    case .predefined(let name, let exprs, _):
      return try callPredefinedFunction(store, name, exprs)

    case .userdefined(let name, let expr):
      return try callUserDefinedFunction(store, name, expr)

    case .arrayAccess(let name, let type, let exprs):
      return try fetchArrayValue(name, store, exprs, type)

    case .op1(let token, let expr):
      let operand = try evaluate(expr, store)
      return operators1[token]!(operand)

    case .op2(let token, let left, let right):
      let operand1 = try evaluate(left, store)
      let operand2 = try evaluate(right, store)

      return operators2[token]!(operand1, operand2)
    }
  }

  fileprivate func fetchArrayValue(
    _ name: Name,
    _ store: Store,
    _ exprs: [Expression],
    _ type: `Type`) throws -> Value {
    if store[name] == nil {
      doDim(
        name,
        Array<Int>(
          repeating: 11,
          count: exprs.count),
        type)
    }

    let value = globals[name]!
    guard case .array(let dimensions, let values) = value else {
      throw InterpreterError.error(lineNumber, "Tried to subscript non-array " + name)
    }

    let index = try indexFor(exprs, store, dimensions)
    return values[index]
  }

  fileprivate func callPredefinedFunction(
    _ store: Interpreter.Store,
    _ name: Name,
    _ exprs: [Expression]) throws -> Value {

    let function = store[name]!

    let arguments = try exprs
      .map {
        try evaluate($0, store)
      }

    return function.apply(arguments)
  }

  fileprivate func callUserDefinedFunction(
    _ store: Interpreter.Store,
    _ name: Name,
    _ expr: Expression) throws -> Value {

    if store[name] == nil {
      throw InterpreterError.error(lineNumber, "Attempted call on undefined function " + name)
    }

    guard case .userFunction(let parameter, let definition, _) = store[name]! else {
      throw InterpreterError.cantHappen(lineNumber, "Function not found: " + name)
    }

    let operand = try evaluate(expr, store)

    var locals = globals
    locals[parameter] = operand

    return try evaluate(definition, locals)
  }

  func format(_ input: Expression) throws -> String {
    let value = try evaluate(input, globals)

    switch value {
    case .number(let number):
      return basicFormat(number)

    case .string(let string):
      return string

    case .undefined: return "<UNDEFINED>"

    case .function:
      return "<FUNCTION>"

    case .userFunction(_, _, _):
      return "<USER-FUNCTION>"

    case .array:
      return "Array<Value>"
    }
  }

  fileprivate func doPrint(_ output: String, _ values : [Expression]) throws -> String {
    var result = output

    let printedOutput = try values
      .map(format)
      .joined(separator: " ")

    result.append(printedOutput)
    result.append("\n")
    return result
  }

  fileprivate func doIf(_ output: String, _ expr: Expression, _ statement: Statement) throws -> String {
    let condition = try evaluate(expr, globals)

    if condition != .number(0.0) {
      return try step(Parse(lineNumber, statement), output)
    }

    return output
  }

  fileprivate func doIfGoto(_ expr: Expression, _ target: Int) throws {
    let condition = try evaluate(expr, globals)
    if condition != .number(0.0) {
      nextLineNumber = target
    }
  }

  fileprivate func doAssign(
    _ lvalue: Expression,
    _ rvalue: Expression) throws {
    switch lvalue {
    case .variable(let name, _):
      let value = try evaluate(rvalue, globals)

      globals[name] = value

    case .arrayAccess(let name, let type, let exprs):
      if globals[name] == nil {
        doDim(
          name,
          Array<Int>(
            repeating: 11,
            count: exprs.count),
          type)
      }

      guard case .array(let dimensions, let values) = globals[name]! else {
        throw InterpreterError.error(lineNumber, "Tried to subscript non-array " + name)
      }

      let index = try indexFor(exprs, globals, dimensions)

      let value = try evaluate(rvalue, globals)

      var updatedValues = values
      updatedValues[index] = value
      globals[name] = .array(dimensions, updatedValues)

    default:
      throw InterpreterError.cantHappen(lineNumber, "?? Lvalue must be either variable or array access")
    }
  }

  func doDim(
    _ name: Name,
    _ dimensions: [Int],
    _ type: `Type`) {

      let count = dimensions.reduce(1, *)

      let array : Value = .array(
        dimensions,
        Array<Value>(
          repeating: type.defaultValue(),
          count: count))

      globals[name] = array
    }

  fileprivate func indexFor(_ exprs: [Expression], _ store: Store, _ dimensions: [Int]) throws -> Int {

    let indexes = try exprs
      .map {
        try evaluate($0, store)
      }
      .map { Int($0.asFloat())}

    try indexes
      .enumerated()
      .forEach { (i, index) in
        if index < 0 || index >= dimensions[i] {
          throw InterpreterError.error(lineNumber, "array access out of bounds")
        }
      }

    return zip(indexes, dimensions)
      .dropFirst()
      .reduce(indexes[0], { (total, indexDim) in
        let (index, dim) = indexDim
        return total * dim + index
    })
  }

  func doFor(_ variable: Name, _ initial: Expression, _ final: Expression, _ step: Expression) throws {

    let typedVariable: Expression = .variable(variable, .number)
    try doAssign(typedVariable, initial)

    let limit = try evaluate(final, globals)
    let stepSize = try evaluate(step, globals)
    try doAssign(typedVariable, .op2(.minus, typedVariable, .number(stepSize.asFloat())))

    let bodyLineNumber = program.lineAfter(lineNumber)

    forLoopStack.append((variable, limit, stepSize, bodyLineNumber))

    let nextLineNumber = try findNext(with: variable)
    doGoto(nextLineNumber)
  }

  func findNext(with variable: Name) throws -> Int {
    var currentLine = program.lineAfter(lineNumber)

    while currentLine < program.maxLineNumber {
      let parse = parser.parse(program[currentLine]!)

      if case .next(let actualVariable) = parse.statement {
        if variable == actualVariable { return currentLine }
      }
      currentLine = program.lineAfter(currentLine)
    }
    throw InterpreterError.error(currentLine, "Found FOR without NEXT: \(variable)")
  }
  
  func doNext(_ variable: Name) throws {
    guard !forLoopStack.isEmpty else {
      throw InterpreterError.error(lineNumber, "Found NEXT without preceding FOR")
    }

    let (pushedName, limit, stepSize, bodyLineNumber) = forLoopStack.last!

    guard variable == pushedName else {
      throw InterpreterError.error(lineNumber, "NEXT variable must match corresponding FOR")
    }
    
    let typedVariable: Expression = .variable(variable, .number)
    let nextValue = try evaluate(.op2(.plus, typedVariable, .number(stepSize.asFloat())), globals)

    if (stepSize.asFloat() >= 0 && nextValue.asFloat() <= limit.asFloat())
    || (stepSize.asFloat() < 0 && nextValue.asFloat() >= limit.asFloat()) {

      try doAssign(typedVariable, .number(nextValue.asFloat()))
      doGoto(bodyLineNumber)
    } else {
      forLoopStack.removeLast()
    }
  }

  func doOnGoto(_ expr: Expression, _ targets: [LineNumber]) throws {
    let floatValue = try evaluate(expr, globals).asFloat()
    let value = Int(floatValue)

    guard value >= 0 else {
      throw InterpreterError.error(lineNumber, "?ILLEGAL QUANTITY")
    }
    
    if value == 0 || value > targets.count {
      return
    }

    doGoto(targets[value - 1])
  }
}
