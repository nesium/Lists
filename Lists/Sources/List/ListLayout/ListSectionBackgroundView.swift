//
//  ListSectionBackgroundView.swift
//  NSMForms
//
//  Created by Marc Bauer on 19.09.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import UIKit

class ListSectionBackgroundView: UICollectionReusableView {
  override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)

    guard let attributes = layoutAttributes as? ListViewLayoutAttributes else {
      return
    }

    self.backgroundColor = attributes.backgroundColor
  }
}
