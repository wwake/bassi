//
//  Type.swift
//  bassi
//
//  Created by Bill Wake on 5/30/22.
//

import Foundation

public indirect enum `Type` : Equatable {
  case number
  case string
  case function([`Type`], `Type`)
  //  case array(Int, `Type`)
}

extension `Type`: Hashable {}

extension `Type` {
  static let typeNtoN = `Type`.function([.number], .number)
  static let typeNtoS = `Type`.function([.number], .string)
  static let typeStoN = `Type`.function([.string], .number)
  static let typeSNtoS = `Type`.function([.string, .number], .string)
  static let typeSNNtoS = `Type`.function([.string, .number, .number], .string)
}
