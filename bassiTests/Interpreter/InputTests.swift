//
//  InputTests.swift
//  bassiTests
//
//  Created by Bill Wake on 7/4/22.
//

import XCTest
@testable import bassi

class InputTests: InterpreterTests {
  func testInputWithOneStringVariable() {
    checkProgramResultsWithInput(
      "10 INPUT X$\n20 PRINT X$",
      input: "hello",
      expecting: "? hello\nhello\n")
  }

  func testInputWithTwoStringVariables() {
    checkProgramResultsWithInput(
      "10 INPUT X$, Y$\n20 PRINT X$ Y$",
      input: "hello , world",
      expecting: "? hello , world\nhello  world\n")
  }

  func testInputToNumericArrayCell() {
    checkProgramResultsWithInput(
      "10 INPUT B(3)\n20 PRINT B(3) B(4)",
      input: "42",
      expecting: "? 42\n 42  0 \n")
  }

  func testInputToStringArrayCell() {
    checkProgramResultsWithInput(
      "10 INPUT B$(3)\n20 PRINT B$(3)",
      input: "Hiya",
      expecting: "? Hiya\nHiya\n")
  }

  func testInputWithNumericVariables() throws {
    checkProgramResultsWithInput(
      "10 INPUT X, Y\n20 PRINT X Y",
      input: "3.0 , 4 ",
      expecting: "? 3.0 , 4 \n 3  4 \n")
  }

  func testInputWithStringForNumericVariable() throws {
    let interactor = Interactor()
    interactor.input("hello, 4.75")

    let interpreter = Interpreter(Program("10 INPUT X,Y\n20 PRINT X,Y"), interactor)

    do {
      try interpreter.run()
    } catch InterpreterError.error(let lineNumber, let message) {
      XCTAssertEqual(lineNumber, 10)
      XCTAssertEqual(message, "Non-numeric input for numeric variable; try again")
    }
  }

  func testResumeFromInput() throws {
    let interactor = Interactor()
    let interpreter = Interpreter(Program("10 INPUT S$\n20 PRINT S$"), interactor)
    try interpreter.run()

    interactor.input("hello")
    try interpreter.continueAfterInput()
    XCTAssertEqual(interactor.output, "? hello\nhello\n")
  }

  func testInputWithTooFewValuesThrows() throws {
    let interactor = Interactor()
    let interpreter = Interpreter(Program("10 INPUT S$, T$\n20 PRINT S$, T$"), interactor)
    try interpreter.run()

    XCTAssertTrue(interpreter.awaitingInput)

    interactor.input("hello")

    do {
      try interpreter.continueAfterInput()
    } catch InterpreterError.error(let lineNumber, let message) {
      XCTAssertEqual(lineNumber, 10)
      XCTAssertEqual(message, "Not enough input values; try again")
    }
  }

  func testInputWithTooManyValuesPrintsMessageAndIgnoresThem() throws {
    checkProgramResultsWithInput(
      "10 INPUT X, Y\n20 PRINT X Y",
      input: "3.0, 4, extra words, 99",
      expecting: "? 3.0, 4, extra words, 99\n? Extra input ignored\n 3  4 \n")
  }

  func testInputWithPrompt() throws {
    checkProgramResultsWithInput(
      "10 INPUT \"prompt\"; X\n20 PRINT X",
      input: "42",
      expecting: "prompt? 42\n 42 \n")
  }

  func testInputPromptShowsBeforeAttemptingInput() throws {
    let interactor = Interactor()
    let interpreter = Interpreter(Program("10 INPUT \">>\"; S$\n20 PRINT S$"), interactor)
    try interpreter.run()

    XCTAssertEqual(interactor.output, ">>? ")

    interactor.input("hello")
    try interpreter.continueAfterInput()
    XCTAssertEqual(interactor.output, ">>? hello\nhello\n")
  }


}
