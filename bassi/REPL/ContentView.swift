//
//  ContentView.swift
//  bassi
//
//  Created by Bill Wake on 5/8/22.
//

import SwiftUI

struct ContentView: View {
  @Namespace var bottom
  @State private var selectedTab = 0

  @ObservedObject var program = Program()
  @ObservedObject var output = Output()

  @State var command: String = ""


  fileprivate func codeView() -> some View {
    return VStack {
      ScrollViewReader { proxy in
        ScrollView {
          ForEach(program.program.sorted(by: <), id: \.key) { key, value in
            Text(value)
          }
          .font(.system(size:18, design:.monospaced))
          .frame(maxWidth: .infinity, alignment: .leading)

          Text("")
            .id(bottom)
        }
        .onChange(of: output) { _ in
          print("output changed")
          proxy.scrollTo(bottom)
        }
      }

      TextField("Enter line, re-type it, or just type line number to delete it", text: $command)
        .padding()
        .onSubmit({
          Repl(program, output).execute(command)
          command = ""
        })

      HStack {
        Spacer()
        Button("RUN") {
          selectedTab = 1
          Repl(program, output).doRun()
        }
        Spacer()
      }

      Spacer()
    }
  }

  fileprivate func runView() -> some View {
    return ScrollViewReader { proxy in
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
  }

  fileprivate func variableView() -> some View {
    Text("All the variables")
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      codeView()
        .tabItem {
          Image(systemName:"curlybraces.square")
          Text("Code")
        }
        .tag(0)
      runView()
        .tabItem {
          Image(systemName:"note.text")
          Text("Output")
        }
        .tag(1)
      variableView()
        .tabItem {
          Image(systemName:"eye")
          Text("Variables")
        }
        .tag(2)
    }
    .frame(width: 600, height: 800)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
