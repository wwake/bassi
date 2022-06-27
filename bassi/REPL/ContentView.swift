//
//  ContentView.swift
//  bassi
//
//  Created by Bill Wake on 5/8/22.
//

import SwiftUI

struct ContentView: View {
  @Namespace var bottom
  
  @ObservedObject var program = Program()
  @ObservedObject var output = Output()

  @State var command: String = ""


  fileprivate func codeView() -> some View {
    return VStack {
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

      TextField("Enter line, re-type it, or just type line number to delete it", text: $command)
        .padding()
        .onSubmit({
          Repl(program, output).execute(command)
          command = ""
        })

      HStack {
        Spacer()
        Button("RUN") {
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
    TabView {
      codeView()
        .tabItem {
          Image(systemName:"curlybraces.square")
          Text("Code")
        }
      runView()
        .tabItem {
          Image(systemName:"note.text")
          Text("Output")
        }
      variableView()
        .tabItem {
          Image(systemName:"eye")
          Text("Variables")
        }
    }
    .frame(width: 600, height: 800)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
