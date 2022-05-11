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
  case print([Parse])
}
