//
//  _SyntaxErrorTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class _SyntaxErrorTests: InterpreterTests {
  func testErrorMessageIncludesLineNumber() throws {
    do {
      let program = "20 PRINT A(-2)"
      let outputter = Interactor()
      let interpreter = Interpreter(Program(program), outputter)
      let _ = try interpreter.run()
      XCTFail("Should have thrown error")
    } catch InterpreterError.error(let lineNumber, _) {
      XCTAssertEqual(lineNumber, 20)
    }
  }
}
