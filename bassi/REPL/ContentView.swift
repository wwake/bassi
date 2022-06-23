//
//  ContentView.swift
//  bassi
//
//  Created by Bill Wake on 5/8/22.
//

import SwiftUI

struct ContentView: View {
  @Namespace var bottom
  
  @ObservedObject var output = Output()
  @State var command: String = ""

  var repl = Repl()

  var body: some View {
    VStack {
      ScrollViewReader { proxy in
        ScrollView {
          Text(output.output)
            .font(.system(size:18, design:.monospaced))
            .padding(.all)
            .frame(maxWidth: .infinity, alignment: .leading)
          Text("")
            .id(bottom)
        }
        .onChange(of: output) { _ in
          print("output changed")
          proxy.scrollTo(bottom)
        }
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
