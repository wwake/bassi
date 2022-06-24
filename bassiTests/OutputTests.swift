@testable import bassi
import XCTest

final class OutputTests: XCTestCase {

  func testAppend() throws {
    let output = Output()
    output.append("Hello ")
    output.append("World")
    XCTAssertEqual(output.output, "Hello World")
  }

  func testOutputTracksColumn() {
    let output = Output()
    XCTAssertEqual(output.column(), 0)
    output.append("123")
    XCTAssertEqual(output.column(), 3)
    output.append("\nabcd")
    XCTAssertEqual(output.column(), 4)
  }
}
