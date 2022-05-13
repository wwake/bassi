//
//  REPLTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/13/22.
//

import XCTest
@testable import bassi

class ReplTests: XCTestCase {

  func testAddingLineSavesIt() {
    let repl = Repl()
    repl.execute("10 PRINT 42")

    XCTAssertTrue(repl.contains("10"))
    XCTAssertFalse(repl.contains("20"))
  }

}
