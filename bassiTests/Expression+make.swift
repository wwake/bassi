//
//  Expression+make.swift
//  bassiTests
//
//  Created by Bill Wake on 5/12/22.
//

import Foundation
@testable import bassi

extension Expression {
  static func make(
    _ int1: Float,
    _ operator1: Token,
    _ int2: Float)
  -> Expression {
    .op2(
      operator1,
      .number(.integer(int1)),
      .number(.integer(int2)))
  }

  static func make(
    _ int1: Float,
    _ operator1: Token,
    _ int2: Float,
    _ operator2: Token,
    _ int3: Float)
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
