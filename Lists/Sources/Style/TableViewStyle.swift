//
//  TableViewStyle.swift
//  NSMForms
//
//  Created by Marc Bauer on 17.07.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import UIKit

public struct TableViewStyle {
  public var separator: LineStyle?

  public init(separator: LineStyle? = nil) {
    self.separator = separator
  }
}

extension TableViewStyle {
  public func apply(to tableView: UITableView) {
    tableView.separatorColor = self.separator?.color
  }
}
