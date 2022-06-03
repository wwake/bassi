//
//  Value.swift
//  bassi
//
//  Created by Bill Wake on 5/27/22.
//

import Foundation

public enum Value : Equatable {
  public static func == (lhs: Value, rhs: Value) -> Bool {
    switch (lhs, rhs) {
    case (.number(let float1), .number(let float2)):
      return float1 == float2

    case (.string(let string1), .string(let string2)):
      return string1 == string2

    case (.undefined, .undefined):
      return true

    case (.arrayOfNumber(let dimensions1, let contents1),
          .arrayOfNumber(let dimensions2, let contents2)):
      return dimensions1 == dimensions2 && contents1 == contents2
      
    case (.function, .function),
      (.userFunction, .userFunction):
      return false

    default:
      return false
    }
  }

  case undefined
  case number(Float)
  case string(String)
  case function(([Value]) -> Value)
  case userFunction(String, Expression, Type)
  case arrayOfNumber([Int], [Float])

  func asFloat() -> Float {
    guard case .number(let value) = self else {
      print("asFloat() called on non-number")
      return -1
    }
    return value
  }

  func asString() -> String {
    guard case .string(let value) = self else {
      print("asString() called on non-string")
      return "???"
    }
    return value
  }

  func apply(_ args: [Value]) -> Value {
    guard case .function(let fn) = self else {
      print("apply() called on non-function")
      return Value.string("???")
    }

    return fn(args)
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

