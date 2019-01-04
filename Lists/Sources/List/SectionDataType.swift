//
//  SectionDataType.swift
//  NSMForms
//
//  Created by Marc Bauer on 20.11.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import IGListKit

internal protocol SectionDataType {
  var numberOfItems: Int { get }
  var style: SectionStyle { get }

  var header: SectionHeaderFooterDataType? { get }
  var footer: SectionHeaderFooterDataType? { get }

  func diffableItems() -> [ListDiffable]

  func cellForItem(
    at index: Int,
    context: ListCollectionContext,
    sectionController: ListSectionController
  ) -> UICollectionViewCell

  func updateCell(
    at index: Int,
    withDataFrom dataIndex: Int,
    context: ListCollectionContext,
    sectionController: ListSectionController
  )

  func updateSeparators(
    in context: ListCollectionContext,
    sectionController: ListSectionController
  )

  func sizeForItem(at index: Int, availableWidth: CGFloat) -> CGSize
}


internal protocol SectionHeaderFooterDataType {
  var height: CGFloat { get }

  func view(
    ofKind elementKind: String,
    at index: Int,
    context: ListCollectionContext,
    sectionController: ListSectionController
  ) -> UICollectionReusableView
}


public struct SectionStyle {
  public var inset: UIEdgeInsets
  public var minimumInteritemSpacing: CGFloat
  public var minimumLineSpacing: CGFloat
  public var backgroundColor: UIColor?

  public init(
    inset: UIEdgeInsets = .zero,
    minimumInteritemSpacing: CGFloat = 0,
    minimumLineSpacing: CGFloat = 0,
    backgroundColor: UIColor? = nil
  ) {
    self.inset = inset
    self.minimumInteritemSpacing = minimumInteritemSpacing
    self.minimumLineSpacing = minimumLineSpacing
    self.backgroundColor = backgroundColor
  }
}

extension SectionStyle {
  public static var `default` = SectionStyle()
}
