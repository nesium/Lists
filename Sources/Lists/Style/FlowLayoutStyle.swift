//
//  FlowLayoutStyle.swift
//  NSMForms
//
//  Created by Marc Bauer on 31.07.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import UIKit

public struct FlowLayoutStyle {
  public typealias ItemSizeHandler = (
    _ index: Int,
    _ numberOfItems: Int,
    _ proposedSize: CGSize,
    _ availableWidth: CGFloat
  ) -> CGSize

  public typealias SeparatorVisibilityHandler = (
    _ index: Int,
    _ numberOfItems: Int
  ) -> Bool

  public var itemSizeHandler: ItemSizeHandler?
  public var scrollDirection: UICollectionView.ScrollDirection
  public var minimumLineSpacing: CGFloat
  public var minimumInteritemSpacing: CGFloat
  public var sectionInset: UIEdgeInsets
  public var separatorVisibilityHandler: SeparatorVisibilityHandler?
  public var backgroundColor: UIColor?

  public init(
    itemSize: CGSize? = nil,
    scrollDirection: UICollectionView.ScrollDirection = .vertical,
    minimumLineSpacing: CGFloat = 0,
    minimumInteritemSpacing: CGFloat = 0,
    sectionInset: UIEdgeInsets = .zero,
    separatorVisibilityHandler: SeparatorVisibilityHandler? = nil,
    backgroundColor: UIColor? = nil
  ) {
    self.itemSizeHandler = itemSize.map { size in { _, _, _, _ in size } }
    self.scrollDirection = scrollDirection
    self.minimumLineSpacing = minimumLineSpacing
    self.minimumInteritemSpacing = minimumInteritemSpacing
    self.sectionInset = sectionInset
    self.separatorVisibilityHandler = separatorVisibilityHandler
    self.backgroundColor = backgroundColor
  }

  public init(
    itemSizeHandler: @escaping ItemSizeHandler,
    scrollDirection: UICollectionView.ScrollDirection = .vertical,
    minimumLineSpacing: CGFloat = 0,
    minimumInteritemSpacing: CGFloat = 0,
    sectionInset: UIEdgeInsets = .zero,
    separatorVisibilityHandler: SeparatorVisibilityHandler? = nil,
    backgroundColor: UIColor? = nil
  ) {
    self.itemSizeHandler = itemSizeHandler
    self.scrollDirection = scrollDirection
    self.minimumLineSpacing = minimumLineSpacing
    self.minimumInteritemSpacing = minimumInteritemSpacing
    self.sectionInset = sectionInset
    self.separatorVisibilityHandler = separatorVisibilityHandler
    self.backgroundColor = backgroundColor
  }
}
