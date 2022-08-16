//
//  ParserCombinators.swift
//  bassi
//
//  Created by Bill Wake on 8/15/22.
//

import Foundation
import pcombo

public class Check2<P: Parser, Target2> : Parser {
  public typealias Input = P.Input
  public typealias Target = Target2

  let parser : P
  let checker: (P.Target, ArraySlice<P.Input>)
                                    -> ParseResult<P.Input, Target2>

  init(_ parser: P, _ checker: @escaping (P.Target, ArraySlice<P.Input>) -> ParseResult<P.Input, Target2>) {
    self.parser = parser
    self.checker = checker
  }

  public func parse(_ input: ArraySlice<P.Input>) -> ParseResult<P.Input, Target2> {
    let parse = parser.parse(input)

    switch parse {
    case .failure(let position, let message):
      return .failure(position, message)

    case .success(let target, let remaining):
      return checker(target, remaining)
    }
  }
}

infix operator |&> : MultiplicationPrecedence

public func |&> <P: Parser, Target2>(p: P, fn: @escaping (P.Target, ArraySlice<P.Input>) -> ParseResult<P.Input, Target2>) -> Check2<P, Target2> {
  return Check2(p, fn)
}


public class inject<Input, InjectedValue> : Parser {
  public typealias Target = InjectedValue

  let value: InjectedValue

  init(_ value: InjectedValue) {
    self.value = value
  }

  public func parse(_ input: ArraySlice<Input>) -> ParseResult<Input, Target> {
    return .success(value, input)
  }
}
