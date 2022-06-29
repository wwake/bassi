@testable import bassi
import XCTest

final class ValueTests: XCTestCase {

  func test_formatNumbers() throws {
    XCTAssertEqual(Value.number(35).format(), " 35 ")
    XCTAssertEqual(Value.number(27.5).format(), " 27.500000 ")
  }

  func test_formatString() {
    XCTAssertEqual(Value.string("hello").format(), "hello")
  }

  func test_formatNumericArray() {
    let array: Value = Value.array(
      BasicArray([2,3],
                 Array(repeating: .number(3), count: 12),
                 .number))

    XCTAssertEqual(array.format(), "Array(1,2): number")
  }

  func test_formatStringArray() {
    let array: Value = Value.array(
      BasicArray([3,2],
                   Array(repeating: .string("hi"), count: 12),
                   .string))

    XCTAssertEqual(array.format(), "Array(2,1): string")
  }

  func test_formatOther() {
    XCTAssertEqual(Value.undefined.format(), "<UNDEFINED>")
    XCTAssertEqual(Value.function({ _ in .number(2)}).format(), "<FUNCTION>")
    XCTAssertEqual(Value.userFunction("FNA", .number(7), .number).format(), "<USER-FUNCTION>")
  }
}
