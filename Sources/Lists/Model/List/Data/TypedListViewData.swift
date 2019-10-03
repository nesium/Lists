//
//  TypedListViewData.swift
//  NSMForms
//
//  Created by Marc Bauer on 30.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import IGListKit
import NSMFoundation
import RxSwift

public struct TypedListViewData<ItemValue>: ListViewData {
  public let sectionData: Observable<[ListDiffable]>

  public init(sectionData observable: Observable<[SectionData<ItemValue>]>) {
    self.sectionData = observable.map { sectionDataList in
      sectionDataList.map { sectionData in
        DiffableSectionDataBox(sectionData, diffWitness: .sectionData())
      }
    }
  }

  public init(
    items: Observable<[ItemValue]>,
    sectionDataMapper: @escaping ([ItemValue]) -> [SectionData<ItemValue>]
  ) {
    self.init(sectionData: items.map { sectionDataMapper($0) })
  }

  public init<Style: CellStyle, Cell: AbstractCell<ItemValue, Style>>(
    items: Observable<[ItemValue]>,
    diffWitness: Diffing<ItemValue>,
    cellClass: Cell.Type,
    cellStyle: Style,
    listViewStyle: TableViewStyle,
    flowLayoutStyle: FlowLayoutStyle? = nil
  ) {
    self.init(
      items: items,
      diffWitness: diffWitness,
      itemToCellTransformer: { $0 },
      cellClass: cellClass,
      cellStyle: cellStyle,
      listViewStyle: listViewStyle,
      flowLayoutStyle: flowLayoutStyle
    )
  }

  public init<CellValue, Style: CellStyle, Cell: AbstractCell<CellValue, Style>>(
    items: Observable<[ItemValue]>,
    diffWitness: Diffing<ItemValue>,
    itemToCellTransformer: @escaping (ItemValue) -> (CellValue),
    cellClass: Cell.Type,
    cellStyle: Style,
    listViewStyle: TableViewStyle,
    flowLayoutStyle: FlowLayoutStyle? = nil
  ) {
    self.init(items: items) { values in
      guard !values.isEmpty else {
        return []
      }
      return [SectionData<ItemValue>(
        uniqueSectionIdentifier: "section-0",
        items: values,
        diffWitness: diffWitness,
        itemToCellTransformer: itemToCellTransformer,
        cellClass: cellClass,
        cellStyle: cellStyle,
        listViewStyle: listViewStyle,
        flowLayoutStyle: flowLayoutStyle
      )]
    }
  }

  public func controller(for sectionData: Any) -> ListSectionController {
    return SectionDataListSectionController()
  }
}
