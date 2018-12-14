//
//  TypedListViewController.swift
//  NSMForms
//
//  Created by Marc Bauer on 27.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import IGListKit
import RxSwift

open class TypedListViewController<ItemValue, OutputValue>: ListViewController
{
  public var value: Observable<OutputValue?> {
    return self.valueSubject.asObservable()
  }

  public var completesOnCommit: Bool = false

  private let diffWitness: Diffing<ItemValue>
  private let selectionStrategy: AnyListSelectionStrategy<ItemValue, OutputValue>
  private var isUpdatingSelection: Bool = false
  private let disposeBag = DisposeBag()

  private var valueSubject = BehaviorSubject<OutputValue?>(value: nil)

  // MARK: - Initialization -

  public init<S: ListSelectionStrategy>(
    data: TypedListViewData<ItemValue>,
    diffWitness: Diffing<ItemValue>,
    selectionStrategy: S,
    placeholderView: UIView? = nil,
    layout: UICollectionViewLayout? = nil,
    sectionHeadersPinToVisibleBounds: Bool = true
  ) where S.ItemValue == ItemValue, S.OutputValue == OutputValue {
    let anyStrategy = AnyListSelectionStrategy(selectionStrategy)
    self.diffWitness = diffWitness
    self.typedData = data
    self.selectionStrategy = anyStrategy

    var beginConversionHandler: (() -> ())?
    var endConversionHandler: (() -> ())?

    super.init(
      data: data,
      placeholderView: placeholderView,
      layout: layout,
      sectionHeadersPinToVisibleBounds: sectionHeadersPinToVisibleBounds
    )

    anyStrategy.didCommit
      .flatMap { _ -> Observable<OutputValue?> in
        if anyStrategy.needsConversion {
          beginConversionHandler?()
          return anyStrategy
            .performConversion()
            .observeOn(MainScheduler.instance)
            .take(1)
            .do(onNext: { _ in endConversionHandler?() })
        }
        return anyStrategy.value.asObservable().take(1)
      }
      .subscribe(onNext: { [unowned self] value in
        self.selectionStrategyDidCommit(with: value)
      })
      .disposed(by: self.disposeBag)

    beginConversionHandler = { [weak self] in self?.beginResultConversion() }
    endConversionHandler = { [weak self] in self?.endResultConversion() }

    self.selectionStrategy.value
      .asObservable()
      .skip(1)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] _ in
        guard !self.isUpdatingSelection else {
          return
        }
        self.reloadSelection(animated: false)
      })
      .disposed(by: self.disposeBag)
  }

  // MARK: - Public Methds -

  @available(*, unavailable)
  public override var data: ListViewData {
    get { return super.data }
    set { super.data = newValue }
  }

  public var typedData: TypedListViewData<ItemValue> {
    didSet {
      super.data = self.typedData
    }
  }

  public func scrollToItem(
    item: ItemValue,
    at scrollPosition: ListViewController.ScrollPosition = .none,
    animated: Bool = true) {
    self.scrollToFirstItem(at: scrollPosition, animated: animated) {
      self.diffWitness.equals($0, item)
    }
  }

  public func scrollToFirstItem(
    at scrollPosition: ListViewController.ScrollPosition = .none,
    animated: Bool = true,
    where predicate: (ItemValue) throws -> Bool
  ) rethrows {
    guard self.isViewLoaded else {
      return
    }

    var section: Int = 0

    for sectionData in self.listAdapter.objects() as! [DiffableSectionDataBox<SectionData<ItemValue>>] {
      var row: Int = 0
      for item in sectionData.value.items {
        if try predicate(item) {
          self.scrollToRow(
            at: IndexPath(item: row, section: section),
            at: scrollPosition,
            animated: animated
          )
          return
        }
        row += 1
      }
      section += 1
    }
  }

  public func sectionData(at idx: Int) -> SectionData<ItemValue> {
    if !self.isViewLoaded {
      _ = self.view
    }
    return (self.listAdapter.object(atSection: idx) as! DiffableSectionDataBox<SectionData<ItemValue>>).value
  }

  public func item(at indexPath: IndexPath) -> ItemValue {
    return self.sectionData(at: indexPath.section).items[indexPath.item]
  }

  // MARK: - InputViewController Methods -

  open func applyValue(_ value: OutputValue?) {
    self.selectionStrategy.applyValue(value)
    valueSubject.onNext(value)
  }

  // MARK: - ListViewController Methods -

  open override var selectionBehavior: ListSelectionBehavior {
    return self.selectionStrategy.selectionBehavior
  }

  open override func isItemSelected(at indexPath: IndexPath) -> Bool {
    return self.selectionStrategy.isItemSelected(self.item(at: indexPath), at: indexPath)
  }

  open override func shouldSelectItem(at indexPath: IndexPath) -> Bool {
    return self.selectionStrategy.listShouldSelectItem(self.item(at: indexPath), at: indexPath)
  }

  open override func didSelectItem(at indexPath: IndexPath) {
    self.isUpdatingSelection = true
    self.selectionStrategy.listDidSelectItem(self.item(at: indexPath), at: indexPath)
    self.isUpdatingSelection = false
  }

  open override func shouldDeselectItem(at indexPath: IndexPath) -> Bool {
    return self.selectionStrategy.listShouldDeselectItem(self.item(at: indexPath), at: indexPath)
  }

  open override func didDeselectItem(at indexPath: IndexPath) {
    self.isUpdatingSelection = true
    self.selectionStrategy.listDidDeselectItem(self.item(at: indexPath), at: indexPath)
    self.isUpdatingSelection = false
  }

  // MARK: - Private Methods -

  private func beginResultConversion() {
    self.listView.isUserInteractionEnabled = false
  }

  private func endResultConversion() {
    self.listView.isUserInteractionEnabled = true
  }

  private func selectionStrategyDidCommit(with value: OutputValue?) {
    valueSubject.onNext(value)

    guard self.completesOnCommit else {
      return
    }

    let currentSubject = self.valueSubject
    self.valueSubject = BehaviorSubject(value: value)
    currentSubject.onCompleted()
  }
}
