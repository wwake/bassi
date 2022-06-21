//
//  Repl+Test.swift
//  bassiTests
//
//  Created by Bill Wake on 6/21/22.
//

import Foundation
@testable import bassi

extension Repl {
  func contains(_ lineNumber: Int) -> Bool {
    program[lineNumber] != nil
  }

  subscript(_ lineNumber: Int) -> String? {
    get { program[lineNumber] }
  }
}
