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

  let reservedWords: [String : Token] = [
    "AND": .and,
    "CLEAR": .clear,
    "DATA": .data,
    "DEF": .def,
    
    "END": .end,
    "FN": .fn,
    "FOR": .forKeyword,
    "GOTO": .goto,
    "GOSUB": .gosub,

    "IF": .ifKeyword,
    "INPUT": .input,
    "LET": .letKeyword,
    "NEXT": .next,
    "NOT": .not,

    "ON": .on,
    "OR": .or,
    "POKE": .poke,
    "PRINT": .print,
    "READ": .read,
    "REM": .remark,

    "RESTORE": .restore,
    "RETURN": .returnKeyword,
    "STOP": .stop,
    "THEN": .then,

    "ABS": .predefined("ABS"),
    "ASC": .predefined("ASC"),
    "ATN": .predefined("ATN"),
    "CHR$": .predefined("CHR$"),
    "COS": .predefined("COS"),

    "EXP": .predefined("EXP"),
    "FRE": .predefined("FRE"),
    "INT": .predefined("INT"),
    "LEFT$": .predefined("LEFT$"),
    "LEN": .predefined("LEN"),
    "LOG": .predefined("LOG"),

    "MID$": .predefined("MID$"),
    "POS": .predefined("POS"),
    "RIGHT$": .predefined("RIGHT$"),
    "RND": .predefined("RND"),

    "SGN": .predefined("SGN"),
    "SIN": .predefined("SIN"),
    "SPC": .predefined("SPC"),
    "SQR": .predefined("SQR"),
    "STR$": .predefined("STR$"),

    "TAB": .predefined("TAB"),
    "TAN": .predefined("TAN"),
    "USR": .predefined("URS"),
    "VAL": .predefined("VAL"),
  ]

  let program: String
  var index = 0

  var lookingForLineNumber = true

  init(_ program: String) {
    self.program = Lexer.normalize(program)
  }

  fileprivate static func normalize(_ program: String) -> String {
    let program2 = program + "\n"
    let pieces = program2
      .split(separator:"\"")

    let normalizedPieces =
      pieces
      .enumerated()
      .map { n, piece in
        n % 2 == 0 ?
          String(piece).replacingOccurrences(of:" ", with:"")
          .uppercased()
        : String("\"" + piece + "\"")
      }

    return normalizedPieces.joined()
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

  func repeatAny(_ low: Character, _ high: Character) -> String {
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
      return .eol

    case "0"..."9":
      if lookingForLineNumber {
        lookingForLineNumber = false
        return integer()
      } else {
        return number()
      }

    case "\"":
      return string()

    case "+", "-", "*", "/", "^", "=", "(", ")":
      return oneCharacterOperator()

    case "<":
      return lessThanOperators()

    case ">":
      return greaterThanOperators()

    case "A"..."Z":
      return keywordsAndNames()

    default:
      return Token.error("not yet implemented")
    }
  }

  fileprivate func integer() -> Token? {
    let value = repeatAny("0", "9")
    return Token.integer(Int(value)!)
  }

  fileprivate func number() -> Token? {
    var value = repeatAny("0", "9")

    if program[index] == "." {
      index += 1
      let fraction = repeatAny("0", "9")
      value += "."
      value += fraction
    }

    if program[index] == "E" || program[index] == "e" {
      index += 1

      let message = "Exponent value is missing"
      if program[index] < "0" || program[index] > "9" {
        return .error(message)
      }
      let exponent = repeatAny("0", "9")

      value += "E"
      value += exponent
    }

    return Token.number(Float(value)!)
  }

  func string() -> Token? {
    var body = ""
    index += 1

    while program[index] != "\"" && program[index] != "\n" {
      body += String(program[index])
      index += 1
    }

    if program[index] == "\n" {
      return .error("unterminated string")
    }

    index += 1

    return .string(body)
  }

  fileprivate func oneCharacterOperator() -> Token? {
    let result = oneCharOperators[program[index]]
    index += 1
    return result
  }

  fileprivate func lessThanOperators() -> Token? {
    index += 1
    if program[index] == "=" {
      index += 1
      return .lessThanOrEqualTo
    } else if program[index] == ">" {
      index += 1
      return .notEqual
    }
    return .lessThan
  }

  fileprivate func greaterThanOperators() -> Token? {
    index += 1
    if program[index] == "=" {
      index += 1
      return .greaterThanOrEqualTo
    }
    return .greaterThan
  }

  fileprivate func isDigit() -> Bool {
    return program[index] >= "0" && program[index] <= "9"
  }

  fileprivate func keywordsAndNames() -> Token? {
    let startingIndex = index
    let value = repeatAny("A", "Z")

    index = startingIndex

    let answer = reservedWords.first { (word, token) in
      value.starts(with: word)
    }

    if answer == nil {
      return handleVariable()
    }

    skipWord(answer!.0)
    let keyword = answer!.1

    if keyword == .remark {
      ignoreUntil("\n")
    } else if keyword == .then {
      if isDigit() {
        lookingForLineNumber = true
      }
    }
    return keyword
  }

  fileprivate func handleVariable() -> Token? {
    var name: String = String(program[index])
    index += 1

    if isDigit() {
      name += String(program[index])
      index += 1
    }

    if program[index] == "$" {
      name += "$"
      index += 1
    }

    return Token.variable(name)
  }
}
