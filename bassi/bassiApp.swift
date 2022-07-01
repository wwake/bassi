//
//  bassiApp.swift
//  bassi
//
//  Created by Bill Wake on 5/8/22.
//

import SwiftUI

@main
struct bassiApp: App {
  static var program = Program()
  static var output = Interactor()

  var body: some Scene {
    WindowGroup {
      ContentView(program: bassiApp.program, interactor: bassiApp.output, repl: Repl(bassiApp.program, bassiApp.output))
    }
  }
}
