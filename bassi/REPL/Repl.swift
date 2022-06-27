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

  init(_ program : Program, _ output: Output) {
    self.program = program
    self.output = output
    interpreter = Interpreter(program, output)
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
    } catch InterpreterError.error(let lineNumber, let message) {
      append("\(lineNumber): ?\(message)")
    } catch {
      append("\(error)")
    }
  }

  func doContinue() {

  }

  func append(_ line: String) {
    output.append(line)
  }
}
