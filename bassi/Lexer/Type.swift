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

extension `Type` {
  static let typeNtoN = `Type`.function([.float], .float)
  static let typeNtoS = `Type`.function([.float], .string)
  static let typeStoN = `Type`.function([.string], .float)
  static let typeSNtoS = `Type`.function([.string, .float], .string)
  static let typeSNNtoS = `Type`.function([.string, .float, .float], .string)
}
