//
//  Interactor.swift
//  bassi
//
//  Created by Bill Wake on 6/24/22.
//

import Foundation

class Interactor: ObservableObject {
  @Published var output: String = ""
  @Published var input: String = ""
  
  func append(_ line: String) {
    output.append(line)
  }

  func column() -> Int {
    let lastIndex = output.lastIndex(of:"\n")
    if lastIndex == nil {
      return output.count
    }
    return output[lastIndex!...].count - 1
  }

  func input(_ input: String) {
    self.input = input
  }
  
  func getLine() -> String {
    let result = input
    input = ""
    return result
  }
}

extension Interactor: Equatable {
  static func == (lhs: Interactor, rhs: Interactor) -> Bool {
    lhs.output == rhs.output
  }
}
