//
//  ListSelectionStrategy.swift
//  NSMForms
//
//  Created by Marc Bauer on 30.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Bindings
import Foundation
import RxSwift

public enum ListSelectionBehavior {
  case toggle
  case continuous
}

public protocol ListSelectionStrategy: AnyObject {
  associatedtype ItemValue
  associatedtype OutputValue

  var value: Binding<OutputValue?> { get }

  var selectionBehavior: ListSelectionBehavior { get }
  var didCommit: Observable<Void> { get }

  func applyValue(_ value: OutputValue?)

  func isItemSelected(_ item: ItemValue, at indexPath: IndexPath) -> Bool

  func listShouldSelectItem(_ item: ItemValue, at indexPath: IndexPath) -> Bool
  func listDidSelectItem(_ item: ItemValue, at indexPath: IndexPath)

  func listShouldDeselectItem(_ item: ItemValue, at indexPath: IndexPath) -> Bool
  func listDidDeselectItem(_ item: ItemValue, at indexPath: IndexPath)

  func commit()
}

public protocol ListSelectionConversionStrategy: ListSelectionStrategy {
  func performConversion() -> Observable<OutputValue?>
}
