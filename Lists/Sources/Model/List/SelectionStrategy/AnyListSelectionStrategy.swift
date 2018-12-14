//
//  AnyListSelectionStrategy.swift
//  NSMForms
//
//  Created by Marc Bauer on 30.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Bindings
import Foundation
import RxSwift

internal class AnyListSelectionStrategy<ItemValue, OutputValue>: ListSelectionStrategy {
  let selectionBehavior: ListSelectionBehavior
  let value: Binding<OutputValue?>
  let didCommit: Observable<Void>
  let needsConversion: Bool

  typealias QueryBlock = (ItemValue, IndexPath) -> Bool
  typealias NoticeBlock = (ItemValue, IndexPath) -> ()

  private let applyValue: (OutputValue?) -> ()

  private let isItemSelected: QueryBlock
  private let shouldSelect: QueryBlock
  private let didSelect: NoticeBlock
  private let shouldDeselect: QueryBlock
  private let didDeselect: NoticeBlock
  private let performCommit: () -> ()
  private let performConversionBlock: () -> (Observable<OutputValue?>)

  init<S: ListSelectionStrategy>(_ strategy: S)
    where S.ItemValue == ItemValue, S.OutputValue == OutputValue {
    self.selectionBehavior = strategy.selectionBehavior
    self.value = strategy.value
    self.didCommit = strategy.didCommit

    self.applyValue = { value in
      strategy.applyValue(value)
    }
    self.isItemSelected = { item, indexPath in
      strategy.isItemSelected(item, at: indexPath)
    }
    self.shouldSelect = { item, indexPath in
      strategy.listShouldSelectItem(item, at: indexPath)
    }
    self.didSelect = { item, indexPath in
      strategy.listDidSelectItem(item, at: indexPath)
    }
    self.shouldDeselect = { item, indexPath in
      strategy.listShouldDeselectItem(item, at: indexPath)
    }
    self.didDeselect = { item, indexPath in
      strategy.listDidDeselectItem(item, at: indexPath)
    }
    self.performCommit = {
      strategy.commit()
    }

    if let convertingStrategy = strategy
      as? ListSingleSelectionConversionStrategy<ItemValue, OutputValue> {
      self.needsConversion = true
      self.performConversionBlock = { convertingStrategy.performConversion() }
    } else {
      self.needsConversion = false
      self.performConversionBlock = { strategy.value.asObservable() }
    }
  }

  func applyValue(_ value: OutputValue?) {
    self.applyValue(value)
  }

  func isItemSelected(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return self.isItemSelected(item, indexPath)
  }

  func listShouldSelectItem(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return self.shouldSelect(item, indexPath)
  }

  func listDidSelectItem(_ item: ItemValue, at indexPath: IndexPath) {
    self.didSelect(item, indexPath)
  }

  func listShouldDeselectItem(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return self.shouldDeselect(item, indexPath)
  }

  func listDidDeselectItem(_ item: ItemValue, at indexPath: IndexPath) {
    self.didDeselect(item, indexPath)
  }

  func commit() {
    self.performCommit()
  }

  func performConversion() -> Observable<OutputValue?> {
    return self.performConversionBlock()
  }
}
