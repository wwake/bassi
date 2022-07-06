//
//  Type+defaultValue.swift
//  bassi
//
//  Created by Bill Wake on 7/6/22.
//

import Foundation

extension `Type` {
  func defaultValue() -> Value {
    switch self {
    case .missing:
      return .undefined

    case .number:
      return Value.number(0.0)

    case .string:
      return Value.string("")

    case .function(_, _):
      return Value.string("?? Undefined function")

    case .opt(_):
      return Value.string("?? Opt type default")
    }
  }
}
