//
//  TypedCollectionViewContainerCell.swift
//  NSMForms
//
//  Created by Marc Bauer on 21.11.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import UIKit

internal final class TypedCollectionViewContainerCell<Value, Style>: CollectionViewContainerCell {
  @available(*, unavailable)
  override var cellView: ListCell! {
    set { super.cellView = newValue }
    get { return super.cellView }
  }

  internal var typedCellView: AbstractCell<Value, Style>! {
    didSet {
      super.cellView = typedCellView
    }
  }

  func applyValue(_ value: Value, style: Style) {
    self.typedCellView.applyValue(value, style: style)
  }
}
