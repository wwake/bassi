//
//  Parse.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

public enum ParseError: Error, Equatable {
  case error(Token, String)
}

public typealias LineNumber = Int
public typealias ColumnNumber = Int
public typealias Name = String

public struct Parse : Equatable {
  let lineNumber: LineNumber
  let statements: [Statement]

  init(_ lineNumber: LineNumber, _ statements: [Statement]) {
    self.lineNumber = lineNumber
    self.statements = statements
  }
}

public indirect enum Expression: Equatable {
  case missing
  case number(Float)
  case string(String)
  case variable(Name, `Type`)
  case predefined(Name, [Expression], `Type`)
  case userdefined(Name, Expression)
  case arrayAccess(Name, `Type`, [Expression])

  case op1(TokenType, Expression)
  case op2(TokenType, Expression, Expression)

  func type() -> `Type` {
    switch self {
    case .missing:
      return .missing
    case .number(_):
      return .number
    case .string(_):
      return .string
    case .variable(_, let type):
      return type
    case .predefined(_,_, let type):
      return type
    case .userdefined(_,_):
      return .number
    case .arrayAccess(_, let type, _):
      return type
    case .op1(_, _):
      return .number
    case .op2(_, _, _):
      return .number
    }
  }
}

public struct DimInfo : Equatable {
  var name: Name
  var dimensions: [Expression]
  var type: `Type`

  init(_ name: Name, _ dimensions: [Expression], _ type: `Type`) {
    self.name = name
    self.dimensions = dimensions
    self.type = type
  }
}

public enum Printable: Equatable {
  case thinSpace
  case tab
  case newline
  case expr(Expression)
}

public indirect enum Statement : Equatable {
  case error(LineNumber, ColumnNumber, String)

  case assign(Expression, Expression)
  case data([String])
  case def(Name, Name, Expression, `Type`)
  case dim([DimInfo])
  case end
  case `for`(Name, Expression, Expression, Expression)
  case gosub(LineNumber)
  case goto(LineNumber)
  case `if`(Expression, [Statement])
  case ifGoto(Expression, LineNumber)
  case input(String, [Expression])
  case next(Name)
  case onGosub(Expression, [LineNumber])
  case onGoto(Expression, [LineNumber])
  case print([Printable])
  case read([Expression])
  case restore
  case `return`
  case skip
  case stop

  static func count(_ statements: [Statement]) -> Int {
    if case .if(_, let inner) = statements.last! {
      return statements.count + Statement.count(inner)
    }
    return statements.count
  }

  static func at(_ list: [Statement], _ index: Int) -> Statement {
    if index < list.count {
      return list[index]
    }
    if case .if(_, let inner) = list.last! {
      return at(inner, index - list.count)
    }
    return .error(0, 0, "Statement.at: index too big - internal error")
  }
}

