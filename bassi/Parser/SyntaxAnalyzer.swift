//
//  Parser.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation
import pcombo

public class SyntaxAnalyzer {
  let maxLineNumber = 99999

  var lexer: Lexer = Lexer("")

  var tokens: [Token] = []
  var index = -1

  var token: Token {
    tokens[index]
  }

  var lineNumber = 0
  var columnNumber = 0

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

  var expressionParser : Bind<Token, Expression> = Bind()

  var statementParser: Bind<Token, Statement> = Bind()
  var lineParser: Bind<Token, Parse> = Bind()

  init() {

    defer {
      expressionParser = ExpressionParser(self).makeExpressionParser()

      statementParser.bind(makeStatementParser().parse)

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

  func oneOf(_ tokens: [TokenType], _ message : String = "Expected symbol not found") -> satisfy<Token> {
    satisfy(message) { Set(tokens).contains($0.type) }
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

  func simpleStatement(_ token: Token) -> Statement {
    tokenToSimpleStatement[token.type]!
  }

  func makeStatementParser() -> Bind<Token, Statement> {
    let variableParser =
    match(.variable) <&> <?>(
      match(.leftParend) &>
      expressionParser <&& match(.comma)
      <& match(.rightParend)
    ) |> makeVariableOrArray

    let commaVariablesParser =
    variableParser <&& match(.comma)
    <%> "At least one variable is required"


    let oneWordStatement = oneOf([.end, .remark, .restore, .return, .stop]) |> simpleStatement


    let assignParser =
    variableParser
    <& match(.equals, "Assignment is missing '='")
    <&> expressionParser
    |&> requireMatchingTypes
    |> { Statement.assign($0.0, $0.1) }


    let dataParser =
    match(.data)
    &> match(.string, "Expected a data value") <&& match(.comma)
    |> makeData


    let defPart =
    match(.def)
    &> match(.fn, "DEF requires a name of the form FNx")
    &> match(.variable, "DEF requires a name of the form FNx")
    <& match(.leftParend)

    let variablePart =
    match(.variable, "Variable is required")
    <& match(.rightParend, "DEF requires ')' after parameter")
    <& match(.equals, "DEF requires '=' after parameter definition")

    let tokens = defPart <&> variablePart

    let defineParser =
    AndThenTuple(tokens, expressionParser |&> requireFloatType)
    |&> checkDefStatement


    let dim1Parser =
    (match(.variable)
     <& match(.leftParend)
    )
    <&> expressionParser <&& match(.comma)
    <& match(.rightParend)
    |> makeDimension

    let dimParser =
    match(.dim)
    &> dim1Parser <&& match(.comma)
    |> { Statement.dim($0) }


    let forParser =
    (match(.for)
     &> match(.variable)
     <& match(.equals, "'=' is required")
    )
    <&> (expressionParser |&> requireFloatType)
    <&> (
      match(.to, "'TO' is required")
      &> expressionParser
      |&> requireFloatType
    )
    <&> <?>(match(.step) &> expressionParser |&> requireFloatType)
    |&> makeForStatement


    let gosubParser =
    match(.gosub)
    &> match(.integer, "Missing target of GOSUB")
    |> { Statement.gosub(LineNumber($0.float)) }


    let gotoParser =
    match(.goto)
    &> match(.integer, "Missing target of GOTO")
    |> { Statement.goto(LineNumber($0.float)) }


    let ifPrefix =
    match(.if)
    &> expressionParser
    <& match(.then, "Missing 'THEN'")
    |&> requireFloatType

    let ifParser =
    (ifPrefix <&> match(.integer) |&> makeIfGoto)
    <|>
    (ifPrefix <&> statementParser <&& match(.colon)
     |&> makeIfStatements)


    var defaultPrompt = Token(line: 0, column: 0, type: .string)
    defaultPrompt.string = ""

    let promptPlusVariables =
    match(.string)
    <& match(.semicolon, "? Semicolon required after prompt")
    <&> commaVariablesParser

    let inputParser =
    match(.input)
    &>
    (    promptPlusVariables
         <|> inject(defaultPrompt) <&> commaVariablesParser
    )
    |> makeInputStatement


    let letParser =
    match(.let)
    &> (
      assignParser
      <%> "LET is missing variable to assign to"
    )


    let nextParser =
    match(.next)
    &> match(.variable, "Variable is required")
    |> { Statement.next($0.string) }


    let onParser =
    ( match(.on)
      &> expressionParser
    )
    <&> oneOf([.goto, .gosub], "ON statement requires GOTO or GOSUB")
    <&> (
      match(.integer) <&& match(.comma)
      <%> "ON statement requires comma-separated list of line numbers"
    )
    |> makeOnStatement


    let printParser =
    match(.print)
    &> <*>(
      ( match(.semicolon) |> { _ in Printable.thinSpace })
      <|> (match(.comma) |> { _ in Printable.tab })
      <|> (expressionParser |> { Printable.expr($0) })
      <%> "Expected start of expression"
    )
    |> makePrintStatement


    let readParser =
    match(.read) &> commaVariablesParser |> { Statement.read($0) }


    let statementParser =
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

    return Bind(statementParser.parse)
  }

  func typeFor(_ name: String) -> `Type` {
    name.last! == "$" ? .string : .number
  }

  func checkDefStatement(_ argument: ((Token, Token), Expression), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Statement> {
    let ((nameToken, parameterToken), expr) = argument

    let name = nameToken.string!

    if name.count != 1 {
      return .failure(indexOf(nameToken),  "DEF function name cannot be followed by extra letters")
    }

    let result = Statement.def(
      "FN"+name,
      parameterToken.string,
      expr,
      .function([.number], .number))
    return .success(result, remaining)
  }

  func requireFloatType(_ expr: Expression, _ remaining: ArraySlice<Token>) -> ParseResult<Token, Expression> {
    if expr.type() == .number { return .success(expr, remaining) }

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
    let type : `Type` = name.last! == "$" ? .string : .number

    if exprs == nil {
      return .variable(name, type)
    }

    return .arrayAccess(name, type, exprs!)
  }


  /// Make statement methods

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

  func makeIfGoto(_ argument: (Expression, Token), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Statement> {
    let (expr, token) = argument
    return .success(.ifGoto(expr, LineNumber(token.float!)), remaining)
  }

  func makeIfStatements(_ argument: (Expression, [Statement]), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Statement> {
    let (expr, statements) = argument
    return .success(.`if`(expr, statements), remaining)
  }

  func makeInputStatement(_ argument: (Token?, [Expression])) -> Statement {
    let (tokenOptional, exprs) = argument

    let prompt = tokenOptional == nil ? "" : tokenOptional!.string!

    return .input(prompt, exprs)
  }

  func makeLine(_ argument: (Token, [Statement]), _ remaining: ArraySlice<Token>) -> ParseResult<Token, Parse> {
    let (token, statements) = argument

    let lineNumber = LineNumber(token.float)
    if lineNumber <= 0 || lineNumber > maxLineNumber {
      return .failure(indexOf(token)+1, "Line number must be between 1 and \(maxLineNumber)")
    }

    return .success(Parse(LineNumber(lineNumber), statements), remaining)
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
