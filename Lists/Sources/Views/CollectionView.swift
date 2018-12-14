//
//  CollectionView.swift
//  NSMForms
//
//  Created by Marc Bauer on 03.12.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import UIKit

class CollectionView: UICollectionView {
  let scrollDirection: UICollectionView.ScrollDirection

  weak var layoutDelegate: CollectionViewLayoutDelegate?

  init(
    frame: CGRect,
    collectionViewLayout layout: UICollectionViewLayout,
    scrollDirection: UICollectionView.ScrollDirection
  ) {
    self.scrollDirection = scrollDirection
    super.init(frame: frame, collectionViewLayout: layout)
    self.preservesSuperviewLayoutMargins = true
  }

  override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
    self.scrollDirection = (layout as? UICollectionViewFlowLayout)?.scrollDirection ?? .vertical
    super.init(frame: frame, collectionViewLayout: layout)
    self.preservesSuperviewLayoutMargins = true
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    return self.collectionViewLayout.collectionViewContentSize
  }

  override var contentSize: CGSize {
    didSet {
      let isDirty = self.scrollDirection == .vertical
        ? self.contentSize.height != oldValue.height
        : self.contentSize.width != oldValue.width

      if isDirty {
        self.layoutDelegate?.collectionViewContentSizeDidChange(self)
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    self.layoutDelegate?.collectionViewDidLayoutSubviews(self)
  }
}

protocol CollectionViewLayoutDelegate: AnyObject {
  func collectionViewContentSizeDidChange(_ collectionView: CollectionView)
  func collectionViewDidLayoutSubviews(_ collectionView: CollectionView)
}
