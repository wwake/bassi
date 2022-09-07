//
//  SyntaxAnalyzer.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation
import pcombo

public class SyntaxAnalyzer {
  var lineNumber = 0
  var columnNumber = 0

  var singleLineParser: Bind<Token, Parse>!
  var statementsParser: Bind<Token, [Statement]>!
  var expressionParser: Bind<Token, Expression>!

  init() {
    defer {
      expressionParser = ExpressionParser().makeExpressionParser()

      let statementParser = StatementParser()
      statementsParser = statementParser.makeStatementsParser(expressionParser)
      singleLineParser = statementParser.makeSingleLineParser(statementsParser)
    }
  }

  func parse(_ tokens: ArraySlice<Token>) -> Parse {
    let result = singleLineParser.parse(tokens)

    switch result {
    case .success(let parseResult, _):
      return parseResult

    case .failure(let errorIndex, let message):
      let errorToken = tokens[errorIndex]
      return Parse(
        errorToken.line,
        [.error(errorToken.line, errorToken.column, message)])
    }
  }
}
