//
//  ContentView.swift
//  bassi
//
//  Created by Bill Wake on 5/8/22.
//

import SwiftUI

struct ContentView: View {
  @ObservedObject var repl = Repl()
  @State var command: String = ""

  var body: some View {
    VStack {
      ScrollView {
        Text(repl.output)
          .padding(.all)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      TextField("text", text: $command)
        .padding()
        .onSubmit({
          repl.output.append(command)
          repl.output.append("\n")
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
