//
//  Value.swift
//  bassi
//
//  Created by Bill Wake on 5/27/22.
//

import Foundation

public enum Value : Equatable {
  case undefined
  case number(Float)
  case string(String)

  case array(BasicArray)

  case function(([Value]) -> Value)
  case userFunction(String, Expression, `Type`)

  func asFloat() -> Float {
    guard case .number(let value) = self else {
      print("asFloat() called on non-number")
      return -1
    }
    return value
  }

  public static func == (lhs: Value, rhs: Value) -> Bool {
    switch (lhs, rhs) {
    case (.number(let float1), .number(let float2)):
      return float1 == float2

    case (.string(let string1), .string(let string2)):
      return string1 == string2

    case (.undefined, .undefined):
      return true

    case (.array(let array1),
          .array(let array2)):
      return array1 == array2

    case (.function, .function),
      (.userFunction, .userFunction):
      return false

    default:
      return false
    }
  }


  func asString() -> String {
    guard case .string(let value) = self else {
      print("asString() called on non-string")
      return "???"
    }
    return value
  }

  func asArray() -> BasicArray {
    guard case .array(let array) = self else {
      print("asArray() called on non-array")
      return BasicArray([], .number)
    }
    return array
  }

  func isFunction() -> Bool {
    if case .function = self {
      return true
    } else {
      return false
    }
  }

  func isArray() -> Bool {
    if case .array = self {
      return true
    } else {
      return false
    }
  }

  func apply(_ args: [Value]) -> Value {
    guard case .function(let fn) = self else {
      // can't happen
      return Value.undefined
    }

    return fn(args)
  }

  fileprivate func basicFormat(_ number: (Float)) -> String {
    var result = ""
    if number == Float(Int(number)) {
      result = String(format: "%.0f", number)
    } else {
      result = String(format: "%f", number)
    }

    if number < 0 { return result + " " }
    return " " + result + " "
  }

  func format() -> String {
    switch self {
    case .number(let number):
      return basicFormat(number)

    case .string(let string):
      return string

    case .undefined:
      return "<UNDEFINED>"

    case .function:
      return "<FUNCTION>"

    case .userFunction(_, _, _):
      return "<USER-FUNCTION>"

    case .array(let array):
      let temp = array.dimensions.map {String($0-1)}.joined(separator: ",")
      return "Array(\(temp)): \(array.type)"
    }
  }
}

public func Fn2n(
  _ fn: @escaping (Float) -> Float)
-> (([Value]) -> Value)
{
  return { args in
    Value.number(
      fn(args[0].asFloat())
    )
  }
}

public func Fn2s(
  _ fn: @escaping (Float) -> String)
-> (([Value]) -> Value)
{
  return { args in
    Value.string(
      fn(args[0].asFloat())
    )
  }
}

public func Fs2n(
  _ fn: @escaping (String) -> Float)
-> (([Value]) -> Value)
{
  return { args in
    Value.number(
      fn(args[0].asString())
    )
  }
}

public func Fsn2s(
  _ fn: @escaping (String, Float) -> String)
-> (([Value]) -> Value)
{
  return { args in
    Value.string(
      fn(args[0].asString(),
         args[1].asFloat())
    )
  }
}

public func Fsnn2s(
  _ fn: @escaping (String, Float, Float) -> String)
-> (([Value]) -> Value)
{
  return { args in
    Value.string(
      fn(args[0].asString(),
         args[1].asFloat(),
         args[2].asFloat())
    )
  }
}

