//
//  Repl.swift
//  bassi
//
//  Created by Bill Wake on 5/13/22.
//

import Foundation

class Repl : ObservableObject {
  var output: Output
  var program: Program
  var interpreter: Interpreter

  @Published var stopped: Bool
  @Published var store: [Name: Value] = [:]
  
  init(_ program : Program, _ output: Output) {
    self.program = program
    self.output = output
    interpreter = Interpreter(program, output)
    stopped = interpreter.stopped
  }

  func execute(_ commands: String) {
    commands
      .split(separator: "\n")
      .forEach {
        let command = String($0)

        if command.count == 0 { return }

        if command.first!.isNumber {
          doLineNumber(command)
        }
      }
  }

  func doLineNumber(_ command: String) {
    let lineNumber = command.prefix {
      $0.isNumber
    }
    program[Int(lineNumber)!] = command
  }

  func doRun() {
    do {
      try interpreter.run()
      stopped = interpreter.stopped
      store = interpreter.globals
    } catch InterpreterError.error(let lineNumber, let message) {
      append("\(lineNumber): ?\(message)")
    } catch {
      append("\(error)")
    }
  }

  func doContinue() {
    do {
      try interpreter.doContinue()
      stopped = interpreter.stopped
    } catch InterpreterError.error(let lineNumber, let message) {
      append("\(lineNumber): ?\(message)")
    } catch {
      append("\(error)")
    }
  }

  func append(_ line: String) {
    output.append(line)
  }
}
