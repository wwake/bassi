//
//  File.swift
//  bassi
//
//  Created by Bill Wake on 5/9/22.
//

import Foundation

enum Token  {
  case atEnd
  case unknown
  case error(String)
  case integer(Float)
  case number(Float)
  
  case plus
  case minus
  case times
  case divide
  case exponent
  case equals
  case leftParend
  case rightParend

  case lessThan
  case lessThanOrEqualTo
  case notEqual

  case greaterThan
  case greaterThanOrEqualTo

  case clear
  case data
  case def
  case dim
  case end

  case and
  case forKeyword
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
  case stop
  case then
}

extension Token : Equatable {
}

extension Token : Hashable {
}
