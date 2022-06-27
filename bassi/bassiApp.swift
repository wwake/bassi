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
  static var output = Output()

  var body: some Scene {
    WindowGroup {
      ContentView(program: bassiApp.program, output: bassiApp.output, repl: Repl(bassiApp.program, bassiApp.output))
    }
  }
}
