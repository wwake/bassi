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
    self.program = program
  }

  func next() -> Token {
    while program[index] == " " {
      index += 1
    }

    switch program[index] {
    case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
      let startingIndex = program.index(program.startIndex, offsetBy: index)

      while program[index] >= "0" && program[index] <= "9" {
        index += 1
      }

      let endingIndex = program.index(program.startIndex, offsetBy: index)
      let value = program[startingIndex..<endingIndex]
      return Token.line(Int(value)!)

      case "A", "B", "C", "D", "E", "F",
      "G", "H", "I", "J", "K", "L",
      "M", "N", "O", "P", "Q", "R", "S",
      "T", "U", "V", "W", "X", "Y", "Z":

      let startingIndex = program.index(program.startIndex, offsetBy: index)

      while program[index] >= "A" && program[index] <= "Z" {
        index += 1
      }

      let endingIndex = program.index(program.startIndex, offsetBy: index)
      let value = program[startingIndex..<endingIndex]

      if (value .starts(with: "REM")) {

        return Token.remark
      }

      return Token.error("unrecognized name")


    default:
      return Token.error("not yet implemented")
    }
  }
}
