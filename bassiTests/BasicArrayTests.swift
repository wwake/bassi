@testable import bassi
import XCTest

final class BasicArrayTests: XCTestCase {

  func checkIndexes(index: Int, expected: [Int]) {
    let array = BasicArray([2,2,3], .number)
    let result = array.indexesFor(index)
    XCTAssertEqual(result, expected)
  }

  func test_indexes() {
    checkIndexes(index: 0, expected: [0,0,0])
    checkIndexes(index: 2, expected: [0,0,2])
    checkIndexes(index: 3, expected: [0,1,0])
    checkIndexes(index: 8, expected: [1,0,2])
    checkIndexes(index: 11, expected: [1,1,2])
  }
 
  func test_debugName() {
    let array = BasicArray([1,2,3], .string)
    XCTAssertEqual(array.debugName("A$", 8), "A$(0,0,2)")
  }

  func test_debugContents() {
    let array = BasicArray([2], .number)
    XCTAssertEqual(
      array.debugContents("A"),
      ["A(0)= 0 ", "A(1)= 0 "])
  }
}
