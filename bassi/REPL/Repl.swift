//
//  Repl.swift
//  bassi
//
//  Created by Bill Wake on 5/13/22.
//

import Foundation

class Repl {
  var program = Program()
  
  func execute(_ command: String) {

    if command.count == 0 { return }
    
    if command.first!.isNumber {
      let lineNumber = command.prefix {
        $0.isNumber
      }
      program[String(lineNumber)] = command
    }
  }
  
  func contains(_ lineNumber: String) -> Bool {
    program[lineNumber].count != 0
  }
}
