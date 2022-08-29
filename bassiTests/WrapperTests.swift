@testable import bassi
import XCTest
import pcombo

final class WrapperTests: XCTestCase {
  var index = 0
  var tokens: ArraySlice<Token>!

  func returnStatement() throws -> Statement {
    index += 1
    return .`return`
  }

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
      do {
        let result = try oldParser()
        return ParseResult.success(result, basicParser.tokens[basicParser.tokenIndex...])
      } catch {
        return .failure(-1, "failed")
      }
    }
  }

  func test_WrapOldWithSuccessfulParse() throws {
    let basicParser = BasicParser(Lexer("RETURN"))

    let result = WrapOld<Statement>(basicParser, basicParser.returnStatement).parse(basicParser.tokens)

    guard case .success(let statement, let remaining) = result else {
      XCTFail("expected success but got \(result)")
      return
    }

    XCTAssertEqual(statement, .return)
    XCTAssertEqual(remaining.startIndex, 1)
  }

  func test_WrapOldWithFailedParse() throws {
//    XCTFail("Tests not yet implemented in WrapperTests")
  }
}
