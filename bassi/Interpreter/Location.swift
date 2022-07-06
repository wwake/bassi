//
//  Location.swift
//  bassi
//
//  Created by Bill Wake on 7/6/22.
//

import Foundation

struct Location : Equatable {
  var lineNumber: LineNumber
  var part: Int

  init(_ lineNumber: LineNumber, _ part: Int = 0) {
    self.lineNumber = lineNumber
    self.part = part
  }

  func next() -> Location {
    return Location(self.lineNumber, self.part + 1)
  }
}
