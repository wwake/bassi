//
//  Lexer.swift
//  bassi
//
//  Created by Bill Wake on 5/9/22.
//

import Foundation

extension StringProtocol {
  subscript(offset: Int) -> Character {
    self[index(startIndex, offsetBy: offset)]
  }
}

class Lexer {
  let program: String
  var index = 0

  init(_ program: String) {
    self.program = program.replacingOccurrences(of:" ", with:"")
  }

  func matchWhile(_ low: Character, _ high: Character) -> String {
    let startingIndex = program.index(program.startIndex, offsetBy: index)

    while program[index] >= low && program[index] <= high {
      index += 1
    }

    let endingIndex = program.index(program.startIndex, offsetBy: index)
    let value = program[startingIndex..<endingIndex]
    return String(value)
  }

  func next() -> Token {
    if index >= program.count {
      return .atEnd
    }

    switch program[index] {
    case "0", "1", "2", "3", "4",
      "5", "6", "7", "8", "9":
      let value = matchWhile("0", "9")
      return Token.line(Int(value)!)

    case "A", "B", "C", "D", "E", "F",
      "G", "H", "I", "J", "K", "L",
      "M", "N", "O", "P", "Q", "R", "S",
      "T", "U", "V", "W", "X", "Y", "Z":

      let value = matchWhile("A", "Z")
      
      if (value .starts(with: "REM")) {
        return Token.remark
      }

      return Token.error("unrecognized name")


    default:
      return Token.error("not yet implemented")
    }
  }
}
