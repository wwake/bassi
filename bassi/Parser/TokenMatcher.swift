//
//  TokenMatcher.swift
//  bassi
//
//  Created by Bill Wake on 8/19/22.
//

import Foundation
import pcombo

public class TokenMatcher {
  private var tokens: [Token] = []

  let tokenNames : [TokenType : String] =
  [
    .integer: "integer",
    .minus: "'-'",
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
    let tokenDescription = tokenNames[tokenType] ?? "expected character \(tokenType)"
    return match(tokenType, "Missing \(tokenDescription)")
  }

  func match(_ tokenType: TokenType, _ message: String) -> satisfy<Token> {
    return satisfy(message) { $0.type == tokenType }
  }

  func oneOf(_ tokens: [TokenType], _ message: String) -> satisfy<Token> {
    satisfy(message) { Set(tokens).contains($0.type) }
  }
}
