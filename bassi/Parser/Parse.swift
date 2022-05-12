//
//  Parse.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

indirect enum Parse : Equatable {
  case program([Parse])
  case line(Token, Parse)
  case skip
  case print([Expression])
  case number(Token)
}

indirect enum Expression: Equatable {
  case number(Token)
  case op2(Token, Expression, Expression)
}

extension Expression {
  static func make(
    _ int1: Int,
    _ operator1: Token,
    _ int2: Int)
  -> Expression {
    .op2(
      operator1,
      .number(.integer(int1)),
      .number(.integer(int2)))
  }

  static func make(
    _ int1: Int,
    _ operator1: Token,
    _ int2: Int,
    _ operator2: Token,
    _ int3: Int)
  -> Expression {
    .op2(
      operator2,
      .op2(
        operator1,
        .number(.integer(int1)),
        .number(.integer(int2))),
      .number(.integer(int3)))
  }
}
