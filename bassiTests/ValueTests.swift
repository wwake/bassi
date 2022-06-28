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

  func test_formatArray() {
    let array: Value = Value.array(
      [1,2],
      Array(repeating: .number(3), count: 6))

    XCTAssertEqual(array.format(), "Array<Value>")
  }

  func test_formatOther() {
    XCTAssertEqual(Value.undefined.format(), "<UNDEFINED>")
    XCTAssertEqual(Value.function({ _ in .number(2)}).format(), "<FUNCTION>")
    XCTAssertEqual(Value.userFunction("FNA", .number(7), .number).format(), "<USER-FUNCTION>")
  }
}
