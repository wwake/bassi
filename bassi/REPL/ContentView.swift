//
//  ContentView.swift
//  bassi
//
//  Created by Bill Wake on 5/8/22.
//

import SwiftUI

struct ContentView: View {
  @State var command: String = ""

  var body: some View {
    VStack {
      ScrollView {
        Text("Hello, world!")
          .padding(.all)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      TextField("text", text: $command)
        .padding()
        .onSubmit({print(command)})
    }
    .frame(width: 600, height: 800)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
