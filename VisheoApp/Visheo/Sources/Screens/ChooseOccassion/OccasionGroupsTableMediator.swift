//
//  OccasionGroupsTableMediator.swift
//  Visheo
//
//  Created by Ivan on 3/26/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import Foundation
import UIKit

enum CellIdentifiers : String {
    case featured = "FeaturedOccasionsTableCell"
    case standard = "StandardOccasionsTableCell"
}

class OccasionGroupsTableMediator : NSObject, UITableViewDelegate, UITableViewDataSource {
    var viewModel: ChooseOccasionViewModel
    var tableView: UITableView
    
    init(withViewModel viewModel: ChooseOccasionViewModel, tableView: UITableView, occasionGroups: [OccasionGroup]) {
        self.tableView  = tableView
        self.viewModel  = viewModel
        
        super.init()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.occasionGroupsCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = viewModel.occasionGroups[indexPath.row]
        switch group.type {
            case .featured:
                return featuredCell(forOccasionAtIndex: indexPath.row)
            case .standard:
                return standardCell(forOccasionAtIndex: indexPath.row)
        }
    }

    func featuredCell(forOccasionAtIndex index: Int) -> FeaturedOccasionsTableCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.featured.rawValue) as! FeaturedOccasionsTableCell
        let group = viewModel.occasionGroups[index]
        let viewModelForGroup = VisheoFeaturedOccasionsTableCellViewModel(withTitle: group.title, subTitle: group.subTitle, occasions: group.occasions) { [weak self] in
            self?.viewModel.selectOccasion(withOccasion:$0)
        }
        let mediator = HolidaysCollectionMediator(viewModel: viewModelForGroup, holidaysCollection: cell.holidaysCollection, containerWidth:tableView.frame.size.width)
        cell.configure(withModel: viewModelForGroup, mediator: mediator)
        return cell
    }
    
    func standardCell(forOccasionAtIndex index: Int) -> StandardOccasionsTableCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.standard.rawValue) as! StandardOccasionsTableCell
        let group = viewModel.occasionGroups[index]
        let viewModelForGroup = VisheoStandardOccasionsTableCellViewModel(withTitle: group.title, occasions: group.occasions) { [weak self] in
            self?.viewModel.selectOccasion(withOccasion: $0)
        }
        let mediator = OccassionsCollectionMediator(viewModel: viewModelForGroup, occasionsCollection: cell.occasionsCollection)
        cell.configure(withModel: viewModelForGroup, mediator: mediator)
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let group = viewModel.occasionGroups[indexPath.row]
        switch group.type {
        case .featured:
            return VisheoFeaturedOccasionsTableCellViewModel.height(forWidth: tableView.frame.size.width)
        case .standard:
            return VisheoStandardOccasionsTableCellViewModel.height
        }
    }
}
