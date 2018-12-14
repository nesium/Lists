//
//  AbstractCellView.swift
//  NSMForms
//
//  Created by Marc Bauer on 30.08.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import UIKit

public protocol CellStyle {
  var rowHeight: CGFloat { get }
  var separatorInset: UIEdgeInsets { get }
}

open class AbstractCell<Value, Style>: ListCell {
  open func applyValue(_ value: Value, style: Style) {
    fatalError("applyValue(:style) must be overridden in concrete subclass")
  }
}
