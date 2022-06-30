@testable import bassi
import XCTest

final class BasicArrayTests: XCTestCase {

  func checkIndexes(index: Int, expected: [Int]) {
    let array = BasicArray([1,2,3], .number)
    let result = array.indexesFor(index)
    XCTAssertEqual(result, expected)
  }

  func test_indexes() {
    checkIndexes(index: 0, expected: [0,0,0])
    checkIndexes(index: 3, expected: [0,0,3])
    checkIndexes(index: 4, expected: [0,1,0])
    checkIndexes(index: 8, expected: [0,2,0])
    checkIndexes(index: 12, expected: [1,0,0])
    checkIndexes(index: 13, expected: [1,0,1])
    checkIndexes(index: 23, expected: [1,2,3])
  }
 

}
