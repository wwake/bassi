//
//  Parse.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

indirect enum Parse : Equatable {
  case program([Parse])
  case line(Token, Parse)
  case skip
  case print([Expression])
  case number(Token)
}

indirect enum Expression: Equatable {
  case number(Token)
  case op2(Token, Expression, Expression)
}
