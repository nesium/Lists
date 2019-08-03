//
//  ListCell.swift
//  NSMForms
//
//  Created by Marc Bauer on 21.11.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import UIKit

open class ListCell: UIView {
  public final var isHighlighted: Bool = false
  public final var isSelected: Bool = false {
    didSet {
      if self.isSelected {
        self.accessibilityTraits.insert(.selected)
      } else {
        self.accessibilityTraits.remove(.selected)
      }
    }
  }

  public final var lastTouchLocation: CGPoint?

  // MARK: - Initialization -

  public required override init(frame: CGRect) {
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Public Methods -

  open func setHighlighted(_ highlighted: Bool, animated: Bool) {
    self.isHighlighted = highlighted
  }

  open func setSelected(_ selected: Bool, animated: Bool) {
    self.isSelected = selected
  }

  open func prepareForReuse() {}

  open var contentBounds: CGRect {
    return self.bounds.inset(by: UIEdgeInsets(
      top: 0,
      left: self.layoutMargins.left,
      bottom: 0,
      right: self.layoutMargins.right
    ))
  }

  open func preferredLayoutAttributesFitting(
    _ layoutAttributes: UICollectionViewLayoutAttributes
  ) -> UICollectionViewLayoutAttributes {
    return layoutAttributes
  }
}
