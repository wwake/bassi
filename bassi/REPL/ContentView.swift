//
//  ContentView.swift
//  bassi
//
//  Created by Bill Wake on 5/8/22.
//

import SwiftUI

struct ContentView: View {
  enum Tab : Int, Hashable {
    case code=1, variable, run
  }

  @Namespace var bottomCode
  @Namespace var bottomVariables
  @Namespace var bottomRun

  @State private var selectedTab = Tab.code
  
  @ObservedObject var program: Program
  @ObservedObject var interactor: Interactor
  @ObservedObject var repl: Repl
  
  @State var command: String = ""
  @State var input: String = ""

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
            .id(bottomCode)
        }
        .onChange(of: program.program) { _ in
          proxy.scrollTo(bottomCode)
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
    VStack {
      ScrollViewReader { proxy in
        ScrollView {
          Text(interactor.output)
            .font(.system(size:18, design:.monospaced))
            .padding(.all)
            .frame(maxWidth: .infinity, alignment: .leading)
          Text("")
            .id(bottomRun)
        }
        .onChange(of: interactor.output) { _ in
          proxy.scrollTo(bottomRun)
        }
      }

      TextField("Enter input", text: $input)
        .padding()
        .onSubmit({
          interactor.input(input)
          repl.resume()
          input = ""
        })
    }
  }

  var columns = [
    GridItem(.fixed(40.0), alignment: .leading),
    GridItem(.fixed(15.0), alignment: .center),
    GridItem(.flexible(), alignment: .leading),
  ]

  struct ArrayInfo : Identifiable {
    var id = UUID()
    var name : String
    var value: Value
  }

  @State private var arrayToShow : ArrayInfo?

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
                      arrayToShow = ArrayInfo(name: key, value: value)
                    }
                    .sheet(item: $arrayToShow) { arrayView in
                      arrayContents(arrayView.name, arrayView.value.asArray())
                    }
                }
              }
              .font(.system(size:18, design:.monospaced))
              .frame(maxWidth: .infinity, alignment: .leading)
          }

          Text("")
            .id(bottomVariables)
        }
        .onChange(of: repl.store) { _ in
          proxy.scrollTo(bottomVariables)
        }
      }
    }
  }

  fileprivate func arrayContents(_ name: Name, _ array: BasicArray) -> some View {
    VStack {
      HStack {
        Spacer()
        Text("Contents of \(name)")
        .font(.system(size:16, design:.default))
        .bold()
        Spacer()
        Text("X ")
          .onTapGesture {
            arrayToShow = nil
        }
      }
      
      ScrollView {
        LazyVGrid(columns: [GridItem(.flexible())]) {
          ForEach(array.debugContents(name), id:\.self) {
            Text($0)
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
        selectedTab = Tab.run
        repl.doRun()
      }
      Button("Continue") {
        selectedTab = Tab.run
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
            Text("Run")
          }
          .tag(Tab.run)
      }
      buttonView()
      Spacer()
    }
    .frame(width: 600, height: 800)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var program = Program()
  static var output = Interactor()
  
  static var previews: some View {
    ContentView(program: program, interactor: output, repl: Repl(program, output))
  }
}
