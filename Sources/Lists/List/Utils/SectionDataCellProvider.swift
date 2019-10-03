//
//  SectionDataCellProvider.swift
//  NSMForms
//
//  Created by Marc Bauer on 21.11.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import IGListKit

public final class SectionDataCellProvider {
  internal enum Mode {
    case update
    case dequeue
  }

  internal var cell: CollectionViewContainerCell?

  private var updateCellCalled = false

  private var mode: Mode!
  private var index: Int!
  private var context: ListCollectionContext!
  private var sectionController: ListSectionController!

  internal init() {}

  internal func set(
    mode: Mode,
    index: Int,
    context: ListCollectionContext,
    sectionController: ListSectionController
  ) {
    self.mode = mode
    self.index = index
    self.context = context
    self.sectionController = sectionController
  }

  internal func reset() {
    self.updateCellCalled = false
    self.cell = nil
    self.mode = nil
    self.index = nil
    self.context = nil
    self.sectionController = nil
  }

  // MARK: - Public Methods -

  public func updateCell<Cell: ListCell>(_ type: Cell.Type, handler: (Cell) -> ()) {
    precondition(
      !self.updateCellCalled,
      "\(#function) can only be called once per config operation."
    )

    self.updateCellCalled = true

    switch self.mode! {
      case .dequeue:
        self.cell = self.context.w2_dequeueAndUpdateReusableCell(
          of: Cell.self,
          for: self.sectionController,
          at: self.index,
          updateHandler: handler
        )

      case .update:
        self.cell = self.context.w2_updateCellForItem(
          Cell.self,
          at: self.index,
          sectionController: self.sectionController,
          updateHandler: handler
        )
    }
  }
}
