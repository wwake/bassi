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

public typealias Parse = Statement

//public struct Parse {
//  let lineNumber: LineNumber
//  let statement: Statement
//}

public indirect enum Statement : Equatable {
  case error(ParseError)
  case end
  case line(LineNumber, Statement)
  case skip
  case print([Expression])
  case goto(LineNumber)
  case `if`(Expression, LineNumber)
  case assign(Expression, Expression)
  case def(String, String, Expression, `Type`)
  case dim(String, [Int], `Type`)
  case `for`(String, Expression, Expression, Expression)
  case next(String)
}

public indirect enum Expression: Equatable {
  case missing
  case number(Float)
  case string(String)
  case variable(String, `Type`)
  case predefined(String, [Expression], `Type`)
  case userdefined(String, Expression)
  case arrayAccess(String, `Type`, [Expression])
  
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
