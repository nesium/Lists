//
//  AbstractHeaderFooterView.swift
//  NSMForms
//
//  Created by Marc Bauer on 28.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import UIKit

public protocol HeaderFooterViewStyle {
  var rowHeight: CGFloat { get }
}

open class AbstractHeaderFooterView<Value, Style>: UIView {
  // MARK: - Initialization -

  public required override init(frame: CGRect) {
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func prepareForReuse() {}

  open func applyValue(_ value: Value, style: Style) {
    fatalError("applyValue(:style) must be overridden in concrete subclass")
  }
}
