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
  case assign(String, Expression)
}

indirect enum Expression: Equatable {
  case number(Float)
  case variable(String, `Type`)
  case op1(Token, Expression)
  case op2(Token, Expression, Expression)

  func type() -> `Type` {
    switch self {
    case .number(_):
      return .float
    case .variable(_, let theType):
      return theType
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
//  case array(Int, `Type`)
//  case function([`Type`], `Type`)
}
