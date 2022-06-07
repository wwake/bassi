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

  let prefixTokens: [(String, Token)] = [
    ("+", .plus),
    ("-", .minus),
    ("*", .times),
    ("/", .divide),
    ("^", .exponent),
    ("=", .equals),
    ("(", .leftParend),
    (")", .rightParend),
    (",", .comma),
    ("\n", .eol),
    ("<=", .lessThanOrEqualTo),
    ("<>", .notEqual),
    ("<", .lessThan),
    (">=", .greaterThanOrEqualTo),
    (">", .greaterThan),

    ("AND", .and),
    ("CLEAR", .clear),
    ("DATA", .data),
    ("DEF", .def),
    ("DIM", .dim),

    ("END", .end),
    ("FN", .fn),
    ("FOR", .forKeyword),
    ("GOTO", .goto),
    ("GOSUB", .gosub),

    ("IF", .ifKeyword),
    ("INPUT", .input),
    ("LET", .letKeyword),
    ("NEXT", .next),
    ("NOT", .not),
    ("ON", .on),
    ("OR", .or),

    ("POKE", .poke),
    ("PRINT", .print),
    ("READ", .read),
    ("REM", .remark),
    ("RESTORE", .restore),
    ("RETURN", .returnKeyword),

    ("STOP", .stop),
    ("THEN", .then),

    ("ABS", .predefined("ABS", `Type`.typeNtoN)),
    ("ASC", .predefined("ASC", `Type`.typeStoN)),
    ("ATN", .predefined("ATN", `Type`.typeNtoN)),
    ("CHR$", .predefined("CHR$", `Type`.typeNtoS)),
    ("COS", .predefined("COS", `Type`.typeNtoN)),
    ("EXP", .predefined("EXP", `Type`.typeNtoN)),
    ("FRE", .predefined("FRE", `Type`.typeNtoN)),
    ("INT", .predefined("INT", `Type`.typeNtoN)),
    ("LEFT$", .predefined("LEFT$", `Type`.typeSNtoS)),
    ("LEN", .predefined("LEN", `Type`.typeStoN)),
    ("LOG", .predefined("LOG", `Type`.typeNtoN)),
    ("MID$", .predefined("MID$", `Type`.typeSNoptNtoS)),
    ("POS", .predefined("POS", `Type`.typeNtoN)),
    ("RIGHT$", .predefined("RIGHT$", `Type`.typeSNtoS)),
    ("RND", .predefined("RND", `Type`.typeNtoN)),
    ("SGN", .predefined("SGN", `Type`.typeNtoN)),
    ("SIN", .predefined("SIN", `Type`.typeNtoN)),
    ("SPC", .predefined("SPC", `Type`.typeNtoS)),
    ("SQR", .predefined("SQR", `Type`.typeNtoN)),
    ("STR$", .predefined("STR$", `Type`.typeNtoS)),
    ("TAB", .predefined("TAB", `Type`.typeNtoS)),
    ("TAN", .predefined("TAN", `Type`.typeNtoN)),
    ("USR", .predefined("USR", `Type`.typeNtoN)),
    ("VAL", .predefined("VAL", `Type`.typeStoN)),
  ]

  let program: String
  var index = 0

  init(_ program: String) {
    self.program = Lexer.normalize(program)
  }

  fileprivate static func normalize(_ program: String) -> String {
    let program2 = program + "\n"
    let pieces = program2
      .split(
        separator:"\"",
        omittingEmptySubsequences: false)

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

    let possibleToken = findPrefixToken()
    if possibleToken != nil {
      return possibleToken
    }

    switch program[index] {
    case "0"..."9":
        return number()

    case "\"":
      return string()

    case "A"..."Z":
      return handleVariable()

    default:
      return Token.error("not yet implemented")
    }
  }

  fileprivate func number() -> Token? {
    var isFloat = false

    var value = repeatAny("0", "9")

    if program[index] == "." {
      index += 1
      isFloat = true
      let fraction = repeatAny("0", "9")
      value += "."
      value += fraction
    }

    if program[index] == "E" && !(("A"..."Z").contains(program[index+1])) {
      index += 1
      isFloat = true

      let message = "Exponent value is missing"
      if program[index] < "0" || program[index] > "9" {
        return .error(message)
      }
      let exponent = repeatAny("0", "9")

      value += "E"
      value += exponent
    }

    return isFloat ?  Token.number(Float(value)!)
    : Token.integer(Int(value)!)
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

  fileprivate func isDigit() -> Bool {
    return program[index] >= "0" && program[index] <= "9"
  }

  fileprivate func findPrefixToken() -> Token? {
    let start = program.index(program.startIndex, offsetBy: index)
    let input = program[start...]

    let answer = prefixTokens.first { (word, token) in
      input.starts(with: word)
    }

    if answer != nil {
      skipWord(answer!.0)
      let keyword = answer!.1

      if keyword == .remark {
        ignoreUntil("\n")
      }

      return keyword
    }

    return nil
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
