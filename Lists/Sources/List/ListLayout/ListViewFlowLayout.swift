//
//  ListViewFlowLayout.swift
//  NSMForms
//
//  Created by Marc Bauer on 19.09.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import UIKit

protocol UICollectionViewDelegateListViewFlowLayout: AnyObject {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    backgroundColorForSectionAt section: Int
  ) -> UIColor?
}

final class ListViewFlowLayout: UICollectionViewFlowLayout {
  private static let elementKindBackground = "ListViewBackground"

  private var backgroundAttributes: [IndexPath: ListViewLayoutAttributes]?

  private var backgroundColorInSection: ((UICollectionView, UICollectionViewLayout, Int) -> UIColor?)?
  private var collectionViewObservation: NSKeyValueObservation?

  internal weak var delegate: UICollectionViewDelegateListViewFlowLayout?

  // MARK: - Initialization -

  override init() {
    super.init()

    self.register(
      ListSectionBackgroundView.self,
      forDecorationViewOfKind: ListViewFlowLayout.elementKindBackground
    )
  }

  deinit {
    self.collectionViewObservation?.invalidate()
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - UICollectionViewFlowLayout Methods -

  override func prepare() {
    super.prepare()

    guard
      self.backgroundAttributes == nil,
      let numberOfSections = self.collectionView?.numberOfSections,
      numberOfSections > 0 else {
      return
    }

    var backgroundAttributes = [IndexPath: ListViewLayoutAttributes]()
    for idx in 0 ..< numberOfSections {
      if let attributes = self.layoutAttributesForSectionBackground(at: idx) {
        backgroundAttributes[attributes.indexPath] = attributes
      }
    }
    self.backgroundAttributes = backgroundAttributes
  }

  override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
    if let ctx = context as? UICollectionViewFlowLayoutInvalidationContext {
      if ctx.invalidateFlowLayoutAttributes || ctx.invalidateFlowLayoutDelegateMetrics {
        self.backgroundAttributes = nil
      }
    }

    if context.invalidateEverything || context.invalidateDataSourceCounts {
      self.backgroundAttributes = nil
    }

    super.invalidateLayout(with: context)
  }

  override func layoutAttributesForDecorationView(
    ofKind elementKind: String,
    at indexPath: IndexPath
  ) -> UICollectionViewLayoutAttributes? {
    return self.backgroundAttributes?[indexPath] ?? nil
  }

  override func layoutAttributesForElements(
    in rect: CGRect
  ) -> [UICollectionViewLayoutAttributes]? {
    guard var attributes = super.layoutAttributesForElements(in: rect) else {
      return nil
    }

    self.backgroundAttributes?.values.forEach { value in
      if rect.intersects(value.frame) {
        attributes.append(value)
      }
    }

    return attributes
  }

  // MARK: - Private Methods -

  private func layoutAttributesForSectionBackground(at index: Int) -> ListViewLayoutAttributes? {
    guard
      let collectionView = self.collectionView,
      let delegate = self.delegate,
      collectionView.numberOfSections > 0,
      let numberOfItemsInSection = self.collectionView?.numberOfItems(inSection: index),
      numberOfItemsInSection > 0
    else {
      return nil
    }

    guard let backgroundColor = delegate.collectionView(
      collectionView, layout: self, backgroundColorForSectionAt: index
    ) else {
      return nil
    }

    let firstItemInSection = self.layoutAttributesForItem(
      at: IndexPath(item: 0, section: index)
    )
    let lastItemInSection = self.layoutAttributesForItem(
      at: IndexPath(item: numberOfItemsInSection - 1, section: index)
    )

    guard
      let firstItemFrame = firstItemInSection?.frame,
      let lastItemFrame = lastItemInSection?.frame,
      !firstItemFrame.isEmpty,
      !lastItemFrame.isEmpty
    else {
      return nil
    }

    var firstFrame = firstItemFrame

    if
      let headerItem = self.layoutAttributesForSupplementaryView(
        ofKind: UICollectionView.elementKindSectionHeader,
        at: IndexPath(item: 0, section: index)
      ),
      !headerItem.frame.isEmpty {
      firstFrame = headerItem.frame
    }

    var sectionFrame = firstFrame.union(lastItemFrame)

    switch self.scrollDirection {
      case .horizontal:
        sectionFrame.size.height = collectionView.bounds.height
      case .vertical:
        sectionFrame.size.width = collectionView.bounds.width
      @unknown default:
        sectionFrame.size.width = collectionView.bounds.width
    }

    let attributes = ListViewLayoutAttributes(
      forDecorationViewOfKind: ListViewFlowLayout.elementKindBackground,
      with: IndexPath(item: 0, section: index)
    )
    attributes.frame = sectionFrame
    attributes.backgroundColor = backgroundColor
    attributes.zIndex = -100
    return attributes
  }
}
