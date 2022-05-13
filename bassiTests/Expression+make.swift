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
    _ num1: Float,
    _ operator1: Token,
    _ num2: Float)
  -> Expression {
    .op2(
      operator1,
      .number(num1),
      .number(num2))
  }

  static func make(
    _ num1: Float,
    _ operator1: Token,
    _ num2: Float,
    _ operator2: Token,
    _ num3: Float)
  -> Expression {
    .op2(
      operator2,
      .op2(
        operator1,
        .number(num1),
        .number(num2)),
      .number(num3))
  }
}
