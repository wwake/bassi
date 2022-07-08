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
  typealias Element = Token

  let prefixTokens: [(String, TokenType)] = [
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
    (":", .colon),
    (";", .semicolon),

    ("AND", .and),
    ("CLEAR", .clear),
    ("DATA", .data),
    ("DEF", .def),
    ("DIM", .dim),

    ("END", .end),
    ("FN", .fn),
    ("FOR", .`for`),
    ("GOTO", .goto),
    ("GOSUB", .gosub),

    ("IF", .`if`),
    ("INPUT", .input),
    ("LET", .`let`),
    ("NEXT", .next),
    ("NOT", .not),
    ("ON", .on),
    ("OR", .or),

    ("POKE", .poke),
    ("PRINT", .print),
    ("READ", .read),
    ("REM", .remark),
    ("RESTORE", .restore),
    ("RETURN", .`return`),

    ("STEP", .step),
    ("STOP", .stop),
    ("THEN", .then),
    ("TO", .to),

    ("ABS", .predefined),
    ("ASC", .predefined),
    ("ATN", .predefined),
    ("CHR$", .predefined),
    ("COS", .predefined),
    ("EXP", .predefined),
    ("FRE", .predefined),
    ("INT", .predefined),
    ("LEFT$", .predefined),
    ("LEN", .predefined),
    ("LOG", .predefined),
    ("MID$", .predefined),
    ("POS", .predefined),
    ("RIGHT$", .predefined),
    ("RND", .predefined),
    ("SGN", .predefined),
    ("SIN", .predefined),
    ("SPC", .predefined),
    ("SQR", .predefined),
    ("STR$", .predefined),
    ("TAB", .predefined),
    ("TAN", .predefined),
    ("USR", .predefined),
    ("VAL", .predefined),
  ]

  let predefinedFunctionTypes: [String: `Type`] =
  [
    "ABS" : `Type`.typeNtoN,
    "ASC" : `Type`.typeStoN,
    "ATN" : `Type`.typeNtoN,
    "CHR$" : `Type`.typeNtoS,
    "COS" : `Type`.typeNtoN,
    "EXP" : `Type`.typeNtoN,
    "FRE" : `Type`.typeNtoN,
    "INT" : `Type`.typeNtoN,
    "LEFT$" : `Type`.typeSNtoS,
    "LEN" : `Type`.typeStoN,
    "LOG" : `Type`.typeNtoN,
    "MID$" : `Type`.typeSNoptNtoS,
    "POS" : `Type`.typeNtoN,
    "RIGHT$" : `Type`.typeSNtoS,
    "RND" : `Type`.typeNtoN,
    "SGN" : `Type`.typeNtoN,
    "SIN" : `Type`.typeNtoN,
    "SPC" : `Type`.typeNtoS,
    "SQR" : `Type`.typeNtoN,
    "STR$" : `Type`.typeNtoS,
    "TAB" : `Type`.typeNtoS,
    "TAN" : `Type`.typeNtoN,
    "USR" : `Type`.typeNtoN,
    "VAL" : `Type`.typeStoN,
  ]

  let program: String
  var index = 0

  var lineNumber : Int?
  var column : Int

  var findUnquotedString = false

  init(_ program: String) {
    self.program = Lexer.normalize(program)
    lineNumber = nil
    column = 0
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
        n % 2 == 0
        ?
          String(piece)
            .replacingOccurrences(of:" ", with:"")
            .uppercased()
        :
          String("\"" + piece + "\"")
      }

    return normalizedPieces.joined()
  }

  func index(at: Int) -> String.Index {
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

  func next() -> Token {
    column = index

    if index >= program.count {
      return makeToken(.atEnd)
    }

    if findUnquotedString {
      var result: String = ""
      while !Set([",", ":", "\n"]).contains(program[index]) {
        result.append(program[index])
        index += 1
      }
      if result.count > 0 {
        return makeToken(.string, string: result)
      }
    }

    let possibleToken = findPrefixToken()
    if possibleToken != nil {
      return possibleToken!
    }

    switch program[index] {
    case "0"..."9":
        return number()

    case "\"":
      return string()

    case "A"..."Z":
      return handleVariable()

    default:
      return makeToken(.error, string: "unexpected character")
    }
  }

  fileprivate func makeToken(_ type: TokenType, string: String? = nil, float: Float? = nil, resultType: `Type`? = nil) -> Token {
    return Token(
      line: lineNumber == nil ? 0 : lineNumber!,
      column: column,
      type: type,
      string: string,
      float: float,
      resultType: resultType)
  }

  fileprivate func number() -> Token {
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

      if program[index] < "0" || program[index] > "9" {
        return makeToken(.error, string: "Exponent value is missing")
      }
      let exponent = repeatAny("0", "9")

      value += "E"
      value += exponent
    }

    if isFloat {
      return makeToken(.number, float: Float(value)!)
    } else {
      let intValue = Float(value)!
      if lineNumber == nil {
        lineNumber = LineNumber(intValue)
      }
      return makeToken(.integer, float: intValue)
    }
  }

  func string() -> Token {
    var body = ""
    index += 1

    while program[index] != "\"" && program[index] != "\n" {
      body += String(program[index])
      index += 1
    }

    if program[index] == "\n" {
      return makeToken(.error, string: "unterminated string")
    }

    index += 1

    return makeToken(.string, string: body)
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

    var string: String? = nil
    var type: `Type`? = nil

    if answer != nil {
      skipWord(answer!.0)
      let keyword = answer!.1

      if keyword == .remark {
        ignoreUntil("\n")
      } else if case .predefined = keyword {
        string = answer!.0
        type = predefinedFunctionTypes[string!]!
      } else if keyword == .data {
        findUnquotedString = true
      } else if keyword == .colon || keyword == .eol {
        findUnquotedString = false
      }

      return makeToken(keyword, string: string, resultType: type)
    }

    return nil
  }

  fileprivate func handleVariable() -> Token {
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

    return makeToken(.variable, string: name)
  }
}
