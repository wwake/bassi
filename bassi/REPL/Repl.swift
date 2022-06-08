//
//  Repl.swift
//  bassi
//
//  Created by Bill Wake on 5/13/22.
//

import Foundation

class Repl : ObservableObject {
  var output: String = "HELLO\n"
  var program = Program()
  
  func execute(_ command: String) {
    append(command)
    append("\n")

    if command.count == 0 { return }
    
    if command.first!.isNumber {
      doLineNumber(command)
    } else if command.uppercased() == "LIST" {
      doList()
    }  else if command.uppercased() == "RUN" {
      doRun()
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

  func doRun() {
    do {
      let interpreter = Interpreter(program)
      let result = try interpreter.run()
      append(result)
    } catch InterpreterError.error(let lineNumber, let message) {
      append("\(lineNumber): ?\(message)")
    } catch {
      append("\(error)")
    }
  }

  func append(_ line: String) {
    output.append(line)
  }

  func contains(_ lineNumber: Int) -> Bool {
    program[lineNumber].count != 0
  }
}
