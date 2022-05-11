//
//  File.swift
//  bassi
//
//  Created by Bill Wake on 5/9/22.
//

import Foundation

enum Token  {
  case atEnd
  case error(String)
  case integer(Int)

  case plus
  case minus
  case times
  case divide
  case exponent
  case equals
  case leftParend
  case rightParend

  case remark
  case print
}

extension Token : Equatable {
}
