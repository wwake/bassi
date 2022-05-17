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
    output.append(command)
    output.append("\n")

    if command.count == 0 { return }
    
    if command.first!.isNumber {
      doLineNumber(command)
    } else if command.uppercased() == "LIST" {
      doList()
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
        output.append($0)
        output.append("\n")
      }
  }

  func contains(_ lineNumber: Int) -> Bool {
    program[lineNumber].count != 0
  }
}
