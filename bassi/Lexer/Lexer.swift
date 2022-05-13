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

class Lexer : Sequence, IteratorProtocol {

  typealias Element = Token

  let oneCharOperators: [Character : Token] = [
    "+": .plus,
    "-": .minus,
    "*": .times,
    "/": .divide,
    "^": .exponent,
    "=": .equals,
    "(": .leftParend,
    ")": .rightParend
  ]

  let program: String
  var index = 0

  init(_ program: String) {
    self.program = program.replacingOccurrences(of:" ", with:"")
    + "\n"
  }

  func index(at: Int) ->String.Index {
    program.index(
      program.startIndex,
      offsetBy: at)
  }

  func substring(_ start: Int, _ ending: Int) -> String {
    let value = program[
      index(at: start)..<index(at: ending)]
    return String(value)
  }

  func matchWhile(_ low: Character, _ high: Character) -> String {
    let startIndex = index

    while program[index] >= low && program[index] <= high {
      index += 1
    }

    return substring(startIndex, index)
  }

  func skipWord(_ word: String) {
    index += word.count
  }

  fileprivate func ignoreUntil(_ expected: Character) {
    while program[index] != expected {
      index += 1
    }
  }

  func next() -> Token? {
    if index >= program.count {
      return .atEnd
    }

    switch program[index] {
    case "\n":
      index += 1
      return next()

    case "0", "1", "2", "3", "4",
      "5", "6", "7", "8", "9":
      var isFloat = false
      var value = matchWhile("0", "9")

      if program[index] == "." {
        isFloat = true
        index += 1
        let fraction = matchWhile("0", "9")
        value += "."
        value += fraction
      }

      if program[index] == "E" || program[index] == "e" {
        isFloat = true
        index += 1

        let message = "Exponent value is missing"
        if program[index] < "0" || program[index] > "9" {
          return .error(message)
        }
        let exponent = matchWhile("0", "9")

        value += "E"
        value += exponent
      }

      if isFloat {
        return Token.number(Float(value)!)
      } else {
        return Token.integer(Float(value)!)
      }

    case "+", "-", "*", "/", "^", "=", "(", ")":
      let result = oneCharOperators[program[index]]
      index += 1
      return result

    case "A", "B", "C", "D", "E", "F",
      "G", "H", "I", "J", "K", "L",
      "M", "N", "O", "P", "Q", "R", "S",
      "T", "U", "V", "W", "X", "Y", "Z":

      let startingIndex = index
      let value = matchWhile("A", "Z")

      index = startingIndex
      if (value .starts(with: "REM")) {
        ignoreUntil("\n")

        return Token.remark
      }

      if value.starts(with: "PRINT") {
        skipWord("PRINT")
        return Token.print
      }

      return Token.error("unrecognized name")


    default:
      return Token.error("not yet implemented")
    }
  }
}
