//
//  bassiTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/8/22.
//

import XCTest
@testable import bassi

class bassiTests: XCTestCase {

//  override func setUpWithError() throws {
//    // Put setup code here. This method is called before the invocation of each test method in the class.
//  }
//
//  override func tearDownWithError() throws {
//    // Put teardown code here. This method is called after the invocation of each test method in the class.
//  }

  func testExample() throws {
    let program = "10 REM Comment"
    let interpreter = Interpreter()
    let output = interpreter.run(program)
    XCTAssertEqual(output, "")
  }
}
