@testable import bassi
import XCTest

final class InteractorTests: XCTestCase {

  func test_GetLineClearsInput() throws {
    let interactor = Interactor()
    interactor.input("test line")

    let line = interactor.getLine()
    XCTAssertEqual(line, "test line")

    let line2 = interactor.getLine()
    XCTAssertEqual(line2, "")
  }
}
