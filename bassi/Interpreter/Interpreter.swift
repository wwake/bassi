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

enum InterpreterError: Error, Equatable {
  case error(LineNumber, String)
  case cantHappen(LineNumber, String)
}

class Interpreter {
  static let freeSpaceCount : Float = 100_000
  let defaultArraySize : Float = 10
  let columnsPerTab = 12

  let program: Program
  let interactor : Interactor

  let parser = Parser()
  var parse: Parse

  var location: Location
  var nextLocation: Location?

  var done = false
  var stopped = false
  var awaitingInput = false

  var data : [String] = []
  var dataIndex = 0
  
  typealias Store = [Name : Value]

  typealias ForInfo = (Name, Value, Value, Location)

  var forLoopStack: [ForInfo] = []

  var returnStack: [Location] = []

  var globals: Store = [:]

  init(_ program: Program, _ output: Interactor) {
    self.program = program
    self.interactor = output

    self.location = Location(0,0)
    self.parse = Parse(0, [])

    defer {
      globals = Predefined.functionsUsing(interactor)
    }
  }

  func nextLocationFor(_ location: Location) -> Location {
    if location.part < Statement.count(parse.statements) - 1 {
      return location.next()
    } else {
      return Location(program.lineAfter(location.lineNumber))
    }
  }

  fileprivate func shouldRun() -> Bool {
    return !done && !stopped && !awaitingInput
  }

  func run() throws {
    try gatherData()

    parse = Parse(0, [])

    location = Location(program.firstLineNumber())
    nextLocation = nil

    try runLoop()
  }

  func continueAfterStop() throws {
    stopped = false
    location = nextLocationFor(location)
    nextLocation = nil

    try runLoop()
  }

  func continueAfterInput() throws {
    awaitingInput = false
    try runLoop()
  }

  func gatherData() throws {
    program.program
      .sorted(by: <)
      .map { (lineNumber, line) in parser.parse(line) }
      .forEach { parse in
        (0..<Statement.count(parse.statements))
          .map { Statement.at(parse.statements, $0) }
          .forEach { statement in
            if case .data(let strings) = statement {
              strings.forEach {
                data.append($0)
              }
            }
          }
      }
  }

  fileprivate func runLoop() throws {
    let line = program[location.lineNumber]!
    parse = parser.parse(line)

    _ = try step(parse.statements[location.part])

    while shouldRun() {
      if nextLocation == nil {
        nextLocation = nextLocationFor(location)
      }

      if nextLocation!.lineNumber != location.lineNumber {
        guard let line = program[nextLocation!.lineNumber] else {
          interactor.append("? Attempted to execute non-existent line: \(nextLocation!.lineNumber)\n")
          return
        }

        parse = parser.parse(line)
      }

      location = nextLocation!
      nextLocation = nil

      _ = try step(
        Statement.at(parse.statements, location.part))
    }
  }

  func step(_ statement: Statement) throws {
    switch statement {
    case .error(let lineNumber, let columnNumber, let message):
      done = true
      interactor.append("?\(lineNumber):\(columnNumber) \(message)")

    case .assign(let variable, let expr):
      try doAssign(variable, expr)

    case .data(_):
      break
      
    case .def(let functionName, let parameter, let definition, let theType):
      if globals[functionName] != nil {
        throw InterpreterError.error(location.lineNumber, "Can't redefine function " + functionName)
      }

      globals[functionName] = .userFunction(parameter, definition, theType)

    case .dim(let dimInfos):
      try dimInfos.forEach {
        if globals[$0.name] != nil {
          throw InterpreterError.error(location.lineNumber, "Can't redeclare array " + $0.name)
        }

        try doDim($0.name, $0.dimensions, $0.type)
      }

    case .end:
      try doEnd()

    case .`for`(let variable, let initial, let final, let step):
      try doFor(variable, initial, final, step)

    case .gosub(let lineNumber):
      try doGosub(Location(lineNumber))

    case .goto(let newLineNumber):
      doGoto(Location(newLineNumber))

    case .`if`(let expression, _):
      try doIf(expression)

    case .ifGoto(let expr, let target):
      try doIfGoto(expr, Location(target))

    case .input(let exprs):
      try doInput(exprs)

    case .next(let variable):
      try doNext(variable)

    case .onGoto(let expr, let targets):
      try doOnGoto(expr, targets)

    case .print(let values, let shouldPrintNewline):
      try doPrint(values, shouldPrintNewline)

    case .read(let exprs):
      try doRead(exprs)

    case .restore:
      dataIndex = 0
      break

    case .`return`:
      try doReturn()

    case .skip:
      break

    case .stop:
      stopped = true
      break
    }
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
        try doDim(
          name,
          Array<Expression>(
            repeating: .number(defaultArraySize),
            count: exprs.count),
          type)
      }

      let fetched = globals[name]!
      guard case .array(let array) = fetched else {
        throw InterpreterError.error(location.lineNumber, "Tried to subscript non-array " + name)
      }

      let indexes = try exprs
        .map {
          try evaluate($0, store)
        }

      do {
        return try array.get(indexes)
      } catch ArrayError.outOfBounds {
        throw InterpreterError.error(location.lineNumber, "array access out of bounds")
      }
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
        throw InterpreterError.error(location.lineNumber, "Attempted call on undefined function " + name)
      }

      guard case .userFunction(let parameter, let definition, _) = store[name]! else {
        throw InterpreterError.cantHappen(location.lineNumber, "Function not found: " + name)
      }

      let operand = try evaluate(expr, store)

      var locals = globals
      locals[parameter] = operand

      return try evaluate(definition, locals)
    }

  func format(_ input: Expression) throws -> String {
    let value = try evaluate(input, globals)
    return value.format()
  }

  func printable(_ item: Printable) throws -> String {
    switch item {
    case .thinSpace:
      return ""

    case .tab:
      let currentColumn = interactor.column()
      let tabNumber = (currentColumn + columnsPerTab) / columnsPerTab
      let neededSpaces = tabNumber * columnsPerTab - currentColumn
      return String(repeating: " ", count: neededSpaces)
      
    case .expr(let expr):
      return try format(expr)
    }
  }

  fileprivate func doPrint(_ values : [Printable], _ shouldPrintNewline: Bool) throws {
    try values.forEach {
      let printable = try printable($0)
      interactor.append(printable)
    }

    if shouldPrintNewline {
      interactor.append("\n")
    }
  }

  func doGosub(_ subroutineLocation: Location) throws {
    returnStack.append(nextLocationFor(location))
    doGoto(subroutineLocation)
  }

  func doReturn() throws {
    guard !returnStack.isEmpty else {
      throw InterpreterError.error(location.lineNumber, "RETURN called before GOSUB")
    }

    let returnTarget = returnStack.popLast()!
    doGoto(returnTarget)
  }

  fileprivate func doGoto(_ newLocation: Location) {
    nextLocation = newLocation
  }

  fileprivate func doIf(_ expr: Expression) throws {
    let condition = try evaluate(expr, globals)

    if condition == .number(0.0) {
      doGoto(Location(program.lineAfter(location.lineNumber)))
    }
  }

  fileprivate func doIfGoto(_ expr: Expression, _ target: Location) throws {
    let condition = try evaluate(expr, globals)
    if condition != .number(0.0) {
      nextLocation = target
    }
  }

  fileprivate func doInput(_ exprs: [Expression]) throws {
    if interactor.input.isEmpty {
      awaitingInput = true
      return
    }

    let line = interactor.getLine()
    try doPrint([.expr(.string("? ")), .expr(.string(line))], true)

    let fields = line.split(separator: ",")
    if fields.count < exprs.count {
      throw InterpreterError.error(location.lineNumber, "Not enough input values; try again")
    } else if fields.count > exprs.count {
      try doPrint([.expr(.string("? Extra input ignored"))], true)
    }

    try exprs.enumerated().forEach { (index, lvalue) in
      let rvalue = try convertInputToExpression(
        String(fields[index]), lvalue.type())

      try doAssign(lvalue, rvalue)
    }
  }

  fileprivate func convertInputToExpression(_ input: String, _ type: `Type`) throws -> Expression {

    let rvalue: Expression
    switch type {
    case .string:
      rvalue = .string(input)

    case .number:
      guard let floatValue = Float(input.trimmingCharacters(in: .whitespaces)) else {
        throw InterpreterError.error(location.lineNumber, "Non-numeric input for numeric variable; try again")
      }

      rvalue = .number(floatValue)

    default:
      throw InterpreterError.cantHappen(location.lineNumber, "Only INPUT to string or numeric types")
    }

    return rvalue
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
          try doDim(
            name,
            Array<Expression>(
              repeating: .number(10),
              count: exprs.count),
            type)
        }

        guard case .array(let basicArray) = globals[name]! else {
          throw InterpreterError.error(location.lineNumber, "Tried to subscript non-array " + name)
        }

        let indexes = try exprs
          .map {
            try evaluate($0, globals)
          }

        let value = try evaluate(rvalue, globals)

        do {
          try basicArray.put(indexes, value)
        } catch ArrayError.outOfBounds {
          throw InterpreterError.error(location.lineNumber, "array access out of bounds")
        }

      default:
        throw InterpreterError.cantHappen(location.lineNumber, "?? Can only assign to variable or array access")
      }
    }

  func doDim(
    _ name: Name,
    _ dimensions: [Expression],
    _ type: `Type`) throws {

      let dimensionSizes = try dimensions
        .map { try evaluate($0, globals) }
        .map { Int($0.asFloat()) + 1 }

      let array = Value.array(BasicArray(dimensionSizes, type))

      globals[name] = array
    }

  func doEnd() throws {
    guard returnStack.isEmpty else {
      throw InterpreterError.error(location.lineNumber, "Ended program without returning from active subroutine")
    }
    done = true
  }

  func doFor(_ variable: Name, _ initial: Expression, _ final: Expression, _ step: Expression) throws {

    let initialValue = try evaluate(initial, globals)
    let limit = try evaluate(final, globals)
    let stepSize = try evaluate(step, globals)

    let typedVariable: Expression = .variable(variable, .number)
    try doAssign(
      typedVariable,
      .op2(.minus,
           .number(initialValue.asFloat()),
           .number(stepSize.asFloat())))

    let bodyLocation = nextLocationFor(location)

    forLoopStack.append((variable, limit, stepSize, bodyLocation))

    let nextLocation = try findNext(with: variable)
    doGoto(nextLocation)
  }

  func findNextInLine(_ location: Location, _ statements: [Statement], dropping: Int, with variable: Name) throws -> Location? {

    let currentStatements = statements.dropFirst(dropping)

    let index = currentStatements.firstIndex(where: {
      if case .next(let actualVariable) = $0 {
        if variable == actualVariable { return true }
      }
      return false
    })

    if index != nil {
      return Location(location.lineNumber, index!)
    }

    return nil
  }

  func findNext(with variable: Name) throws -> Location {

    let nextLocation = try findNextInLine(
      location,
      parse.statements,
      dropping: location.part + 1,
      with: variable)
    if nextLocation != nil {
      return nextLocation!
    }

    var currentLine = Location(program.lineAfter(location.lineNumber))
    while currentLine.lineNumber < program.maxLineNumber {
      let parse = parser.parse(program[currentLine.lineNumber]!)

      let nextLocation = try findNextInLine(
        currentLine,
        parse.statements,
        dropping: 0,
        with: variable)
      if nextLocation != nil {
        return nextLocation!
      }

      currentLine = Location(program.lineAfter(currentLine.lineNumber))
    }
    throw InterpreterError.error(
      currentLine.lineNumber,
      "Found FOR without NEXT: \(variable)")
  }
  
  func doNext(_ variable: Name) throws {
    guard !forLoopStack.isEmpty else {
      throw InterpreterError.error(location.lineNumber, "Found NEXT without preceding FOR")
    }

    let (pushedName, limit, stepSize, bodyLocation) = forLoopStack.last!

    guard variable == pushedName else {
      throw InterpreterError.error(location.lineNumber, "NEXT variable must match corresponding FOR")
    }
    
    let typedVariable: Expression = .variable(variable, .number)
    let nextValue = try evaluate(.op2(.plus, typedVariable, .number(stepSize.asFloat())), globals)

    if (stepSize.asFloat() >= 0 && nextValue.asFloat() <= limit.asFloat())
        || (stepSize.asFloat() < 0 && nextValue.asFloat() >= limit.asFloat()) {

      try doAssign(typedVariable, .number(nextValue.asFloat()))
      doGoto(bodyLocation)
    } else {
      forLoopStack.removeLast()
    }
  }

  func doOnGoto(_ expr: Expression, _ targets: [LineNumber]) throws {
    let floatValue = try evaluate(expr, globals).asFloat()
    let value = Int(floatValue)

    guard value >= 0 else {
      throw InterpreterError.error(location.lineNumber, "?ILLEGAL QUANTITY")
    }
    
    if value == 0 || value > targets.count {
      return
    }

    doGoto(Location(targets[value - 1]))
  }

  func doRead(_ exprs: [Expression]) throws {
    guard dataIndex + exprs.count <= data.count else {
      try doEnd()
      return
    }

    try exprs.forEach { lvalue in
      let rawValue = data[dataIndex]
      dataIndex += 1

      let rvalue: Expression
      if lvalue.type() == .number {
        guard let floatValue = Float(rawValue) else {
          throw InterpreterError.error(location.lineNumber, "? Attempted to read string as number")
        }
        rvalue = .number(floatValue)
      } else {
        rvalue = .string(rawValue)
      }

      try doAssign(lvalue, rvalue)
    }
  }
}
