//
//  Output.swift
//  bassi
//
//  Created by Bill Wake on 6/24/22.
//

import Foundation

class Output: ObservableObject {
  @Published var output: String = ""

  func append(_ line: String) {
    output.append(line)
  }
}

extension Output: Equatable {
  static func == (lhs: Output, rhs: Output) -> Bool {
    lhs.output == rhs.output
  }
}
