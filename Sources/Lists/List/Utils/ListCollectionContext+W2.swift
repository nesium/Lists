//
//  ListCollectionContext+W2.swift
//  NSMForms
//
//  Created by Marc Bauer on 21.11.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import IGListKit

extension ListCollectionContext {
  func w2_dequeueAndUpdateReusableCell<T: ListCell>(
    of type: T.Type,
    for ctrl: ListSectionController,
    at index: Int,
    updateHandler: (T) -> ()
  ) -> CollectionViewContainerCell {
    let cell = self.dequeueReusableCell(
      of: CollectionViewContainerCell.self,
      withReuseIdentifier: String(describing: T.self),
      for: ctrl,
      at: index
    ) as! CollectionViewContainerCell

    if cell.cellView == nil {
      cell.cellView = type.init(frame: .zero)
    }

    updateHandler(cell.cellView as! T)

    return cell
  }

  func w2_updateCellForItem<T: ListCell>(
    _ cellClass: T.Type,
    at index: Int,
    sectionController: ListSectionController,
    updateHandler: (T) -> ()
  ) -> CollectionViewContainerCell? {
    guard let cell = self.cellForItem(
        at: index,
        sectionController: sectionController
      ) as? CollectionViewContainerCell
    else {
      return nil
    }

    updateHandler(cell.cellView as! T)
    return cell
  }
}
