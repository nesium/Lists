//
//  SectionDataListSectionController.swift
//  NSMForms
//
//  Created by Marc Bauer on 27.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import IGListKit

protocol ListViewSectionController {
  var sectionBackgroundColor: UIColor? { get }
}

internal class SectionDataListSectionController:
  ListSectionController,
  ListSupplementaryViewSource,
  ListViewSectionController
{
  enum ListDiffingState {
    case idle
    case queued
    case applied
  }

  private var state: ListDiffingState = .idle
  private var data: SectionDataType?
  private var oldItems: [ListDiffable] = []

  internal var sectionBackgroundColor: UIColor?

  // MARK: - Initialization -

  override init() {
    super.init()
    self.supplementaryViewSource = self
    self.sectionBackgroundColor = .green
  }

  func update(animated: Bool, completion: ((Bool) -> ())?) {
    guard let data = self.data, self.state == .idle else {
      completion?(false)
      return
    }

    self.state = .queued

    let oldItems = self.oldItems
    let collectionContext = self.collectionContext!

    var needsSeparatorUpdate = false

    collectionContext.performBatch(
      animated: animated,
      updates: { batchContext in
        guard self.state == .queued else {
          return
        }

        let result = ListDiff(
          oldArray: oldItems,
          newArray: data.diffableItems(),
          option: .equality
        )

        result.updates.forEach { idx in
          let identifier = oldItems[idx].diffIdentifier()
          let idxAfterUpdate = result.newIndex(forIdentifier: identifier as! NSString)

          if idxAfterUpdate != NSNotFound {
            data.updateCell(
              at: idxAfterUpdate,
              context: collectionContext,
              sectionController: self
            )
          }
        }

        batchContext.delete(in: self, at: result.deletes)
        batchContext.insert(in: self, at: result.inserts)

        result.moves.forEach { move in
          batchContext.move(in: self, from: move.from, to: move.to)
        }

        if !result.deletes.isEmpty || !result.inserts.isEmpty {
          needsSeparatorUpdate = true
        }

        self.state = .applied
      },
      completion: { finished in
        self.state = .idle

        if needsSeparatorUpdate {
          data.updateSeparators(in: collectionContext, sectionController: self)
        }

        completion?(finished)
      })
  }

  // MARK: - IBListSectionController overrides -

  override func numberOfItems() -> Int {
    return self.data?.numberOfItems ?? 0
  }

  override func sizeForItem(at index: Int) -> CGSize {
    let availableWidth =
      collectionContext!.containerSize.width -
      self.inset.left -
      self.inset.right

    return self.data!.sizeForItem(at: index, availableWidth: availableWidth)
  }

  override func cellForItem(at index: Int) -> UICollectionViewCell {
    return self.data!.cellForItem(
      at: index,
      context: self.collectionContext!,
      sectionController: self
    )
  }

  override func didUpdate(to object: Any) {
    let needsUpdate = self.data != nil

    let data = (object as! SectionDataBox).sectionData

    self.oldItems = self.data?.diffableItems() ?? []
    self.data = data

    let style = data.style

    self.inset = style.inset
    self.minimumInteritemSpacing = style.minimumInteritemSpacing
    self.minimumLineSpacing = style.minimumLineSpacing
    self.sectionBackgroundColor = style.backgroundColor

    if needsUpdate {
      self.update(animated: true, completion: nil)
    }
  }

  // MARK: - ListSupplementaryViewSource Methods -

  func supportedElementKinds() -> [String] {
    var elementKinds = [String]()

    if self.data!.header != nil {
      elementKinds.append(UICollectionView.elementKindSectionHeader)
    }
    if self.data!.footer != nil {
      elementKinds.append(UICollectionView.elementKindSectionFooter)
    }
    return elementKinds
  }

  func viewForSupplementaryElement(
    ofKind elementKind: String,
    at index: Int) -> UICollectionReusableView {
    switch elementKind {
    case UICollectionView.elementKindSectionHeader:
        return self.data!.header!.view(
          ofKind: elementKind,
          at: index,
          context: self.collectionContext!,
          sectionController: self
        )
    case UICollectionView.elementKindSectionFooter:
        return self.data!.footer!.view(
          ofKind: elementKind,
          at: index,
          context: self.collectionContext!,
          sectionController: self
        )
      default:
        fatalError("Unknown element type \(elementKind)")
    }
  }

  func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
    let availableWidth = collectionContext!.containerSize.width - self.inset.left - self.inset.right

    switch elementKind {
    case UICollectionView.elementKindSectionHeader:
        return CGSize(
          width: availableWidth,
          height: self.data!.header!.height
        )
    case UICollectionView.elementKindSectionFooter:
        return CGSize(
          width: availableWidth,
          height: self.data!.footer!.height
        )
      default:
        fatalError("Unknown element type \(elementKind)")
    }
  }
}
