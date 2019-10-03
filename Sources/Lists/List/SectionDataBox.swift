//
//  SectionDataBox.swift
//  NSMForms
//
//  Created by Marc Bauer on 21.11.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import IGListKit

internal protocol SectionDataBox {
  var sectionData: SectionDataType { get }
}

internal final class DiffableSectionDataBox<T: SectionDataType>:
  ListDiffable,
  SectionDataBox
{
  let value: T
  let diffWitness: Diffing<T>

  var sectionData: SectionDataType {
    return self.value
  }

  init(_ value: T, diffWitness: Diffing<T>) {
    self.value = value
    self.diffWitness = diffWitness
  }

  // MARK: - ListDiffable Methods -

  func diffIdentifier() -> NSObjectProtocol {
    return self.diffWitness.identifier(self.value) as NSString
  }

  func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
    guard let other = object as? DiffableSectionDataBox<T> else {
      return false
    }
    return self.diffWitness.equals(self.value, other.value)
  }
}
