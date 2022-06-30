//
//  BasicArray.swift
//  bassi
//
//  Created by Bill Wake on 6/29/22.
//

import Foundation

public class BasicArray {
  var dimensions: [Int]
  var contents: [Value]
  var type:`Type`

  convenience init(_ dimensions: [Int], _ type: `Type`) {
    let count = dimensions.reduce(1, *)
    self.init(dimensions, Array<Value>(
      repeating: type.defaultValue(),
      count: count), type)
  }

  init(_ dimensions: [Int], _ contents: [Value], _ type:`Type`) {
    self.dimensions = dimensions
    self.contents = contents
    self.type = type
  }

  fileprivate func indexFor(_ valueIndexes: [Value], _ location: Location) throws -> Int {
    let indexes = valueIndexes
      .map { Int($0.asFloat())}

    try indexes
      .enumerated()
      .forEach { (i, index) in
        if index < 0 || index >= dimensions[i] {
          throw InterpreterError.error(location.lineNumber, "array access out of bounds")
        }
      }

    return zip(indexes, dimensions)
      .dropFirst()
      .reduce(indexes[0], { (total, indexDim) in
        let (index, dim) = indexDim
        return total * dim + index
      })
  }

  func indexesFor(_ index: Int) -> [Int] {
    var resultReversed: [Int] = []
    var divisor = 1

    dimensions
      .reversed()
      .forEach {
        resultReversed.append((index / divisor) % $0)
        divisor = divisor * $0
      }

    return resultReversed.reversed()
  }

  func debugName(_ variable: String, _ index: Int) -> String {
    let indexes = indexesFor(index)
      .map {String($0)}
      .joined(separator: ",")
    
    return "\(variable)(\(indexes))"
  }
  
  func get(_ indexes: [Value], _ location: Location) throws -> Value {
    let index = try indexFor(indexes, location)
    return get(index)
  }

  func get(_ index: Int) -> Value {
    return contents[index]
  }

  func put(_ indexes: [Value], _ rhs: Value, _ location: Location) throws {
    let index = try indexFor(indexes, location)
    contents[index] = rhs
  }
}

extension BasicArray: Equatable {
  public static func == (lhs: BasicArray, rhs: BasicArray) -> Bool {
    lhs.dimensions == rhs.dimensions
    && lhs.contents == rhs.contents
    && lhs.type == rhs.type
  }
}
