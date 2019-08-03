//
//  ListViewController.swift
//  NSMForms
//
//  Created by Marc Bauer on 27.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import IGListKit
import NSMUIKit
import RxSwift
import SwipeCellKit
import UIKit

public protocol ListViewControllerScrollDelegate: AnyObject {
  func listViewControllerDidScroll(_ listView: ListViewController)
  func listViewControllerWillEndDragging(
    _ listView: ListViewController,
    withVelocity velocity: CGPoint,
    targetContentOffset: inout CGPoint
  )
  func listViewControllerWillBeginDragging(_ listView: ListViewController)
}

public protocol ListViewControllerUpdateDelegate: AnyObject {
  func listViewControllerWillCommitUpdates(_ listView: ListViewController, animated: Bool)
  func listViewControllerDidCommitUpdates(
    _ listView: ListViewController,
    listState: ListState,
    animated: Bool
  )
  func listViewControllerDidFinishUpdates(
    _ listView: ListViewController,
    listState: ListState,
    animated: Bool
  )
}

public protocol ListViewControllerSwipeActionsDelegate: AnyObject {
  func listViewController(
    _ listView: ListViewController,
    canHaveTrailingSwipeActionsInSection section: Int
  ) -> Bool

  func listViewController(
    _ listView: ListViewController,
    trailingSwipeActionsConfigurationAt indexPath: IndexPath
  ) -> UISwipeActionsConfiguration?
}

public extension ListViewControllerSwipeActionsDelegate {
  func listViewController(
    _ listView: ListViewController,
    canHaveTrailingSwipeActionsInSection section: Int
  ) -> Bool {
    return true
  }
}

public extension ListViewControllerScrollDelegate {
  func listViewControllerDidScroll(_ listView: ListViewController) {}
  func listViewControllerWillEndDragging(
    _ listView: ListViewController,
    withVelocity velocity: CGPoint,
    targetContentOffset: inout CGPoint
  ) {}
  func listViewControllerWillBeginDragging(_ listView: ListViewController) {}
}

public extension ListViewControllerUpdateDelegate {
  func listViewControllerWillCommitUpdates(_ listView: ListViewController, animated: Bool) {}
  func listViewControllerDidCommitUpdates(
    _ listView: ListViewController,
    listState: ListState,
    animated: Bool
  ) {}
  func listViewControllerDidFinishUpdates(
    _ listView: ListViewController,
    listState: ListState,
    animated: Bool
  ) {}
}

public struct ListState {
  public let contentOffset: CGPoint
  public let contentSize: CGSize
}

open class ListViewController:
  FlexViewController,
  ListAdapterDataSource,
  UICollectionViewDelegate,
  SwipeTableViewCellDelegate,
  CollectionViewLayoutDelegate,
  UICollectionViewDelegateListViewFlowLayout
{
  public enum ViewState {
    case list
    case placeholder
  }

  public enum ScrollPosition {
    case none
    case top
    case middle
    case bottom
  }

  internal var listAdapter: ListAdapter!

  private var collectionView: CollectionView!
  private var layout: UICollectionViewLayout

  private var sectionData: [ListDiffable] = []
  private var sectionDataSubscription: Disposable?

  private let updateSubject: PublishSubject<ListState>
  private var keyboardSubscription: Disposable?

  struct Flags {
    var isFirstUpdate = true
    var isUpdating = false
    var didSendCommitUpdateMessage = false
    var listState: ListState? = nil
    var isUpdatingAnimated = false
  }
  private var flags: Flags = Flags()

  private var currentTrailingSwipeActions: UISwipeActionsConfiguration?

  public let placeholderView: UIView?

  public private(set) var viewState: ViewState = .list

  public let update: Observable<ListState>

  public weak var scrollDelegate: ListViewControllerScrollDelegate?
  public weak var updateDelegate: ListViewControllerUpdateDelegate?
  public weak var swipeActionsDelegate: ListViewControllerSwipeActionsDelegate?

  /// If true, the contentInset and scrollIndicatorInsets of the contained TableView will
  /// automatically be modified if a keyboard is shown, to the height of the intersection of
  /// the keyboard.
  public var automaticallyAvoidsKeyboard: Bool = true

  public var listView: UIScrollView {
    if !self.isViewLoaded {
      _ = self.view
    }
    return self.collectionView
  }

  // MARK: - Initialization -

  public init(
    data: ListViewData,
    placeholderView: UIView? = nil,
    layout: UICollectionViewLayout? = nil,
    sectionHeadersPinToVisibleBounds: Bool = true
  ) {
    self.data = data
    self.placeholderView = placeholderView

    self.updateSubject = PublishSubject()
    self.update = self.updateSubject.asObservable()

    if let layout = layout {
      self.layout = layout
    } else {
      let flowLayout = ListViewFlowLayout()
      flowLayout.sectionHeadersPinToVisibleBounds = sectionHeadersPinToVisibleBounds
      self.layout = flowLayout
    }

    super.init()

    self.nsm_edgesForExtendedLayout = .all

    if layout == nil {
      (self.layout as? ListViewFlowLayout)?.delegate = self
    }
  }

  deinit {
    self.sectionDataSubscription?.dispose()
    self.keyboardSubscription?.dispose()
  }

  // MARK: - Public Methods -

  public var data: ListViewData {
    didSet {
      guard self.isViewLoaded else {
        return
      }
      self.applyListViewData()
    }
  }

  public func reloadSelection(animated: Bool) {
    guard self.isViewLoaded else {
      return
    }

    self.collectionView.indexPathsForVisibleItems.forEach { indexPath in
      guard let cell = self.collectionView.cellForItem(at: indexPath)
        as? SelectableCollectionViewCell else {
        return
      }
      cell.setSelected(self.isItemSelected(at: indexPath), animated: animated)
    }
  }

  public func scrollToRow(
    at indexPath: IndexPath,
    at scrollPosition: ScrollPosition = .none,
    animated: Bool = true) {
    let collectionViewScrollPosition: UICollectionView.ScrollPosition

    switch scrollPosition {
      case .none:
        guard let itemFrame = self.collectionView.collectionViewLayout
          .layoutAttributesForItem(at: indexPath)?.frame else {
          print(
            "Could not scroll to indexPath \(indexPath). " +
            "The collectionViewLayout did not return a frame."
          )
          return
        }

        guard !self.collectionView.bounds.contains(itemFrame) else {
          // item is visible. nothing to do.
          return
        }

        if itemFrame.minY < self.collectionView.bounds.minY {
          collectionViewScrollPosition = .top
        } else {
          collectionViewScrollPosition = .bottom
        }

      case .bottom:
        collectionViewScrollPosition = .bottom

      case .top:
        collectionViewScrollPosition = .top

      case .middle:
        collectionViewScrollPosition = .centeredVertically
    }

    self.collectionView.scrollToItem(
      at: indexPath,
      at: collectionViewScrollPosition,
      animated: animated
    )
  }

  /// Point should be relative to `listView`.
  public func indexPathForItem(at point: CGPoint) -> IndexPath? {
    return self.collectionView.indexPathForItem(at: point)
  }

  public var numberOfSections: Int {
    return self.listAdapter.objects().count
  }

  // MARK: - Internal Methods -

  internal func supplementaryView(
    forElementKind elementKind: String,
    at indexPath: IndexPath
  ) -> UICollectionReusableView? {
    return self.collectionView.supplementaryView(forElementKind: elementKind, at: indexPath)
  }

  // MARK: - Hooks -

  open var selectionBehavior: ListSelectionBehavior {
    return .toggle
  }
  open func isItemSelected(at indexPath: IndexPath) -> Bool { return false }
  open func shouldSelectItem(at indexPath: IndexPath) -> Bool { return false }
  open func didSelectItem(at indexPath: IndexPath) {}
  open func shouldDeselectItem(at indexPath: IndexPath) -> Bool { return false }
  open func didDeselectItem(at indexPath: IndexPath) {}
  open func numberOfSectionsDidChange() {}

  // MARK: - UIViewController Methods -

  open override func viewDidLoad() {
    super.viewDidLoad()

    self.view.backgroundColor = .white

    self.collectionView = CollectionView(frame: .zero, collectionViewLayout: self.layout)
    self.collectionView.backgroundView = nil
    self.collectionView.backgroundColor = nil
    self.collectionView.layoutDelegate = self
    self.view.addSubview(self.collectionView)

    if let placeholderView = self.placeholderView {
      self.view.addSubview(placeholderView)
      placeholderView.flex.includedInLayout = false
      placeholderView.isHidden = true
    }

    self.applyListViewData()

    self.view.flex.style {
      $0.enabled = true
      $0.direction = .column
      $0.alignItems = .stretch
    }

    self.collectionView.flex.style {
      $0.enabled = true
      $0.grow = 1
      $0.shrink = 1
    }

    if self.keyboardSubscription == nil {
      self.keyboardSubscription = KeyboardObserver.shared.observableKeyboardRect
        .subscribe(onNext: { [unowned self] rect in
          self.avoidKeyboardInRect(rect)
        })
    }

    self.updatePlaceholderView()
  }

  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.avoidKeyboardInRect(KeyboardObserver.shared.keyboardRect)
  }

  // MARK: - ListAdapterDataSourceMethods -

  public func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
    return self.sectionData
  }

  public func listAdapter(
    _ listAdapter: ListAdapter,
    sectionControllerFor object: Any) -> ListSectionController {
    return self.data.controller(for: object)
  }

  public func emptyView(for listAdapter: ListAdapter) -> UIView? {
    return nil
  }

  // MARK: - UICollectionViewDelegate Methods -

  public func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath) {
    if self.selectionBehavior == .toggle && self.isItemSelected(at: indexPath) {
      if self.shouldDeselectItem(at: indexPath) {
        self.didDeselectItem(at: indexPath)
        self.reloadSelection(animated: true)
      }
    } else {
      if self.shouldSelectItem(at: indexPath) {
        self.didSelectItem(at: indexPath)
        self.reloadSelection(animated: true)
      }
    }
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    willDisplay cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    // It is important not to set us as the delegate of the SwipeTableViewCell if we have more
    // than one column, since this affects the point(inside:event:) outcome in the SwipeTableViewCell.
    if
      let swipeActionDelegate = self.swipeActionsDelegate,
      swipeActionDelegate.listViewController(
        self,
        canHaveTrailingSwipeActionsInSection: indexPath.section
      ),
      let cell = cell as? SwipeTableViewCell
    {
      cell.delegate = self
    }
    if let cell = cell as? SelectableCollectionViewCell {
      cell.setSelected(self.isItemSelected(at: indexPath), animated: false)
    }
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    willDisplaySupplementaryView view: UICollectionReusableView,
    forElementKind elementKind: String,
    at indexPath: IndexPath
  ) {
    // workaround for http://www.openradar.me/34308893
    // where SectionHeaders in a UICollectionViewFlowLayout are displayed above the
    // scroll indicator.
    if elementKind == UICollectionView.elementKindSectionHeader {
      view.layer.zPosition = 0
    }
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    didEndDisplaying cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    guard cell is SelectableCollectionViewCell else {
      return
    }

    // Reset the state modified by SwipeTableViewCell, so that in case of a swipe-to-delete
    // action, the reused cell looks pretty again.
    let cellFrame: CGRect

    if let layoutAttributes = self.collectionView.lst_safeLayoutAttributesForItem(at: indexPath) {
      cellFrame = layoutAttributes.frame
    } else {
      var frame = cell.frame
      frame.origin.x = 0
      cellFrame = frame
    }

    cell.frame = cellFrame
    cell.mask = nil
  }

  // MARK: - UICollectionViewDelegateListViewFlowLayout Methods -

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    backgroundColorForSectionAt section: Int
  ) -> UIColor? {
    return (self.listAdapter.sectionController(
      forSection: section
    ) as? ListViewSectionController)?.sectionBackgroundColor
  }

  // MARK: - UIScrollViewDelegate Methods -

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    self.scrollDelegate?.listViewControllerDidScroll(self)
  }

  public func scrollViewWillEndDragging(
    _ scrollView: UIScrollView,
    withVelocity velocity: CGPoint,
    targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    self.scrollDelegate?.listViewControllerWillEndDragging(
      self,
      withVelocity: velocity,
      targetContentOffset: &targetContentOffset.pointee
    )
  }

  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    self.scrollDelegate?.listViewControllerWillBeginDragging(self)
  }

  // MARK: - SwipeTableViewCellDelegate Methods -

  public func collectionView(
    _ collectionView: UICollectionView,
    editActionsForRowAt indexPath: IndexPath,
    for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard orientation == .right else {
      return nil
    }

    guard let cell = collectionView.cellForItem(at: indexPath) as? SwipeTableViewCell else {
      return nil
    }

    self.currentTrailingSwipeActions = self.swipeActionsDelegate?.listViewController(
      self,
      trailingSwipeActionsConfigurationAt: indexPath
    )

    guard let config = self.currentTrailingSwipeActions else {
      return nil
    }

    return config.actions.map { action in
      let style: SwipeActionStyle

      switch action.style {
        case .normal:
          style = .default
        case .destructive:
          style = .destructive
        @unknown default:
          style = .default
      }

      let swipeAction = SwipeAction(
        style: style,
        title: action.title) { _, _ in
          action.handler(action, collectionView) { actionPerformed in
            cell.hideSwipe(animated: true)
          }
        }
      swipeAction.backgroundColor = action.backgroundColor

      return swipeAction
    }
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    editActionsOptionsForRowAt indexPath: IndexPath,
    for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
    var options = SwipeTableOptions()

    if self.currentTrailingSwipeActions?.performsFirstActionWithFullSwipe == true {
      switch self.currentTrailingSwipeActions?.actions.first?.style {
        case .some(.normal):
          options.expansionStyle = .selection
        case .some(.destructive):
          options.expansionStyle = .destructiveAfterFill
        case .none:
          break
        @unknown default:
          break
      }
    }

    return options
  }

  // MARK: - CollectionViewLayoutDelegate Methods -

  func collectionViewContentSizeDidChange(_ collectionView: CollectionView) {
    self.collectionView.flex.setIsDirty()
    self.view.nsm_invalidateIntrinsicContentSize()
  }

  func collectionViewDidLayoutSubviews(_ collectionView: CollectionView) {
    guard
      self.flags.isUpdating && !self.flags.didSendCommitUpdateMessage,
      let listState = self.flags.listState else {
      return
    }
    self.flags.didSendCommitUpdateMessage = true
    self.updateDelegate?.listViewControllerDidCommitUpdates(
      self,
      listState: listState,
      animated: self.flags.isUpdatingAnimated
    )
  }

  // MARK: - Private Methods -

  private func applyListViewData() {
    self.sectionDataSubscription?.dispose()
    self.sectionData = []

    self.flags.isFirstUpdate = true

    self.listAdapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    self.listAdapter.collectionView = collectionView
    self.listAdapter.dataSource = self
    self.listAdapter.collectionViewDelegate = self
    self.listAdapter.scrollViewDelegate = self

    self.sectionDataSubscription = self.data.sectionData
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] sectionData in
        let oldNumberOfSections = self.sectionData.count
        self.sectionData = sectionData

        let animated = !self.flags.isFirstUpdate
        let listState = ListState(
          contentOffset: self.listView.contentOffset,
          contentSize: self.listView.contentSize
        )

        self.flags.isUpdating = true
        self.flags.isUpdatingAnimated = animated
        self.flags.didSendCommitUpdateMessage = false
        self.flags.listState = listState

        self.updateDelegate?.listViewControllerWillCommitUpdates(self, animated: animated)

        // the completion block is potentially performed when we're already deallocated as it
        // is scheduled on the runloop, so we'll switch to a weak pointer here…
        self.listAdapter.performUpdates(animated: animated, completion: { [weak self] _ in
          guard let self = self else {
            return
          }

          self.flags.isUpdating = false
          self.flags.isUpdatingAnimated = false
          self.flags.listState = nil

          if oldNumberOfSections != sectionData.count {
            self.numberOfSectionsDidChange()
          }

          self.updateSubject.on(.next(listState))
          self.updateDelegate?.listViewControllerDidFinishUpdates(
            self,
            listState: listState,
            animated: animated
          )

          self.view.nsm_invalidateIntrinsicContentSize()
        })

        self.flags.isFirstUpdate = false

        self.updatePlaceholderView()
      })
  }

  private func avoidKeyboardInRect(_ rect: CGRect?) {
    guard automaticallyAvoidsKeyboard else {
      return
    }

    guard let rect = rect else {
      self.collectionView.contentInset = .zero
      self.collectionView.scrollIndicatorInsets = .zero
      return
    }

    let intersection = self.collectionView.bounds.intersection(
      self.collectionView.convert(rect, from: nil)
    )
    
    let insets = UIEdgeInsets(
      top: 0,
      left: 0,
      bottom: intersection.height - self.collectionView.safeAreaInsets.bottom,
      right: 0
    )

    self.collectionView.contentInset = insets
    self.collectionView.scrollIndicatorInsets = insets
  }

  private func updatePlaceholderView() {
    if self.sectionData.isEmpty, let placeholderView = self.placeholderView {
      self.collectionView.flex.includedInLayout = false
      self.collectionView.isHidden = true

      placeholderView.flex.includedInLayout = true
      placeholderView.isHidden = false

      self.viewState = .placeholder
    } else {
      self.collectionView.flex.includedInLayout = true
      self.collectionView.isHidden = false

      self.placeholderView?.flex.includedInLayout = false
      self.placeholderView?.isHidden = true

      self.viewState = .list
    }

    self.view.setNeedsLayout()
  }
}
