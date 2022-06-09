//
//  Parse.swift
//  bassi
//
//  Created by Bill Wake on 5/10/22.
//

import Foundation

public enum ParseError: Error, Equatable {
  case error(String)
  case internalError(String)
  case unknownStatement
  case notYetImplemented

  case noLineNumber
  case lineNumberRange

  case missingLeftParend
  case missingRightParend
  case expectedStartOfExpression
  case extraCharactersAtEol
  case missingTarget
  case missingTHEN
  case assignmentMissingEqualSign
  case letMissingAssignment
  case typeMismatch
  case argumentCountMismatch

  case floatRequired

  case DEFfunctionMustStartWithFn
  case DEFrequiresVariableAfterFn
  case DEFfunctionNameMustBeFnFollowedBySingleLetter
  case FNrequiresParameterVariable
  case DEFrequiresRightParendAfterParameter
  case DEFrequiresEqualAfterParameter
  case variableRequired
  case integerRequired
}

public indirect enum Parse : Equatable {
  case error(ParseError)
  case end
  case line(Int, Parse)
  case skip
  case print([Expression])
  case goto(Int)
  case `if`(Expression, Int)
  case assign(Expression, Expression)
  case def(String, String, Expression, `Type`)
  case dim(String, [Int], `Type`)
}

public indirect enum Expression: Equatable {
  case missing
  case number(Float)
  case string(String)
  case variable(String, `Type`)
  case predefined(String, [Expression], `Type`)
  case userdefined(String, Expression)
  case arrayAccess(String, `Type`, [Expression])
  
  case op1(Token, Expression)
  case op2(Token, Expression, Expression)

  func type() -> `Type` {
    switch self {
    case .missing:
      return .missing
    case .number(_):
      return .number
    case .string(_):
      return .string
    case .variable(_, let type):
      return type
    case .predefined(_,_, let type):
      return type
    case .userdefined(_,_):
      return .number
    case .arrayAccess(_, let type, _):
      return type
    case .op1(_, _):
      return .number
    case .op2(_, _, _):
      return .number
    }
  }
}
