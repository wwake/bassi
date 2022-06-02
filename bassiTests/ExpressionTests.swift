//
//  ExpressionTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/25/22.
//

import XCTest
@testable import bassi

class ExpressionTests: XCTestCase {
  func testNumberHasTypeFloat() {
    let number = Expression.number(37.5)
    XCTAssertEqual(number.type(), .number)
  }

  func testVariableHasSpecifiedType() {
    XCTAssertEqual(Expression.variable("X", .number).type(), .number)
    XCTAssertEqual(Expression.variable("Y", .string).type(), .string)
  }

  func testOperatorsAllHaveTypeFloat() {
    XCTAssertEqual(
      Expression.op1(.minus, .number(3)).type(),
      .number)
    XCTAssertEqual(
      Expression.op2(.plus,
          .number(1),
          .number(2)).type(),
      .number)
  }

  func testCallOfPredefinedFunctionHasProperReturnType() {
    let call = Expression.predefined("CHR$", [.number(3)], .string)
    XCTAssertEqual(call.type(), .string)
  }

}
