//
//  ListNoSelectionStrategy.swift
//  NSMForms
//
//  Created by Marc Bauer on 30.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Bindings
import Foundation
import RxSwift

public class ListNoSelectionStrategy<ItemValue>: ListSelectionStrategy {
  public typealias OutputValue = Void

  public let selectionBehavior: ListSelectionBehavior = .continuous

  public let tap: Observable<(item: ItemValue, indexPath: IndexPath)>

  public let value: Binding<Void?>
  public let didCommit: Observable<Void>

  private let tapSubject: PublishSubject<(item: ItemValue, indexPath: IndexPath)>
  private let commitSubject: PublishSubject<Void>

  // MARK: - Initialization -

  public init() {
    self.value = Binding(target: BehaviorSubject(value: nil))
    self.tapSubject = PublishSubject()
    self.tap = self.tapSubject.asObservable()

    self.commitSubject = PublishSubject()
    self.didCommit = self.commitSubject.asObservable()
  }

  // MARK: - ListSelectionStrategy Methods -

  public func applyValue(_ value: Void?) {}

  public func isItemSelected(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return false
  }

  public func listShouldSelectItem(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return true
  }

  public func listDidSelectItem(_ item: ItemValue, at indexPath: IndexPath) {
    self.tapSubject.onNext((item: item, indexPath: indexPath))
  }

  public func listShouldDeselectItem(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return false
  }

  public func listDidDeselectItem(_ item: ItemValue, at indexPath: IndexPath) {}

  public func commit() {
    self.commitSubject.onNext(())
  }
}
