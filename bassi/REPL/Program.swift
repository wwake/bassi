//
//  Program.swift
//  bassi
//
//  Created by Bill Wake on 5/13/22.
//

import Foundation

class Program {
  var program : [Int: String] = [:]

  subscript(_ lineNumber: Int) -> String {
    get { program[lineNumber] ?? "" }
    set {
      if Int(newValue) == nil {
        program[lineNumber] = newValue
        return
      }
      program.removeValue(forKey: Int(newValue)!)
    }
  }

  func list() -> [String] {
    return program.values.map {
      $0
    }
  }
}
