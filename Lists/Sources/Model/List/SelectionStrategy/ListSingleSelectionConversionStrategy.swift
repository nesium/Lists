//
//  ListSingleSelectionConversionStrategy.swift
//  NSMForms
//
//  Created by Marc Bauer on 22.01.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import Bindings
import Foundation
import NSMFoundation
import RxSwift

public enum ConversionStatus {
  case loading
  case error(Error)
  case success
}

public class ListSingleSelectionConversionStrategy<ItemValue, OutputValue>
  : ListSelectionConversionStrategy {
  public let selectionBehavior: ListSelectionBehavior = .continuous

  public let value: Binding<OutputValue?>
  public let didCommit: Observable<Void>

  public var conversionStatusHandler: ((ConversionStatus) -> ())?

  private let itemToOutputTransformer: (ItemValue) -> (Observable<OutputValue?>)
  private let itemToOutputComparator: (ItemValue, OutputValue) -> (Bool)
  private let itemFilter: (ItemValue) -> (Bool)

  private let diffWitness: Diffing<ItemValue>
  private let commitsOnSelection: Bool
  private let commitSubject: PublishSubject<Void>
  private var selectedItem: Either<ItemValue, OutputValue>?
  private let valueSubject: BehaviorSubject<OutputValue?>
  private let disposeBag: DisposeBag = DisposeBag()

  // MARK: - Initialization -

  public init(
    diffWitness: Diffing<ItemValue>,
    commitsOnSelection: Bool = true,
    itemToOutputTransformer: @escaping (ItemValue) -> Observable<OutputValue?>,
    itemToOutputComparator: @escaping (ItemValue, OutputValue) -> (Bool),
    itemFilter: @escaping (ItemValue) -> (Bool) = const(true)
  ) {
    self.diffWitness = diffWitness
    self.commitsOnSelection = commitsOnSelection
    self.valueSubject = BehaviorSubject(value: nil)
    self.value = Binding(target: self.valueSubject)
    self.commitSubject = PublishSubject()
    self.didCommit = self.commitSubject.asObservable()
    self.itemToOutputComparator = itemToOutputComparator
    self.itemToOutputTransformer = itemToOutputTransformer
    self.itemFilter = itemFilter

    self.valueSubject
      .skip(1)
      .subscribe(onNext: { [unowned self] item in
        self.applyValue(item)
      })
      .disposed(by: self.disposeBag)
  }

  // MARK: - ListSelectionStrategy Methods -

  public func applyValue(_ value: OutputValue?) {
    guard let value = value else {
      self.selectedItem = nil
      return
    }
    self.selectedItem = .right(value)
  }

  public func isItemSelected(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    guard let selectedItem = self.selectedItem else {
      return false
    }

    switch selectedItem {
      case .left(let ourItem):
        return self.diffWitness.equals(item, ourItem)
      case .right(let ourItem):
        return self.itemToOutputComparator(item, ourItem)
    }
  }

  public func listShouldSelectItem(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return self.itemFilter(item)
  }

  public func listDidSelectItem(_ item: ItemValue, at indexPath: IndexPath) {
    self.selectedItem = .left(item)

    if (self.commitsOnSelection) {
      self.commit()
    }
  }

  public func listShouldDeselectItem(_ item: ItemValue, at indexPath: IndexPath) -> Bool {
    return true
  }

  public func listDidDeselectItem(_ item: ItemValue, at indexPath: IndexPath) {
    self.selectedItem = nil
  }

  public func commit() {
    self.commitSubject.onNext(())
  }

  // MARK: - ListSelectionConversionStrategy Methods -

  public func performConversion() -> Observable<OutputValue?> {
    let observable: Observable<OutputValue?>

    switch self.selectedItem {
      case .none:
        observable = Observable.just(nil)
      case .some(.left(let item)):
        self.conversionStatusHandler?(.loading)
        observable = self.itemToOutputTransformer(item)
      case .some(.right(let item)):
        observable = Observable.just(item)
    }

    let valueSubject = self.valueSubject

    return observable
      .observeOn(MainScheduler.instance)
      .do(
        onNext: { value in
          valueSubject.onNext(value)
          self.conversionStatusHandler?(.success)
        },
        onError: {
          self.conversionStatusHandler?(.error($0))
        }
      )
  }
}
