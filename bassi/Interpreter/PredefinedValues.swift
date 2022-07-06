//
//  PredefinedValues.swift
//  bassi
//
//  Created by Bill Wake on 7/6/22.
//

import Foundation


fileprivate func midDollar(_ string: String, _ start: Int, _ length: Int) -> String {
  let count = string.count

  let rightCount = max(0, count - start + 1)
  let rightString = String(string.suffix(rightCount))
  return String(rightString.prefix(length))
}

func midFunction(_ arguments: [Value]) -> Value {
  let string = arguments[0].asString()
  let start = Int(arguments[1].asFloat())

  var length = string.count
  if arguments[2] != .undefined {
    length = Int(arguments[2].asFloat())
  }

  return Value.string(midDollar(
    string,
    start,
    length
  ))
}

class Predefined {
  static var lastSeed : Float = 0

  static func random(_ seed: Float) -> Float {
    if seed != lastSeed {
      lastSeed = seed
      srand48(Int(lastSeed))
    }

    return Float(drand48())
  }

  func buildTab(_ outputter: Interactor) -> (Float) -> String {
    return {
      let currentColumn = outputter.column()
      let desiredColumn = Int($0)
      if desiredColumn >= currentColumn {
        return String(repeating: " ", count: desiredColumn - currentColumn)
      }
      return "\n" + String(repeating: " ", count: desiredColumn)
    }
  }

  static func functionsUsing(_ interactor: Interactor) -> [Name : Value] {

    var result = predefinedFunctions
    result["TAB"] = Value.function(Fn2s(buildTab(interactor)))
    return result
  }

  static func buildTab(_ outputter: Interactor) -> (Float) -> String {
    return {
      let currentColumn = outputter.column()
      let desiredColumn = Int($0)
      if desiredColumn >= currentColumn {
        return String(repeating: " ", count: desiredColumn - currentColumn)
      }
      return "\n" + String(repeating: " ", count: desiredColumn)
    }
  }

  static let predefinedFunctions = [
    "ABS" : Value.function(Fn2n(abs)),
    "ASC" : Value.function(Fs2n( {
      if $0.count == 0 { return 0}
      return Float($0.utf8.first!)
    })),
    "ATN" : Value.function(Fn2n(atan)),
    "CHR$" : Value.function(Fn2s( { return
      String(
        Character(
          UnicodeScalar(
            Int($0))!))
    })),
    "COS" : Value.function(Fn2n(cos)),
    "EXP":
      Value.function(Fn2n(exp)),
    "FRE":
      Value.function(Fn2n({_ in Interpreter.freeSpaceCount})),
    "INT" : Value.function(Fn2n({Float(Int($0))})),
    "LEFT$": Value.function(Fsn2s({
      String($0.prefix(Int($1)))
    })),
    "LEN" : Value.function(Fs2n({Float($0.count)})),
    "LOG":
      Value.function(Fn2n(log)),
    "MID$": Value.function(midFunction),
    "RIGHT$": Value.function(Fsn2s({
      String($0.suffix(Int($1)))
    })),
    "RND" :
      Value.function(Fn2n(random)),
    "SGN":
      Value.function(Fn2n({
        if $0 == 0 {
          return 0.0
        } else if $0 < 0 {
          return -1.0
        }
        return 1.0
      })),
    "SIN" : Value.function(Fn2n(sin)),
    "SQR" : Value.function(Fn2n(sqrt)),
    "STR$": Value.function(Fn2s({
      Value.number($0).format()
    })),
    "TAN" : Value.function(Fn2n(tan)),
    "VAL" : Value.function(Fs2n({Float($0) ?? 0})),
  ]
}
