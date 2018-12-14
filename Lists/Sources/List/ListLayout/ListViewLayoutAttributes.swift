//
//  ListViewLayoutAttributes.swift
//  NSMForms
//
//  Created by Marc Bauer on 19.09.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import UIKit

class ListViewLayoutAttributes: UICollectionViewLayoutAttributes {
  var backgroundColor: UIColor?

  override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone) as! ListViewLayoutAttributes
    copy.backgroundColor = self.backgroundColor
    return copy
  }

  override func isEqual(_ object: Any?) -> Bool {
    guard let object = object as? ListViewLayoutAttributes else {
      return false
    }
    return super.isEqual(object) && object.backgroundColor == self.backgroundColor
  }

  override var hash: Int {
    return super.hash ^ (self.backgroundColor?.hash ?? 0)
  }
}
