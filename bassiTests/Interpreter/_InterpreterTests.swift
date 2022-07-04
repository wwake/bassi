//
//  InterpreterTests.swift
//  bassiTests
//
//  Created by Bill Wake on 5/9/22.
//

import XCTest
@testable import bassi

class InterpreterTests: XCTestCase {
   func checkProgramResults(_ program: String, expecting: String) {
    do {
      let interactor = Interactor()
      let interpreter = Interpreter(Program(program), interactor)
      try interpreter.run()
      XCTAssertEqual(interactor.output, expecting)
    } catch {
      XCTFail("\(error)")
    }
  }

  func checkProgramResultsWithInput(_ program: String, input: String, expecting: String) {
    do {
      let interactor = Interactor()
      interactor.input = input

      let interpreter = Interpreter(Program(program), interactor)
      try interpreter.run()

      XCTAssertEqual(interactor.output, expecting)
    } catch {
      XCTFail("\(error)")
    }
  }

  func checkExpectedError(_ program: String, expecting: String) {
    do {
      let interactor = Interactor()

      let interpreter = Interpreter(Program(program), interactor)
      let _ = try interpreter.run()
      XCTFail("Should have thrown error")
    } catch InterpreterError.error(_, let message){
      XCTAssertEqual(message, expecting)
    } catch {
      XCTFail("Unexpected error \(error)")
    }
  }

  func checkPrintWithRelop(_ op: String, _ expected: Int) throws {
    let program = "40 PRINT 10 \(op) 10"
    checkProgramResults(program, expecting: " \(expected) \n")
  }

  func checkOppositeRelationalOps(
    _ op1ExpectedTrue: String,
    _ op2ExpectedFalse: String) throws {
      try checkPrintWithRelop(op1ExpectedTrue, 1)
      try checkPrintWithRelop(op2ExpectedFalse, 0)
    }
}
