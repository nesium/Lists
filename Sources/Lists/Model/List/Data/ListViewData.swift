//
//  ListViewData.swift
//  NSMForms
//
//  Created by Marc Bauer on 30.11.17.
//  Copyright © 2017 nesiumdotcom. All rights reserved.
//

import IGListKit
import RxSwift

public protocol ListViewData {
  var sectionData: Observable<[ListDiffable]> { get }
  func controller(for sectionData: Any) -> ListSectionController
}
