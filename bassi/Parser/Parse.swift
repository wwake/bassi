//
//  Parse.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

indirect enum Parse : Equatable {
  case line(Int, Parse)
  case skip
  case print([Expression])
  case goto(Int)
}

indirect enum Expression: Equatable {
  case number(Float)
  case op1(Token, Expression)
  case op2(Token, Expression, Expression)
}
