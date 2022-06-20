//
//  ContentView.swift
//  bassi
//
//  Created by Bill Wake on 5/8/22.
//

import SwiftUI

struct ContentView: View {
  @ObservedObject var output = Output()
  @State var command: String = ""

  var repl = Repl()

  var body: some View {
    VStack {
      ScrollView {
        Text(output.output)
          .padding(.all)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      TextField("text", text: $command)
        .padding()
        .onSubmit({
          repl.execute(command, output)
          command = ""
        })
    }
    .frame(width: 600, height: 800)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
