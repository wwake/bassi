//
//  Parse.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

public enum ParseError: Error, Equatable {
  case error(String)
}

public typealias LineNumber = Int
public typealias Name = String

public struct Parse : Equatable {
  let lineNumber: LineNumber
  let statement: Statement

  init(_ lineNumber: LineNumber, _ statement: Statement) {
    self.lineNumber = lineNumber
    self.statement = statement
  }
}

public indirect enum Statement : Equatable {
  case error(ParseError)

  case assign(Expression, Expression)
  case def(Name, Name, Expression, `Type`)
  case dim(Name, [Int], `Type`)
  case end
  case `for`(Name, Expression, Expression, Expression)
  case gosub(LineNumber)
  case goto(LineNumber)
  case `if`(Expression, [Statement])
  case ifGoto(Expression, LineNumber)
  case next(Name)
  case onGoto(Expression, [LineNumber])
  case print([Expression])
  case `return`
  case skip
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
