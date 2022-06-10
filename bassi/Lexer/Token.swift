//
//  File.swift
//  bassi
//
//  Created by Bill Wake on 5/9/22.
//

import Foundation

struct Token {
  var type: TokenType
  var line: Int
  var column: Int
}

public enum TokenType  {
  case unknown
  case atEnd
  case eol
  case error(String)

  case integer(Int)
  case number(Float)
  case variable(String)
  case string(String)
  
  case plus
  case minus
  case times
  case divide
  case exponent
  case equals
  case leftParend
  case rightParend
  case comma
  
  case lessThan
  case lessThanOrEqualTo
  case notEqual

  case greaterThan
  case greaterThanOrEqualTo

  case and
  case clear
  case data
  case def
  case dim

  case end
  case fn
  case `for`
  case goto
  case gosub

  case ifKeyword
  case input
  case letKeyword
  case next
  case not
  case on
  case or

  case poke
  case print
  case read
  case remark

  case restore
  case returnKeyword
  case step
  case stop
  case then
  case to

  case predefined(String, `Type`)
}

extension TokenType : Equatable {
}

extension TokenType : Hashable {
}
