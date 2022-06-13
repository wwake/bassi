//
//  Program.swift
//  bassi
//
//  Created by Bill Wake on 5/13/22.
//

import Foundation

class Program {
  let maxLineNumber = 99999

  var program : [Int: String] =
    [99999 : "99999 END"]

  init(_ lines: String) {
    lines
      .split(separator: "\n")
      .forEach {
        let line = String($0)
        if line.count != 0 {
          let lineNumber = line.prefix {
            $0.isNumber
          }
          program[Int(lineNumber)!] = line
        }
      }
  }

  init() {}

  subscript(_ lineNumber: Int) -> String? {
    get { program[lineNumber] }
    set {
      if Int(newValue!) == nil {
        program[lineNumber] = newValue
        return
      }
      program.removeValue(forKey: Int(newValue!)!)
    }
  }

  func list() -> [String] {
    program
      .sorted(by: {$0.key < $1.key})
      .map {(key, value) in value}
      .dropLast()
  }

  func firstLineNumber() -> Int {
    let lineNumber = program
      .min(by: {$0.key < $1.key})

    return lineNumber?.key ?? 0
  }

  func lineAfter(_ lineNumber: Int) -> Int {
    let keys = program.keys.sorted(by: <)

    let startIndex = keys
      .firstIndex { $0 == lineNumber }

    if startIndex == nil {
      return maxLineNumber
    }

    if startIndex! + 1 >= keys.count {
      return maxLineNumber
    }

    return keys[startIndex! + 1]
  }
}
