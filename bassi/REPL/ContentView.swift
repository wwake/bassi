//
//  ContentView.swift
//  bassi
//
//  Created by Bill Wake on 5/8/22.
//

import SwiftUI

struct ContentView: View {
  enum Tab : Int, Hashable {
    case code=1, variable, output
  }

  @Namespace var bottom

  @State private var selectedTab = Tab.code
  
  @ObservedObject var program: Program
  @ObservedObject var output: Output
  @ObservedObject var repl: Repl
  
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
          repl.execute(command)
          command = ""
        })

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

  var columns = [
    GridItem(.fixed(40.0), alignment: .leading),
    GridItem(.fixed(15.0), alignment: .center),
    GridItem(.flexible(), alignment: .leading),
  ]

  @State private var showArrayContents = false

  fileprivate func variableView() -> some View {
    return VStack {
      ScrollViewReader { proxy in
        ScrollView {
          LazyVGrid(columns: columns, alignment: .center) {
            ForEach(
              repl
                .store
                .filter { !$1.isFunction() }
                .sorted(by: {$0.key < $1.key}),
              id: \.key) { key, value in
                Text(key)
                Text(":")
                HStack {
                  Text(value.format())
                  Image(systemName: "eye")
                    .opacity(value.isArray() ? 1 : 0)
                    .onTapGesture {
                      print("Tapped \(key)")
                      showArrayContents = true
                    }
                    .sheet(isPresented: $showArrayContents, content: {
                      arrayContents(key, value.asArray())
                    })
                }
              }
              .font(.system(size:18, design:.monospaced))
              .frame(maxWidth: .infinity, alignment: .leading)
          }

          Text("")
            .id(bottom)
        }
        .onChange(of: output) { _ in
          print("output changed")
          proxy.scrollTo(bottom)
        }
      }
    }
  }

  fileprivate func arrayContents(_ key: Name, _ array: BasicArray) -> some View {
    //   Contents of A
    // A$(0,0) = "hello"
    // A$(0,1) = "world"
    // A$(1,0) = "monday"
    // A$(1,1) = "tuesday"

    VStack {
      Text("Contents of \(key)")
        .font(.system(size:16, design:.default))
        .bold()

      ScrollView {
        LazyVGrid(columns: [GridItem(.flexible())]) {
          ForEach(0..<array.contents.count) {
            Text("\(array.debugName(key, $0))=\(array.get($0).format())")
          }
        }
      }
    }
    .frame(width: 400, height: 600)
  }

  fileprivate func buttonView() -> some View {
    HStack {
      Spacer()
      Button("Run") {
        selectedTab = Tab.output
        repl.doRun()
      }
      Button("Continue") {
        selectedTab = Tab.output
        repl.doContinue()
      }
      .disabled(!repl.stopped)
      Spacer()
    }
  }
  
  var body: some View {
    VStack {
      TabView(selection: $selectedTab) {
        codeView()
          .tabItem {
            Image(systemName:"curlybraces.square")
            Text("Code")
          }
          .tag(Tab.code)
        variableView()
          .tabItem {
            Image(systemName:"eye")
            Text("Variables")
          }
          .tag(Tab.variable)
        runView()
          .tabItem {
            Image(systemName:"note.text")
            Text("Output")
          }
          .tag(Tab.output)
      }
      buttonView()
      Spacer()
    }
    .frame(width: 600, height: 800)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var program = Program()
  static var output = Output()
  
  static var previews: some View {
    ContentView(program: program, output: output, repl: Repl(program, output))
  }
}
