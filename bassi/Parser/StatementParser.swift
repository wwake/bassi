//
//  StatementParser.swift
//  bassi
//
//  Created by Bill Wake on 8/18/22.
//

import Foundation
import pcombo

public class StatementParser {
  let tokenNames : [TokenType : String] =
  [
    .leftParend: "'('",
    .rightParend : "')'",
    .variable: "variable name"
  ]

  let tokenToSimpleStatement: [TokenType : Statement] = [
    .end : .end,
    .remark : .skip,
    .restore : .restore,
    .return : .return,
    .stop : .stop
  ]

  let expressionParser: Bind<Token, Expression>
  let tokenizer: TokenMatcher

  var statementParser : Bind<Token, Statement> = Bind()

  var match: ((TokenType, String) -> satisfy<Token>)! = nil

  var match1: ((TokenType) -> satisfy<Token>)! = nil

  var oneOf: (([TokenType], String) -> satisfy<Token>)! = nil

  enum ThenTarget {
    case lineNumber(Token)
    case statements([Statement])
  }

  init(_ expressionParser: Bind<Token, Expression>, _ tokenizer: TokenMatcher) {
    self.expressionParser = expressionParser

    self.tokenizer = tokenizer
    self.match = tokenizer.match
    self.match1 = tokenizer.match1
    self.oneOf = tokenizer.oneOf
  }

  func make() -> Bind<Token, Statement> {
    let variableParser =
    match1(.variable) <&> <?>(
      match1(.leftParend) &>
      expressionParser <&& match1(.comma)
      <& match1(.rightParend)
    ) |> makeVariableOrArray

    let commaVariablesParser =
    variableParser <&& match1(.comma)
    <%> "At least one variable is required"

    let oneWordStatement = oneOf([.end, .remark, .restore, .return, .stop], "Expected statement start not found") |> simpleStatement

    let assignParser =
    variableParser
    <& match(.equals, "Assignment is missing '='")
    <&> expressionParser
    |&> requireMatchingTypes
    |> { Statement.assign($0.0, $0.1) }


    let dataParser =
    match1(.data)
    &> match(.string, "Expected a data value") <&& match1(.comma)
    |> makeData


    let defPart =
    match1(.def)
    &> match(.fn, "DEF requires a name of the form FNx")
    &> match(.variable, "DEF requires a name of the form FNx")
    <& match1(.leftParend)

    let variablePart =
    match(.variable, "Variable is required")
    <& match(.rightParend, "DEF requires ')' after parameter")
    <& match(.equals, "DEF requires '=' after parameter definition")

    let functionAndVariable = defPart <&> variablePart

    let defineParser =
    (functionAndVariable <&> (expressionParser |&> requireFloatType))
    |&> checkDefStatement


    let dim1Parser =
    (match1(.variable)
     <& match1(.leftParend)
    )
    <&> expressionParser <&& match1(.comma)
    <& match1(.rightParend)
    |> makeDimension

    let dimParser =
    match1(.dim)
    &> dim1Parser <&& match1(.comma)
    |> { Statement.dim($0) }


    let forParser =
    (match1(.for)
     &> match1(.variable)
     <& match(.equals, "'=' is required")
    )
    <&> (expressionParser |&> requireFloatType)
    <&> (
      match(.to, "'TO' is required")
      &> expressionParser
      |&> requireFloatType
    )
    <&> <?>(match1(.step) &> expressionParser |&> requireFloatType)
    |&> makeForStatement


    let gosubParser =
    match1(.gosub)
    &> match(.integer, "Missing target of GOSUB")
    |> { Statement.gosub(LineNumber($0.float)) }


    let gotoParser =
    match1(.goto)
    &> match(.integer, "Missing target of GOTO")
    |> { Statement.goto(LineNumber($0.float)) }


    let ifPrefix =
    match1(.if)
    &> expressionParser
    <& match(.then, "Missing 'THEN'")
    |&> requireFloatType

    let ifTarget =
    ( match1(.integer) |> { ThenTarget.lineNumber($0) })
      <|>
    ( statementParser <&& match1(.colon)
        |> { ThenTarget.statements($0) })

    let ifParser =
      ifPrefix <&> ifTarget |> makeIfThen

    var defaultPrompt = Token(line: 0, column: 0, type: .string)
    defaultPrompt.string = ""

    let promptPlusVariables =
    match1(.string)
    <& match(.semicolon, "? Semicolon required after prompt")
    <&> commaVariablesParser

    let inputParser =
    match1(.input)
    &>
    (    promptPlusVariables
         <|> inject(defaultPrompt) <&> commaVariablesParser
    )
    |> makeInputStatement


    let letParser =
    match1(.let)
    &> (
      assignParser
      <%> "LET is missing variable to assign to"
    )


    let nextParser =
    match1(.next)
    &> match(.variable, "Variable is required")
    |> { Statement.next($0.string) }


    let onParser =
    ( match1(.on)
      &> expressionParser
    )
    <&> oneOf([.goto, .gosub], "ON statement requires GOTO or GOSUB")
    <&> (
      match1(.integer) <&& match1(.comma)
      <%> "ON statement requires comma-separated list of line numbers"
    )
    |> makeOnStatement


    let printParser =
    match1(.print)
    &> <*>(
      ( match1(.semicolon) |> { _ in Printable.thinSpace })
      <|> (match1(.comma) |> { _ in Printable.tab })
      <|> (expressionParser |> { Printable.expr($0) })
      <%> "Expected start of expression"
    )
    |> makePrintStatement


    let readParser =
    match1(.read) &> commaVariablesParser |> { Statement.read($0) }


    let theStatementParser =
    oneWordStatement
    <|> assignParser
    <|> dataParser
    <|> defineParser
    <|> dimParser
    <|> forParser
    <|> gosubParser
    <|> gotoParser
    <|> ifParser
    <|> inputParser
    <|> letParser
    <|> nextParser
    <|> onParser
    <|> printParser
    <|> readParser
    <%> "Unknown statement"

    statementParser.bind(theStatementParser.parse)
    return statementParser
  }

  func simpleStatement(_ token: Token) -> Statement {
    tokenToSimpleStatement[token.type]!
  }

  func typeFor(_ name: String) -> `Type` {
    name.last! == "$" ? .string : .number
  }

  func checkDefStatement(_ argument: ((Token, Token), Expression), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Statement> {
    let ((nameToken, parameterToken), expr) = argument

    let name = nameToken.string!

    if name.count != 1 {
      return .failure(tokenizer.indexOf(nameToken),  "DEF function name cannot be followed by extra letters")
    }

    let result = Statement.def(
      "FN"+name,
      parameterToken.string,
      expr,
      .function([.number], .number))
    return .success(result, remaining)
  }

  func requireFloatType(_ expr: Expression, _ remaining: ArraySlice<Token>) -> ParseResult<Token, Expression> {
    if expr.type() == .number {
      return .success(expr, remaining)
    }

    return .failure(remaining.startIndex, "Numeric type is required")
  }

  func requireMatchingTypes(_ argument: (Expression, Expression), _ remaining: ArraySlice<Token>) -> ParseResult<Token, (Expression, Expression)> {
    let (left, right) = argument

    if left.type() != right.type() {
      return .failure(remaining.startIndex, "Type mismatch")
    }
    return .success(argument, remaining)
  }

  func makeVariableOrArray(_ argument: (Token, [Expression]?)) -> Expression {
    let (token, exprs) = argument

    let name = token.string!
    let type : `Type` = typeFor(name)

    if exprs == nil {
      return .variable(name, type)
    }

    return .arrayAccess(name, type, exprs!)
  }

  func makeData(_ tokens: [Token]) -> Statement {
    let strings = tokens.map { $0.string! }
    return .data(strings)
  }

  func makeDimension(_ argument: (Token, [Expression])) -> DimInfo {
    let (token, dimensions) = argument
    let arrayName = token.string!
    return DimInfo(arrayName, dimensions, typeFor(arrayName))
  }

  func makeForStatement(_ argument: (((Token, Expression), Expression), Expression?), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Statement> {
    let (((variable, initial), final), stepOptional) = argument

    let step = stepOptional == nil ? Expression.number(1) : stepOptional!

    let statement = Statement.for(variable.string, initial, final, step)
    return .success(statement, remaining)
  }

  func makeIfThen(_ argument: (Expression, ThenTarget)) -> Statement {
    let (expr, thenTarget) = argument

    switch thenTarget {
    case .lineNumber(let token):
      return .ifGoto(expr, LineNumber(token.float!))

    case .statements(let statements):
      return .`if`(expr, statements)
    }
  }

  func makeInputStatement(_ argument: (Token?, [Expression])) -> Statement {
    let (tokenOptional, exprs) = argument

    let prompt = tokenOptional == nil ? "" : tokenOptional!.string!

    return .input(prompt, exprs)
  }

  func makeOnStatement(_ argument: ((Expression, Token), [Token])) -> Statement {
    let ((expr, typeToken), targetTokens) = argument

    let targets = targetTokens.map { LineNumber($0.float) }

    return typeToken.type == .goto
    ? .onGoto(expr, targets)
    : .onGosub(expr, targets)
  }

  func makePrintStatement(_ arguments: [Printable]) -> Statement {
    var values = arguments

    if values.count == 0 {
      return Statement.print([.newline])
    }

    if values.last! != .thinSpace && values.last != .tab {
      values.append(.newline)
    }

    return Statement.print(values)
  }
}
