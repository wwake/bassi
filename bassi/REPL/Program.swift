//
//  Program.swift
//  bassi
//
//  Created by Bill Wake on 5/13/22.
//

import Foundation

class Program {
  var program : [String: String] = [:]

  subscript(_ lineNumber: String) -> String {
    get { program[lineNumber] ?? "" }
    set {
      if Int(newValue) == nil {
        program[lineNumber] = newValue
        return
      }
      program.removeValue(forKey: newValue)
    }
  }
}
