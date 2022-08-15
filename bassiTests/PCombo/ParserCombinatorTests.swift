//
//  Check2Tests.swift
//
//
//  Created by Bill Wake on 8/15/22.
//

@testable import bassi
import XCTest
import pcombo

extension ParseResult {
  func checkSuccess(
    _ expectedTarget: Target,
    _ expectedRemaining: ArraySlice<Input>)
  where Target: Equatable, Input: Equatable
  {
    guard case let .success(target, remaining) = self else {
      XCTFail("Result was \(self)")
      return
    }
    XCTAssertEqual(target, expectedTarget, "target")
    XCTAssertEqual(remaining, expectedRemaining, "remaining")
  }

  func checkFailure(_ expected: ParseResult<Int, Target>) where Target: Equatable {

    if case let .failure(location1, message1) = self {
      if case let .failure(location2, message2) = expected {
        XCTAssertEqual(location1, location2, "location")
        XCTAssertEqual(message1, message2, "message")
        return
      }
    }

    XCTFail("Expected \(expected) but got \(self)")
  }
}

final class Check2Tests: XCTestCase {
  func sumShouldBeEven(_ values: [Int], _ remaining: ArraySlice<Int>) -> ParseResult<Int, String> {
    let sum = values.reduce(0, +)
    if sum.isMultiple(of: 2) { return .success("Result: \(sum)", remaining) }
    return .failure(values.count, "sum was odd")
  }

  func testReturnsParseResultWhenCheckSucceeds() {
    let one = satisfy { $0 == 1 }
    let parser = <+>one |&> sumShouldBeEven
    let result = parser.parse([1,1,1,1,2])
    result.checkSuccess("Result: 4", [2])
  }

  func testReturnsFailureWhenCheckFails() {
    let one = satisfy { $0 == 1 }
    let parser = <+>one |&> sumShouldBeEven
    let result = parser.parse([1,1,1,2])
    result.checkFailure(.failure(3, "sum was odd"))
  }

  func testReturnsFailureWhenParseFails() {
    let one = satisfy { $0 == 1 }
    let parser = <+>one |&> sumShouldBeEven
    let result = parser.parse([2])
    result.checkFailure(.failure(0, "Did not find expected value"))
  }
}
