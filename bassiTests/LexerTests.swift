//
//  ScannerTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/9/22.
//

import Foundation
import XCTest
@testable import bassi

class LexerTests: XCTestCase {

  func testRemark() throws {
    let program = "10  REM Comment"
    let lexer = Lexer(program)
    let token1 = lexer.next()
    let token2 = lexer.next()
    XCTAssertEqual(token1, Token.line(10))
    XCTAssertEqual(token2, Token.remark)
  }
}
