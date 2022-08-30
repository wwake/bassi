@testable import bassi
import XCTest
import pcombo

final class WrapperTests: XCTestCase {
  func test_WrapOldWithSuccessfulParse() throws {
    let input = "10RETURN"
    let basicParser = BasicParser(Lexer(input))
    XCTAssertEqual(basicParser.tokenIndex, 0)

    let result = WrapOld<Statement>(basicParser, basicParser.returnStatement).parse(basicParser.tokens[1...])

    guard case .success(let statement, let remaining) = result else {
      XCTFail("expected success but got \(result)")
      return
    }

    XCTAssertEqual(statement, .return)
    XCTAssertEqual(remaining.startIndex, 2)
    XCTAssertEqual(basicParser.tokenIndex, 0)
  }

  func test_WrapOldWithFailedParse() throws {
    let basicParser = BasicParser(Lexer("GOTO"))  // missing target
    XCTAssertEqual(basicParser.tokenIndex, 0)

    let result = WrapOld<Statement>(basicParser, basicParser.goto).parse(basicParser.tokens)

    guard case .failure(let errorIndex, let message) = result else {
      XCTFail("expected failure but got \(result)")
      return
    }

    XCTAssertEqual(errorIndex, 1)
    XCTAssertEqual(message, "Missing target of GOTO")
    XCTAssertEqual(basicParser.tokenIndex, 0)
  }
}
