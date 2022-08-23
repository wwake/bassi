//
//  SyntaxAnalyzer+Test.swift
//  bassiTests
//
//  Created by Bill Wake on 8/23/22.
//

import Foundation
import XCTest
@testable import bassi

extension String {
  func checkParse(_ expected: Expression) {
      let input = "10 PRINT \(self)"
      let parser = SyntaxAnalyzer()
      let result = parser.parse(input)
      XCTAssertEqual(
        result,
        Parse(
          10,
          [.print([.expr(expected), .newline])])
      )
    }

  func checkError(_ expected: String)
  {
    let line = self
    let parser = SyntaxAnalyzer()
    let output = parser.parse(line)

    if case .error(_, _, let actualMessage) = output.statements[0] {
      XCTAssertEqual(
        actualMessage,
        expected)
      return
    }

    XCTFail("no error found")
  }

  func checkStatement(
    _ expected: Statement)
  {
    let program = self
    let parser = SyntaxAnalyzer()
    let result = parser.parse(program)
    XCTAssertEqual(
      result.statements,
      [expected]
    )
  }

  func checkStatements(
    _ expected: [Statement])
  {
    let program = self
    let parser = SyntaxAnalyzer()
    let result = parser.parse(program)
    XCTAssertEqual(
      result.statements,
      expected
    )
  }

}
