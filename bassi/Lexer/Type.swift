//
//  Type.swift
//  bassi
//
//  Created by Bill Wake on 5/30/22.
//

import Foundation

public indirect enum `Type` : Equatable {
  case missing
  case number
  case string
  case function([`Type`], `Type`)
  case opt(`Type`)

  public func conformsTo(_ parameterType: `Type`) -> Bool {
    let argumentType = self
    if parameterType == argumentType {
        return true
      }
      if case .opt(let innerType) = parameterType {
        if innerType == argumentType {
          return true
        }
        if argumentType == .missing {
          return true
        }
      }
      return false
    }


}

extension `Type`: Hashable {}

extension `Type` {
  static let typeNtoN = `Type`.function([.number], .number)
  static let typeNtoS = `Type`.function([.number], .string)
  static let typeStoN = `Type`.function([.string], .number)
  static let typeSNtoS = `Type`.function([.string, .number], .string)
  static let typeSNoptNtoS = `Type`.function([.string, .number, .opt(.number)], .string)
}
