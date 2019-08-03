//
//  CollectionViewContainerCell.swift
//  NSMForms
//
//  Created by Marc Bauer on 30.08.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import UIKit
import SwipeCellKit

internal protocol SelectableCollectionViewCell {
  var nsm_isSelected: Bool { get }
  func setSelected(_ selected: Bool, animated: Bool)
}

#warning("FIXME: CollectionViewContainerCell must conform to FormButton")
internal class CollectionViewContainerCell:
  SwipeTableViewCell,
  SelectableCollectionViewCell
{
  private let separator: UIView

  private var separatorStyle: LineStyle? {
    didSet {
      if self.separatorStyle != oldValue {
        self.setNeedsLayout()
      }
    }
  }

  private var separatorInsets: UIEdgeInsets = .zero {
    didSet {
      if self.separatorInsets != oldValue {
        self.setNeedsLayout()
      }
    }
  }

  internal var cellView: ListCell! {
    didSet {
      oldValue?.removeFromSuperview()
      self.cellView.preservesSuperviewLayoutMargins = true
      self.contentView.insertSubview(self.cellView, belowSubview: self.separator)
    }
  }

  // MARK: - Initialization -

  override init(frame: CGRect) {
    self.separator = UIView()
    super.init(frame: frame)
    self.preservesSuperviewLayoutMargins = true
    self.contentView.backgroundColor = nil
    self.contentView.preservesSuperviewLayoutMargins = true
    self.contentView.addSubview(self.separator)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - FormButton Protocol Methods -

  var isAlwaysTouchEnabled: Bool {
    return true
  }

  override var isHighlighted: Bool {
    didSet {
      self.setHighlighted(self.isHighlighted, animated: false)
    }
  }

  func setHighlighted(_ highlighted: Bool, animated: Bool) {
    self.cellView.setHighlighted(highlighted, animated: animated)
  }

  private(set) var nsm_isSelected: Bool = false {
    didSet {
      self.cellView.isSelected = self.nsm_isSelected
    }
  }

  func setSelected(_ selected: Bool, animated: Bool) {
    guard self.nsm_isSelected != selected else {
      return
    }
    self.cellView.setSelected(selected, animated: animated)
    self.nsm_isSelected = selected
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    if self.nsm_isSelected {
      self.cellView.setSelected(false, animated: false)
    }
    self.nsm_isSelected = false
    self.cellView.prepareForReuse()
  }

  // MARK: - Public Methods -

  func applySeparatorStyle(_ style: LineStyle?, insets: UIEdgeInsets = .zero) {
    self.separatorStyle = style
    self.separatorInsets = insets
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first {
      self.cellView.lastTouchLocation = touch.location(in: self.cellView)
    }
    super.touchesBegan(touches, with: event)
  }

  // MARK: - UIView Methods -

  override func layoutSubviews() {
    super.layoutSubviews()

    var cellViewFrame = self.contentView.bounds

    if let style = self.separatorStyle {
      self.separator.isHidden = false
      self.separator.backgroundColor = style.color
      self.separator.frame = CGRect(
        x: self.separatorInsets.left,
        y: self.contentView.bounds.height - style.thickness,
        width: self.contentView.bounds.width -
          self.separatorInsets.left -
          self.separatorInsets.right,
        height: style.thickness)

      cellViewFrame.size.height -= style.thickness
    } else {
      self.separator.isHidden = true
    }

    self.cellView.frame = self.contentView.bounds
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard self.isUserInteractionEnabled && !self.isHidden && self.alpha > 0.01 else {
      return nil
    }

    if self.actionsViewFrame.contains(point) {
      return super.hitTest(point, with: event)
    }

    guard self.point(inside: point, with: event) else {
      return nil
    }

    // Allow tapping Buttons if one has been hit…
    let hitView = super.hitTest(point, with: event)
    if hitView is UIControl {
      return hitView
    }

    // We prevent that the FormTapGestureRecognizer finds any other view than us, so that we
    // can get identified as a FormButton.
    return self
  }

  override func preferredLayoutAttributesFitting(
    _ layoutAttributes: UICollectionViewLayoutAttributes
  ) -> UICollectionViewLayoutAttributes {
    return self.cellView.preferredLayoutAttributesFitting(layoutAttributes)
  }
}
