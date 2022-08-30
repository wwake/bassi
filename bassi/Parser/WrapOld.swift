//
//  WrapOld.swift
//  bassiTests
//
//  Created by Bill Wake on 8/30/22.
//

import Foundation
import pcombo

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
      basicParser.tokenIndex = input.startIndex
      let result = try oldParser()
      return ParseResult.success(result, basicParser.tokens[basicParser.tokenIndex...])
    } catch ParseError.error(let token, let message) {
      return .failure(basicParser.indexOf(token), message)
    } catch {
      return .failure(0, "can't happen \(error)")
    }
  }
}
