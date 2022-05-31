//
//  Type.swift
//  bassi
//
//  Created by Bill Wake on 5/30/22.
//

import Foundation

public indirect enum `Type` : Equatable {
  case float
  case string
  case function([`Type`], `Type`)
  //  case array(Int, `Type`)
}

extension `Type`: Hashable {}
