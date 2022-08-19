//
//  SyntaxAnalyzer.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation
import pcombo

public class TokenMatcher {
  private var tokens: [Token] = []

  let tokenNames : [TokenType : String] =
  [
    .leftParend: "'('",
    .rightParend : "')'",
    .variable: "variable name"
  ]

  func setTokens(_ tokens: [Token]) {
    self.tokens = tokens
  }

  var lineNumber : LineNumber {
    return tokens[0].type == .integer
      ? LineNumber(tokens[0].float!)
      : LineNumber(0)
  }

  var tokenSlice: ArraySlice<Token> {
    tokens[...]
  }

  func columnAt(_ position: Int) -> Int {
    tokens[position].column
  }

  func indexOf(_ token: Token) -> Array<Token>.Index {
    return tokens.firstIndex(of: token)!
  }

  func match1(_ tokenType: TokenType) -> satisfy<Token> {
    let tokenDescription = tokenNames[tokenType] ?? "expected character"
    return match(tokenType, "Missing \(tokenDescription)")
  }

  func match(_ tokenType: TokenType, _ message: String) -> satisfy<Token> {
    return satisfy(message) { $0.type == tokenType }
  }
}

public class SyntaxAnalyzer {
  let maxLineNumber = 99999

  var lexer: Lexer = Lexer("")

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

  var tokenizer = TokenMatcher()

  var match: ((_ tokenType: TokenType, _ message: String) -> satisfy<Token>)! = nil

  init() {

    defer {
      match = tokenizer.match

      expressionParser = ExpressionParser(tokenizer).make()

      statementParser = StatementParser(expressionParser, tokenizer).makeStatementParser()

      let line =
      match(.integer, "Line number is required at start of statement")
      <&> statementParser <&& match(.colon, ":")
      <& match(.eol, "Extra characters at end of line")
      |&> makeLine

      lineParser.bind(line.parse)
    }
  }

  func parse(_ input: String) -> Parse {
    lexer = Lexer(input)

    let tokens = lexer.line()
    tokenizer.setTokens(tokens)

    return singleLine()
  }

  func singleLine() -> Parse {
    let result = lineParser.parse(tokenizer.tokenSlice)

    switch result {
    case .failure(let position, let message):
      let errorLine = tokenizer.lineNumber
      let errorColumn = tokenizer.columnAt(position)
      return Parse(errorLine, [.error(errorLine, errorColumn, message)])

    case .success(let parse, _):
      return parse
    }
  }

  func makeLine(_ argument: (Token, [Statement]), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Parse> {
    let (token, statements) = argument

    let lineNumber = LineNumber(token.float)
    if lineNumber <= 0 || lineNumber > maxLineNumber {
      return .failure(tokenizer.indexOf(token)+1, "Line number must be between 1 and \(maxLineNumber)")
    }

    return .success(Parse(LineNumber(lineNumber), statements), remaining)
  }
}
