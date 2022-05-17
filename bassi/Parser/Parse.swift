//
//  Parse.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

indirect enum Parse : Equatable {
  case program([Parse])
  case line(Int, Parse)
  case skip
  case print([Expression])
}

indirect enum Expression: Equatable {
  case number(Float)
  case op2(Token, Expression, Expression)
}
