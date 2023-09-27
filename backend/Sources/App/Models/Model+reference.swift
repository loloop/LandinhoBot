//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 24/09/23.
//

import Foundation
import Fluent
import Vapor

extension Model {
  static var reference: DatabaseSchema.FieldConstraint {
    .references(Self.schema, "id")
  }
}
