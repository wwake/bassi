//
//  Statement.swift
//  bassi
//
//  Created by Bill Wake on 9/5/22.
//

import Foundation
import pcombo

public class StatementParser {
  let maxLineNumber = 99999

  var expressionParser: Bind<Token, Expression>!

  private func match(_ type: TokenType, _ message: String = "Didn't find expected value") -> satisfy<Token> {
    satisfy<Token>(message) { $0.type == type }
  }

  func indexOf(_ token: Token) -> Int {
    return 3
  }

  fileprivate func makeDefStatement(_ nameParameterExpr: ((Token, String), Expression), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Statement> {
    let ((token, name), expr) = nameParameterExpr

    guard token.string.count == 1 else {
      return .failure(indexOf(token), "DEF function name cannot be followed by extra letters")
    }

    let statement = Statement.def(
      "FN"+token.string,
      name,
      expr,
      .function([.number], .number))

    return .success(statement, remaining)
  }

  public func makeStatementsParser(_ expressionParser: Bind<Token,Expression>) -> Bind<Token, [Statement]> {
    let statementsParser = Bind<Token, [Statement]>()

    let variableParser =
    match(.variable, "Expected variable")
    <&> <?>(
      match(.leftParend, "Missing '('")
      &> expressionParser <&& match(.comma)
      <& match(.rightParend, "Missing ')'")
    )
    |> { (variableToken, exprs) -> Expression in
      let name = variableToken.string!

      let type : `Type` =
      name.last! == "$" ? .string : .number

      if (exprs == nil) {
        return .variable(name, type)
      } else {
        return .arrayAccess(name, type, exprs!)
      }
    }

    let requiredVariableParser = match(.variable, "Variable is required") |> { $0.string! }

    let assignParser =
    variableParser
    <& match(.equals, "Assignment is missing '='")
    <&> expressionParser
    |&> requireMatchingTypes
    |> { (lhs, rhs) in Statement.assign(lhs, rhs) }

    let dataParser =
    match(.data)
    &> match(.string, "Expected a data value") <&& match(.comma)
    |> { tokens in tokens.map {$0.string} }
    |> { strings in Statement.data(strings) }

    let defParser =
    match(.def)
    &>
    (  match(.fn, "DEF requires a name of the form FNx")
       &> match(.variable, "DEF requires a name of the form FNx")
       <& match(.leftParend, "Missing '('")
       <&> requiredVariableParser
       <& match(.rightParend, "DEF requires ')' after parameter")
    )
    <& match(.equals, "DEF requires '=' after parameter definition")
    <&> (expressionParser |&> requireFloatType)
    |&> makeDefStatement

    let dim1Parser =
    requiredVariableParser
    <& match(.leftParend, "Missing '('")
    <&> expressionParser <&& match(.comma)
    <& match(.rightParend, "Missing ')'")
    |> { (arrayName, dimensions) in
      return DimInfo(arrayName, dimensions, self.typeFor(arrayName))
    }

    let dimParser =
    match(.dim)
    &> dim1Parser <&& match(.comma)
    |> { Statement.dim($0) }

    let exprThenGoto =
    (expressionParser |&> requireFloatType)
    <& match(.then, "Missing 'THEN'")
    <&> match(.integer)
    |> {(expr, token) in Statement.ifGoto(expr, LineNumber(token.float))}

    let exprThenStatements =
    (expressionParser |&> requireFloatType)
    <& match(.then, "Missing 'THEN'")
    <&> statementsParser
    |> {(expr, stmts) in Statement.`if`(expr, stmts) }

    let forParser =
    match(.for)
    &> requiredVariableParser
    <& match(.equals, "'=' is required")
    <&> (expressionParser |&> requireFloatType)
    <& match(.to, "'TO' is required")
    <&> (expressionParser |&> requireFloatType)
    <&> <?>(
      match(.step)
      &> (expressionParser |&> requireFloatType)
    )
    |> { (varFromTo, stepOpt) -> Statement in
      let ((variable, initial), final) = varFromTo

      let step = stepOpt ?? Expression.number(1)
      return Statement.`for`(variable, initial, final, step)
    }

    let gosubParser =
    match(.gosub)
    &> match(.integer, "Missing target of GOSUB")
    |> { token in Statement.gosub(LineNumber(token.float))}

    let gotoParser =
    match(.goto)
    &> match(.integer, "Missing target of GOTO")
    |> { token in Statement.goto(LineNumber(token.float))}


    let ifThenParser =
    match(.if) &>
    (exprThenGoto <||> exprThenStatements <%> "Numeric type is required")

    let inputParser =
    match(.input)
    &> (<?>(match(.string) <& match(.semicolon, "? Semicolon required after prompt")))
    <&> variableParser <&& match(.comma)
    |> { (promptOpt, variables) -> Statement in
      let prompt = promptOpt?.string ?? ""
      return Statement.input(prompt, variables)
    }

    let letParser =
    match(.let) &> (assignParser <%> "LET is missing variable to assign to")

    let nextParser =
    match(.next)
    &> requiredVariableParser
    |> { Statement.next($0) }

    let onParser =
    match(.on)
    &> expressionParser
    <&> (match(.goto) <|> match(.gosub) <%> "ON statement requires GOTO or GOSUB")
    <&> (
      match(.integer, "ON requires a comma-separated list of line numbers")
      <&& match(.comma)
      |> { tokens in tokens.map {LineNumber($0.float)} }
    )
    |> { (exprGo, lineNumbers) -> Statement in
      let (expr, savedToken) = exprGo
      if savedToken.type == .goto {
        return .onGoto(expr, lineNumbers)
      } else {
        return .onGosub(expr, lineNumbers)
      }
    }

    let printParser =
    match(.print)
    &> <*>(
      (match(.semicolon) |> { _ in Printable.thinSpace })
      <|> (match(.comma) |> { _ in Printable.tab })
      <|> (expressionParser |> { Printable.expr($0) })
    )
    |> { printables -> Statement in
      var values = printables

      let needsNewline =
      values.count == 0
      || values.last! != .thinSpace && values.last != .tab

      if needsNewline {
        values.append(.newline)
      }

      return Statement.print(values)
    }

    let readParser =
    match(.read)
    &> variableParser <&& match(.comma)
    |> { exprs in Statement.read(exprs) }

    let statementParser =
    assignParser
    <|> dataParser
    <|> defParser
    <|> dimParser
    <|> match(.end) |> { _ in Statement.end }
    <|> forParser
    <|> gosubParser
    <|> gotoParser
    <|> ifThenParser
    <|> inputParser
    <|> letParser
    <|> nextParser
    <|> onParser
    <|> printParser
    <|> readParser
    <|> match(.remark) |> { _ in Statement.skip }
    <|> match(.restore) |> { _ in Statement.restore }
    <|> match(.return) |> { _ in Statement.return }
    <|> match(.stop) |> { _ in Statement.stop }
    <%> "Unknown statement"

    let theStatementsParser =
    statementParser <&& match(.colon, "Expected ':'")

    statementsParser.bind(theStatementsParser.parse)
    return statementsParser
  }

  func makeSingleLineParser(_ statementsParser: Bind<Token, [Statement]>) -> Bind<Token, Parse> {
    let lineParser =
    ( match(.integer, "Line number is required")
      |&> lineNumberInRange
    )
    <&> statementsParser
    <& match(.eol, "Extra characters at end of line")
    |> {(lineNumber, statements) in Parse(lineNumber, statements)}

    return Bind<Token, Parse>(lineParser.parse)
  }

  func lineNumberInRange(_ token: Token, _ remaining: ArraySlice<Token>) -> ParseResult<Token, LineNumber> {
    let lineNumber = LineNumber(token.float)
    if lineNumber <= 0 || lineNumber > maxLineNumber {
      return .failure(indexOf(token), "Line number must be between 1 and \(maxLineNumber)")
    }
    return .success(lineNumber, remaining)
  }

  func typeFor(_ name: String) -> `Type` {
    name.last! == "$" ? .string : .number
  }

  func requireFloatType(_ expr: Expression, _ remaining: ArraySlice<Token>) -> ParseResult<Token, Expression> {

    if expr.type() == .number {
      return .success(expr, remaining)
    }
    return .failure(remaining.startIndex-1, "Numeric type is required")
  }

  func requireMatchingTypes(_ exprExpr: (Expression, Expression), _ remaining: ArraySlice<Token>) -> ParseResult<Token, (Expression, Expression)> {
    let (left, right) = exprExpr

    if left.type() == right.type() {
      return .success(exprExpr, remaining)
    }

    return .failure(remaining.startIndex - 1, "Type mismatch")
  }
}
