//
//  ListMultiSelectionStrategy.swift
//  NSMForms
//
//  Created by Marc Bauer on 30.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Bindings
import Foundation
import NSMFoundation
import RxSwift

public class ListMultiSelectionStrategy<ItemValue>: ListSelectionStrategy {
  public typealias OutputValue = [ItemValue]

  public let selectionBehavior: ListSelectionBehavior = .toggle

  public let value: Binding<[ItemValue]?>
  public let didCommit: Observable<Void>

  private let diffWitness: Diffing<ItemValue>
  private let itemFilter: (ItemValue) -> (Bool)

  private let commitSubject: PublishSubject<Void>
  private var selectedItems: [String: ItemValue] = [:]
  private let valueSubject: BehaviorSubject<[ItemValue]?>

  private let disposeBag = DisposeBag()

  // MARK: - Initialization -

  public init(
    diffWitness: Diffing<ItemValue>,
    itemFilter: @escaping ((ItemValue) -> (Bool)) = const(true)
  ) {
    self.diffWitness = diffWitness
    self.valueSubject = BehaviorSubject(value: [])
    self.value = Binding(target: self.valueSubject)

    self.commitSubject = PublishSubject()
    self.didCommit = self.commitSubject.asObservable()
    self.itemFilter = itemFilter

    self.valueSubject
      .skip(1)
      .subscribe(onNext: { [unowned self] items in
        self.applyValue(items)
      })
      .disposed(by: self.disposeBag)
  }

  // MARK: - ListSelectionStrategy Methods -

  public func applyValue(_ value: [ItemValue]?) {
    self.selectedItems.removeAll()
    value?.forEach { item in
      self.selectedItems[self.diffWitness.identifier(item)] = item
    }
  }

  public func isItemSelected(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return self.selectedItems[self.diffWitness.identifier(item)] != nil
  }

  public func listShouldSelectItem(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return self.itemFilter(item)
  }

  public func listDidSelectItem(_ item: ItemValue, at indexPath: IndexPath) {
    self.selectedItems[self.diffWitness.identifier(item)] = item
    self.valueSubject.onNext(Array(self.selectedItems.values))
  }

  public func listShouldDeselectItem(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return true
  }

  public func listDidDeselectItem(_ item: ItemValue, at indexPath: IndexPath) {
    self.selectedItems.removeValue(forKey: self.diffWitness.identifier(item))
    self.valueSubject.onNext(Array(self.selectedItems.values))
  }

  public func commit() {
    self.commitSubject.onNext(())
  }
}
