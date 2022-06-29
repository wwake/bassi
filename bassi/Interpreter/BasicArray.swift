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

  func indexFor(_ values: [Value], _ location: Location) throws -> Int {
    let indexes = values
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

  func get(_ values: [Value], _ location: Location) throws -> Value {
    let index = try indexFor(values, location)
    return contents[index]
  }

}

extension BasicArray: Equatable {
  public static func == (lhs: BasicArray, rhs: BasicArray) -> Bool {
    lhs.dimensions == rhs.dimensions
    && lhs.contents == rhs.contents
    && lhs.type == rhs.type
  }
}
