//
//  ParserAdapters.swift
//  bassi
//
//  Created by Bill Wake on 8/10/22.
//

import Foundation
import pcombo

public class WrapNew<P : Parser>
where P.Input == Token
{
  let analyzer: SyntaxAnalyzer
  let parser: P

  public init(_ analyzer: SyntaxAnalyzer, _ parser: P) {
    self.analyzer = analyzer
    self.parser = parser
  }

  public func parse() throws -> P.Target {
    let result = parser.parse(analyzer.tokens[analyzer.index...])

    switch result {
    case .failure(let failureIndex, let message):
      throw ParseError.error(analyzer.tokens[failureIndex], message)

    case .success(let value, let remaining):
      analyzer.index = remaining.startIndex
      return value
    }
  }
}

public class WrapOld<In, Value> : Parser {
  public typealias Input = In

  public typealias Target = Value

  let analyzer : SyntaxAnalyzer
  let oldParser: () throws -> Value

  init(_ analyzer: SyntaxAnalyzer, _ oldParser: @escaping () throws -> Value) {
    self.analyzer = analyzer
    self.oldParser = oldParser
  }

  public func parse(_ input: ArraySlice<In>) -> ParseResult<Input, Target> {
    let oldIndex = analyzer.index
    do {
      analyzer.index = input.startIndex
      let result = try oldParser()
      return .success(result, input[analyzer.index...])
    } catch ParseError.error(let token, let message) {
      analyzer.index = oldIndex
      let failureTokenIndex = analyzer.tokens.firstIndex(of: token)!
      return .failure(failureTokenIndex, message)
    } catch {
      analyzer.index = oldIndex
      return .failure(0, "can't happen")
    }
  }
}
