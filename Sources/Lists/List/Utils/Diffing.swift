//
//  Diffing.swift
//  Lists
//
//  Created by Marc Bauer on 13.12.18.
//  Copyright © 2018 Marc Bauer. All rights reserved.
//

import Foundation
import IGListKit

public struct Diffing<A> {
  internal let identifier: (A) -> (String)
  internal let equals: (A, A) -> Bool

  public init(identifier: @escaping (A) -> (String), equals: @escaping (A, A) -> (Bool)) {
    self.identifier = identifier
    self.equals = equals
  }
}

extension Diffing where A: Equatable {
  public static func identifier(_ block: @escaping (A) -> (String)) -> Diffing {
    return Diffing(identifier: block, equals: ==)
  }
}

extension Diffing {
  public static func sectionData<T>() -> Diffing<SectionData<T>> {
    return Diffing<SectionData<T>>(
      identifier: { (sectionData: SectionData<T>) in sectionData.uniqueSectionIdentifier },
      equals: ==
    )
  }
}
