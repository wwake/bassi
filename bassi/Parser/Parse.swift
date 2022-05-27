//
//  Parse.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

indirect enum Parse : Equatable {
  case end
  case line(Int, Parse)
  case skip
  case print([Expression])
  case goto(Int)
  case `if`(Expression, Int)
  case assign(Expression, Expression)
  case def(String, String, Expression)
}

indirect enum Expression: Equatable {
  case number(Float)
  case string(String)
  case variable(String, `Type`)
  case predefined(String, Expression)

  case op1(Token, Expression)
  case op2(Token, Expression, Expression)

  func type() -> `Type` {
    switch self {
    case .number(_):
      return .float
    case .string(_):
      return .string
    case .variable(_, let theType):
      return theType
    case .predefined(_,_):
      return .float
    case .op1(_, _):
      return .float
    case .op2(_, _, _):
      return .float
    }
  }
}

indirect enum `Type` : Equatable {
  case float
  case string
  case function([`Type`], `Type`)
  //  case array(Int, `Type`)
}
