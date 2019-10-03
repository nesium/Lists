//
//  SectionData.swift
//  NSMForms
//
//  Created by Marc Bauer on 27.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import Foundation
import IGListKit
import NSMUIKit

public enum SeparatorInsetReference {
  case fromCellEdges
  case fromAutomaticInsets
}

public struct SectionData<ItemValue> {
  public typealias CellMeasure = (
    _ value: ItemValue,
    _ index: Int,
    _ availableWidth: CGFloat
  ) -> CGSize

  public typealias CellUpdate = (
    _ provider: SectionDataCellProvider,
    _ value: ItemValue,
    _ index: Int
  ) -> ()

  public typealias CellSeparator = (
    _ value: ItemValue,
    _ index: Int,
    _ numberOfItems: Int
  ) -> (style: LineStyle, inset: UIEdgeInsets, reference: SeparatorInsetReference)?

  public let items: [ItemValue]
  public let headerData: SectionHeaderFooterData?
  public let footerData: SectionHeaderFooterData?

  internal let uniqueSectionIdentifier: String

  private let diffWitness: Diffing<ItemValue>
  private let cellMeasure: CellMeasure
  private let cellUpdate: CellUpdate
  private let cellSeparator: CellSeparator

  private let cellProvider = SectionDataCellProvider()

  // MARK: - Initialization -

  public init(
    uniqueSectionIdentifier: String,
    items: [ItemValue],
    diffWitness: Diffing<ItemValue>,
    headerData: SectionHeaderFooterData? = nil,
    footerData: SectionHeaderFooterData? = nil,
    cellSeparator: @escaping CellSeparator,
    cellMeasure: @escaping CellMeasure,
    cellUpdate: @escaping CellUpdate,
    style: SectionStyle = .default
  ) {
    self.uniqueSectionIdentifier = uniqueSectionIdentifier
    self.items = items
    self.diffWitness = diffWitness
    self.headerData = headerData
    self.footerData = footerData
    self.cellSeparator = cellSeparator
    self.cellMeasure = cellMeasure
    self.cellUpdate = cellUpdate
    self.style = style
  }

  public init<CellValue, Style: CellStyle, Cell: AbstractCell<CellValue, Style>>(
    uniqueSectionIdentifier: String,
    items: [ItemValue],
    diffWitness: Diffing<ItemValue>,
    itemToCellTransformer: @escaping (ItemValue) -> (CellValue),
    cellClass: Cell.Type,
    cellStyle: Style,
    listViewStyle: TableViewStyle,
    headerData: SectionHeaderFooterData? = nil,
    footerData: SectionHeaderFooterData? = nil,
    flowLayoutStyle: FlowLayoutStyle? = nil
  ) {
    let style = SectionStyle(
      inset: flowLayoutStyle?.sectionInset ?? .zero,
      minimumInteritemSpacing: flowLayoutStyle?.minimumInteritemSpacing ?? 0,
      minimumLineSpacing: flowLayoutStyle?.minimumLineSpacing ?? 0,
      backgroundColor: flowLayoutStyle?.backgroundColor
    )

    let rowHeight = cellStyle.rowHeight + (listViewStyle.separator?.thickness ?? 0)

    let cellMeasure: CellMeasure = { _, idx, availableWidth in
      let proposedSize = CGSize(width: availableWidth, height: rowHeight)
      guard let handler = flowLayoutStyle?.itemSizeHandler else {
        return proposedSize
      }
      return handler(idx, items.count, proposedSize, availableWidth)
    }

    let cellSeparator = flowLayoutStyle?.separatorVisibilityHandler.map { handler in
      SectionData.defaultCellSeparatorHandler(
        style: listViewStyle.separator,
        inset: cellStyle.separatorInset,
        reference: .fromCellEdges,
        visibilityHandler: handler
      )
    } ?? SectionData.defaultCellSeparatorHandler(
      style: listViewStyle.separator,
      inset: cellStyle.separatorInset,
      reference: .fromCellEdges
    )

    self.init(
      uniqueSectionIdentifier: uniqueSectionIdentifier,
      items: items,
      diffWitness: diffWitness,
      headerData: headerData,
      footerData: footerData,
      cellSeparator: cellSeparator,
      cellMeasure: cellMeasure,
      cellUpdate: { provider, value, _ in
        provider.updateCell(cellClass) { cell in
          cell.applyValue(itemToCellTransformer(value), style: cellStyle)
        }
      },
      style: style
    )
  }

  public static func ==(lhs: SectionData, rhs: SectionData) -> Bool {
    // We do not reload sections for changed items, since the diffing is done inside the
    // SectionDataListSectionController
    return
      lhs.uniqueSectionIdentifier == rhs.uniqueSectionIdentifier &&
      lhs.headerData == rhs.headerData &&
      lhs.footerData == rhs.footerData
  }

  // MARK: - SectionDataType Protocol -

  var header: SectionHeaderFooterDataType? {
    return self.headerData
  }

  var footer: SectionHeaderFooterDataType? {
    return self.footerData
  }

  var numberOfItems: Int {
    return self.items.count
  }

  let style: SectionStyle

  func diffableItems() -> [ListDiffable] {
    return self.items.map {
      DiffableBox(value: $0, diffing: self.diffWitness)
    }
  }

  func sizeForItem(at index: Int, availableWidth: CGFloat) -> CGSize {
    let requiredSize = self.cellMeasure(self.items[index], index, availableWidth)
    return CGSize(
      width: UIScreen.nsm_ceil(requiredSize.width),
      height: UIScreen.nsm_ceil(requiredSize.height)
    )
  }

  internal func cellForItem(
    at index: Int,
    context: ListCollectionContext,
    sectionController: ListSectionController
  ) -> UICollectionViewCell {
    let value = self.items[index]

    self.cellProvider.set(
      mode: .dequeue,
      index: index,
      context: context,
      sectionController: sectionController
    )
    self.cellUpdate(self.cellProvider, value, index)

    guard let cell = self.cellProvider.cell else {
      fatalError("SectionDataCellProvider.updateCell must be called at least once per config operation")
    }

    self.cellProvider.reset()

    if let separator = self.cellSeparator(value, index, self.items.count) {
      cell.applySeparatorStyle(
        separator.style,
        insets: separator.inset,
        reference: separator.reference
      )
    } else {
      cell.applySeparatorStyle(nil)
    }

    return cell
  }

  func updateCell(
    at index: Int,
    withDataFrom dataIndex: Int,
    context: ListCollectionContext,
    sectionController: ListSectionController
  ) {
    let value = self.items[dataIndex]

    self.cellProvider.set(
      mode: .update,
      index: index,
      context: context,
      sectionController: sectionController
    )
    self.cellUpdate(self.cellProvider, value, index)

    if let cell = self.cellProvider.cell {
      if let separator = self.cellSeparator(value, index, self.items.count) {
        cell.applySeparatorStyle(
          separator.style,
          insets: separator.inset,
          reference: separator.reference
        )
      } else {
        cell.applySeparatorStyle(nil)
      }
    }

    self.cellProvider.reset()
  }

  func updateSeparators(
    in context: ListCollectionContext,
    sectionController: ListSectionController
  ) {
    context.visibleIndexPaths(for: sectionController).forEach { indexPath in
      guard let cell = context.cellForItem(
        at: indexPath.item,
        sectionController: sectionController
      ) as? CollectionViewContainerCell
      else {
        return
      }

      let value = self.items[indexPath.item]
      if let separator = self.cellSeparator(value, indexPath.item, self.items.count) {
        cell.applySeparatorStyle(
          separator.style,
          insets: separator.inset,
          reference: separator.reference
        )
      } else {
        cell.applySeparatorStyle(nil)
      }
    }
  }
}


extension SectionData: SectionDataType {}


extension SectionData {
  public static func defaultCellSeparatorHandler(
    style: LineStyle?,
    inset: UIEdgeInsets,
    reference: SeparatorInsetReference
  ) -> CellSeparator {
    return self.defaultCellSeparatorHandler(
      style: style,
      inset: inset,
      reference: reference
    ) { idx, numberOfItems in
      return idx < numberOfItems - 1
    }
  }

  fileprivate static func defaultCellSeparatorHandler(
    style: LineStyle?,
    inset: UIEdgeInsets,
    reference: SeparatorInsetReference,
    visibilityHandler: @escaping FlowLayoutStyle.SeparatorVisibilityHandler
  ) -> CellSeparator {
    guard let style = style else {
      return { _, _, _ in .none }
    }

    return { _, index, numberOfItems in
      if visibilityHandler(index, numberOfItems) {
        return (style, inset, reference)
      }
      return nil
    }
  }
}
