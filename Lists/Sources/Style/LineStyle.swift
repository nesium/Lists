//
//  LineStyle.swift
//  Lists
//
//  Created by Marc Bauer on 13.12.18.
//  Copyright © 2018 Marc Bauer. All rights reserved.
//

import UIKit

public struct LineStyle: Equatable {
  public var thickness: CGFloat
  public var color: UIColor

  public init(_ thickness: CGFloat, _ color: UIColor) {
    self.thickness = thickness
    self.color = color
  }

  public static func ==(lhs: LineStyle, rhs: LineStyle) -> Bool {
    return lhs.thickness == rhs.thickness && lhs.color == rhs.color
  }
}
