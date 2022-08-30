@testable import bassi
import XCTest
import pcombo

final class WrapperTests: XCTestCase {

  class WrapOld<TheTarget>: Parser {
    typealias Input = Token
    typealias Target = TheTarget

    let basicParser: BasicParser
    let oldParser : () throws -> Target

    init(_ basicParser: BasicParser, _ oldParser : @escaping () throws -> Target) {
      self.basicParser = basicParser
      self.oldParser = oldParser
    }

    func parse(_ input: ArraySlice<Token>) -> ParseResult<Token, Target> {
      let originalIndex = basicParser.tokenIndex
      defer {
        basicParser.tokenIndex = originalIndex
      }

      do {
        let result = try oldParser()
        return ParseResult.success(result, basicParser.tokens[basicParser.tokenIndex...])
      } catch ParseError.error(let token, let message) {
        return .failure(basicParser.indexOf(token), message)
      } catch {
        return .failure(0, "can't happen \(error)")
      }
    }
  }

  func test_WrapOldWithSuccessfulParse() throws {
    let basicParser = BasicParser(Lexer("RETURN"))
    XCTAssertEqual(basicParser.tokenIndex, 0)

    let result = WrapOld<Statement>(basicParser, basicParser.returnStatement).parse(basicParser.tokens)

    guard case .success(let statement, let remaining) = result else {
      XCTFail("expected success but got \(result)")
      return
    }

    XCTAssertEqual(statement, .return)
    XCTAssertEqual(remaining.startIndex, 1)
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
