//
//  SectionHeaderFooterData.swift
//  NSMForms
//
//  Created by Marc Bauer on 21.11.18.
//  Copyright © 2018 nesiumdotcom. All rights reserved.
//

import IGListKit

public struct SectionHeaderFooterData: Equatable {
  private let reusableView: (
    String,
    Int,
    ListCollectionContext,
    ListSectionController
  ) -> UICollectionReusableView

  private let uniqueIdentifier: String
  private let configurationHandler: ((UICollectionReusableView, Int) -> ())?

  public init<Value, Style: HeaderFooterViewStyle, View: AbstractHeaderFooterView<Value, Style>>(
    value: Value,
    viewClass: View.Type,
    viewStyle: Style,
    uniqueIdentifier: String,
    configurationHandler: ((View, _ sectionIndex: Int) -> ())? = nil
  ) {
    self.height = viewStyle.rowHeight
    self.reusableView = { kind, idx, ctx, ctrl in
      guard let containerView = ctx.dequeueReusableSupplementaryView(
        ofKind: kind,
        for: ctrl,
        class: CollectionHeaderFooterContainerView<Value, Style>.self,
        at: idx
      ) as? CollectionHeaderFooterContainerView<Value, Style>
      else {
        fatalError("Dequeueing supplementaryView failed.")
      }

      if containerView.contentView == nil {
        containerView.contentView = viewClass.init(frame: .zero)
      }

      containerView.applyValue(value, style: viewStyle)
      configurationHandler?((containerView.contentView as! View), ctrl.section)
      return containerView
    }

    self.configurationHandler = configurationHandler.map { handler in
      return { reusableView, sectionIdx in
        guard let containerView = reusableView as?
          CollectionHeaderFooterContainerView<Value, Style>
        else {
          return
        }
        handler(containerView.contentView as! View, sectionIdx)
      }
    }

    self.uniqueIdentifier = uniqueIdentifier
  }

  public static func ==(lhs: SectionHeaderFooterData, rhs: SectionHeaderFooterData) -> Bool {
    return lhs.uniqueIdentifier == rhs.uniqueIdentifier
  }

  // MARK: - SectionHeaderFooterDataType Protocol -

  internal let height: CGFloat

  internal func view(
    ofKind elementKind: String,
    at index: Int,
    context: ListCollectionContext,
    sectionController: ListSectionController
  ) -> UICollectionReusableView {
    return self.reusableView(elementKind, index, context, sectionController)
  }

  /// This method is called by the `TypedListViewController` when the number of sections has
  /// changed, so that the visible headers and footers can be updated.
  ///
  /// - Parameters:
  ///   - view: The header or footer to be updated.
  ///   - section: The section in which the header or footer is displayed.
  internal func configure(view: UICollectionReusableView, in section: Int) {
    self.configurationHandler?(view, section)
  }
}


extension SectionHeaderFooterData: SectionHeaderFooterDataType {}
