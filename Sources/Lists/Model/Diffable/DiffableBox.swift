//
//  DiffableBox.swift
//  NSMForms
//
//  Created by Marc Bauer on 04.08.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Foundation
import IGListKit

// Source: https://github.com/Instagram/IGListKit/issues/35#issuecomment-277503724

internal final class DiffableBox<T>: ListDiffable {
  let value: T
  let diffing: Diffing<T>

  init(value: T, diffing: Diffing<T>) {
    self.value = value
    self.diffing = diffing
  }

  // MARK: - ListDiffable Methods -

  func diffIdentifier() -> NSObjectProtocol {
    return self.diffing.identifier(self.value) as NSString
  }

  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let other = object as? DiffableBox<T> else {
      return false
    }
    return self.diffing.equals(self.value, other.value)
  }
}
