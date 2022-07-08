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

    ("ABS", .predefined(`Type`.typeNtoN)),
    ("ASC", .predefined(`Type`.typeStoN)),
    ("ATN", .predefined(`Type`.typeNtoN)),
    ("CHR$", .predefined(`Type`.typeNtoS)),
    ("COS", .predefined(`Type`.typeNtoN)),
    ("EXP", .predefined(`Type`.typeNtoN)),
    ("FRE", .predefined(`Type`.typeNtoN)),
    ("INT", .predefined(`Type`.typeNtoN)),
    ("LEFT$", .predefined(`Type`.typeSNtoS)),
    ("LEN", .predefined(`Type`.typeStoN)),
    ("LOG", .predefined(`Type`.typeNtoN)),
    ("MID$", .predefined(`Type`.typeSNoptNtoS)),
    ("POS", .predefined(`Type`.typeNtoN)),
    ("RIGHT$", .predefined(`Type`.typeSNtoS)),
    ("RND", .predefined(`Type`.typeNtoN)),
    ("SGN", .predefined(`Type`.typeNtoN)),
    ("SIN", .predefined(`Type`.typeNtoN)),
    ("SPC", .predefined(`Type`.typeNtoS)),
    ("SQR", .predefined(`Type`.typeNtoN)),
    ("STR$", .predefined(`Type`.typeNtoS)),
    ("TAB", .predefined(`Type`.typeNtoS)),
    ("TAN", .predefined(`Type`.typeNtoN)),
    ("USR", .predefined(`Type`.typeNtoN)),
    ("VAL", .predefined(`Type`.typeStoN)),
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
    let (tokenType, string, returnType) = nextTokenType()

    return Token(
      type: tokenType,
      line: lineNumber == nil ? 0 : lineNumber!,
      column: column,
      string: string,
      returnType: returnType)
  }

  func nextTokenType() -> (TokenType, String?, `Type`?) {
    if index >= program.count {
      return (.atEnd, nil, nil)
    }

    if findUnquotedString {
      var result: String = ""
      while !Set([",", ":", "\n"]).contains(program[index]) {
        result.append(program[index])
        index += 1
      }
      if result.count > 0 {
        return (.string, result, nil)
      }
    }

    let (possibleToken, possibleString, possibleType) = findPrefixToken()
    if possibleToken != nil {
      return (possibleToken!, possibleString, possibleType)
    }

    switch program[index] {
    case "0"..."9":
        let (token, string) = number()
        return (token, string, nil)

    case "\"":
      let (token, string) = string()
      return (token, string, nil)

    case "A"..."Z":
      let (token, string) = handleVariable()
      return (token, string, nil)

    default:
      return (TokenType.error, "unexpected character", nil)
    }
  }

  fileprivate func number() -> (TokenType, String?) {
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
        return (.error, "Exponent value is missing")
      }
      let exponent = repeatAny("0", "9")

      value += "E"
      value += exponent
    }

    if isFloat {
      return (TokenType.number(Float(value)!), nil)
    } else {
      let intValue = Int(value)!
      if lineNumber == nil {
        lineNumber = intValue
      }
      return (TokenType.integer(intValue), nil)
    }
  }

  func string() -> (TokenType, String?) {
    var body = ""
    index += 1

    while program[index] != "\"" && program[index] != "\n" {
      body += String(program[index])
      index += 1
    }

    if program[index] == "\n" {
      return (.error, "unterminated string")
    }

    index += 1

    return (.string, body)
  }

  fileprivate func isDigit() -> Bool {
    return program[index] >= "0" && program[index] <= "9"
  }

  fileprivate func findPrefixToken() -> (TokenType?, String?, `Type`?) {
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

      return (keyword, string, type)
    }

    return (nil, nil, nil)
  }

  fileprivate func handleVariable() -> (TokenType, String) {
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

    return (TokenType.variable, name)
  }
}
