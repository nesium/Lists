//
//  UICollectionView+Lists.swift
//  Lists
//
//  Created by Marc Bauer on 26.09.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import UIKit

extension UICollectionView {
  // fixes a crash on iOS 11
  func lst_safeLayoutAttributesForItem(
    at indexPath: IndexPath
  ) -> UICollectionViewLayoutAttributes? {
    guard indexPath.section < self.numberOfSections else {
      return nil
    }
    guard indexPath.item < self.numberOfItems(inSection: indexPath.section) else {
      return nil
    }
    return self.layoutAttributesForItem(at: indexPath)
  }
}
