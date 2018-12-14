//
//  ListSingleSelectionStrategy.swift
//  NSMForms
//
//  Created by Marc Bauer on 30.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Bindings
import Foundation
import RxSwift

public class ListSingleSelectionStrategy<ItemValue>: ListSelectionStrategy {
  public typealias OutputValue = ItemValue

  public let selectionBehavior: ListSelectionBehavior = .continuous

  public let value: Binding<ItemValue?>
  public let didCommit: Observable<Void>

  public var commitsOnSelection: Bool

  private let diffWitness: Diffing<ItemValue>
  private let commitSubject: PublishSubject<Void>
  private var selectedItem: ItemValue?
  private let valueSubject: BehaviorSubject<ItemValue?>
  private let disposeBag: DisposeBag = DisposeBag()

  // MARK: - Initialization -

  public init(diffWitness: Diffing<ItemValue>, commitsOnSelection: Bool = true) {
    self.diffWitness = diffWitness
    self.commitsOnSelection = commitsOnSelection
    self.valueSubject = BehaviorSubject(value: nil)
    self.value = Binding(target: self.valueSubject)
    self.commitSubject = PublishSubject()
    self.didCommit = self.commitSubject.asObservable()

    self.valueSubject
      .skip(1)
      .subscribe(onNext: { [unowned self] items in
        self.applyValue(items)
      })
      .disposed(by: self.disposeBag)
  }

  // MARK: - ListSelectionStrategy Methods -

  public func applyValue(_ value: ItemValue?) {
    self.selectedItem = value
  }

  public func isItemSelected(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return self.selectedItem.map { self.diffWitness.equals($0, item) } ?? false
  }

  public func listShouldSelectItem(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return true
  }

  public func listDidSelectItem(_ item: ItemValue, at indexPath: IndexPath) {
    self.selectedItem = item
    
    if (self.commitsOnSelection) {
      self.commit()
    } else {
      self.valueSubject.onNext(self.selectedItem)
    }
  }

  public func listShouldDeselectItem(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return true
  }

  public func listDidDeselectItem(_ item: ItemValue, at indexPath: IndexPath) {
    self.selectedItem = nil
  }

  public func commit() {
    self.valueSubject.onNext(self.selectedItem)
    self.commitSubject.onNext(())
  }
}
