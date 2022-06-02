//
//  Parse.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

public indirect enum Parse : Equatable {
  case end
  case line(Int, Parse)
  case skip
  case print([Expression])
  case goto(Int)
  case `if`(Expression, Int)
  case assign(Expression, Expression)
  case def(String, String, Expression, Type)
}

public indirect enum Expression: Equatable {
  case number(Float)
  case string(String)
  case variable(String, `Type`)
  case predefined(String, [Expression], `Type`)
  case userdefined(String, Expression)
  
  case op1(Token, Expression)
  case op2(Token, Expression, Expression)

  func type() -> `Type` {
    switch self {
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
    case .op1(_, _):
      return .number
    case .op2(_, _, _):
      return .number
    }
  }
}
