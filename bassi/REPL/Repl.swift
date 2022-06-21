//
//  Repl.swift
//  bassi
//
//  Created by Bill Wake on 5/13/22.
//

import Foundation

class Output: ObservableObject {
  @Published var output: String = ""

  func append(_ line: String) {
    output.append(line)
  }
}

class Repl : ObservableObject {
  var output: Output!

  var program = Program()
  
  func execute(_ commands: String, _ output: Output) {
    self.output = output

    commands
      .split(separator: "\n")
      .forEach {
        let command = String($0)
        append(command)
        append("\n")

        if command.count == 0 { return }

        if command.first!.isNumber {
          doLineNumber(command)
        } else if command.uppercased() == "LIST" {
          doList()
        }  else if command.uppercased() == "RUN" {
          doRun(output)
        }
      }
  }

  func doLineNumber(_ command: String) {
    let lineNumber = command.prefix {
      $0.isNumber
    }
    program[Int(lineNumber)!] = command
  }

  func doList() {
    program
      .list()
      .forEach {
        append($0)
        append("\n")
      }
  }

  func doRun(_ output: Output) {
    do {
      let interpreter = Interpreter(program, output)
      try interpreter.run()
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
