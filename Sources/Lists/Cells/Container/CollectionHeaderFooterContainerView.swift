//
//  CollectionHeaderFooterContainerView.swift
//  NSMForms
//
//  Created by Marc Bauer on 28.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import UIKit

internal class CollectionHeaderFooterContainerView<Value, Style>: UICollectionReusableView {
  internal var contentView: AbstractHeaderFooterView<Value, Style>! {
    didSet {
      oldValue?.removeFromSuperview()
      self.addSubview(self.contentView)
    }
  }

  // MARK: - Initialization -

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.backgroundColor = .white
    self.preservesSuperviewLayoutMargins = true
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Public Methods -

  func applyValue(_ value: Value, style: Style) {
    self.contentView.applyValue(value, style: style)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    self.contentView.frame = self.bounds
  }
}
