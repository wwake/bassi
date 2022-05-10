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
  case line(Int)
  case remark
  case print
}

extension Token : Equatable {
}
