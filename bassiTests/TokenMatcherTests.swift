@testable import bassi
import XCTest

final class TokenMatcherTests: XCTestCase {

    func testMatch1DefaultsMessageToTokenTypeName() throws {

      let matcher = TokenMatcher()
      let token = Token(line: 1, column: 2, type: .integer)
      let result = matcher.match1(.not).parse([token])

      guard case .failure(let position, let message) = result else {
        XCTFail("Should return failure: \(result)")
        return
      }
      XCTAssertEqual(position, 0)
      XCTAssertEqual(message, "Expected 'not'")
    }
}
