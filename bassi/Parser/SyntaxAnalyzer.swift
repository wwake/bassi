//
//  Parser.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation
import pcombo

protocol Tokenizer {
  func indexOf(_ token: Token) -> Array<Token>.Index
}

public class SyntaxAnalyzer: Tokenizer {
  let maxLineNumber = 99999

  var lexer: Lexer = Lexer("")

  var tokens: [Token] = []
  var index = -1

  var token: Token {
    tokens[index]
  }

  let tokenNames : [TokenType : String] =
  [
    .leftParend: "'('",
    .rightParend : "')'",
    .variable: "variable name"
  ]

  var lineNumber = 0
  var columnNumber = 0

  var expressionParser : Bind<Token, Expression> = Bind()

  var statementParser: Bind<Token, Statement> = Bind()
  var lineParser: Bind<Token, Parse> = Bind()

  init() {

    defer {
      expressionParser = ExpressionParser(self).make()

      statementParser = StatementParser(expressionParser, self).makeStatementParser()

      let line =
      match(.integer, "Line number is required at start of statement")
      <&> statementParser <&& match(.colon)
      <& match(.eol, "Extra characters at end of line")
      |&> makeLine

      lineParser.bind(line.parse)
    }
  }

  func indexOf(_ token: Token) -> Array<Token>.Index {
    return tokens.firstIndex(of: token)!
  }

  func match(_ tokenType: TokenType) -> satisfy<Token> {
    let tokenDescription = tokenNames[tokenType] ?? "expected character"
    return match(tokenType, "Missing \(tokenDescription)")
  }

  func match(_ tokenType: TokenType, _ message: String) -> satisfy<Token> {
    return satisfy(message) { $0.type == tokenType }
  }

  func parse(_ input: String) -> Parse {
    lexer = Lexer(input)

    tokens = lexer.line()
    index = 0

    return singleLine()
  }

  func singleLine() -> Parse {
    let result = lineParser.parse(tokens[...])

    switch result {
    case .failure(let position, let message):
      let errorLine = tokens[0].type == .integer ? LineNumber(tokens[0].float!) : 0
      let errorColumn = tokens[position].column
      return Parse(errorLine, [.error(errorLine, errorColumn, message)])

    case .success(let parse, _):
      return parse
    }
  }

  func makeLine(_ argument: (Token, [Statement]), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Parse> {
    let (token, statements) = argument

    let lineNumber = LineNumber(token.float)
    if lineNumber <= 0 || lineNumber > maxLineNumber {
      return .failure(indexOf(token)+1, "Line number must be between 1 and \(maxLineNumber)")
    }

    return .success(Parse(LineNumber(lineNumber), statements), remaining)
  }
}
