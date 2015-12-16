//
//  ViewController.swift
//  ScrollingTabControllerExample
//
//  Created by Erik LaManna on 9/2/15.
//  Copyright © 2015 WillowTree, Inc. All rights reserved.
//

import UIKit
import ScrollingTabController

class ViewController: ScrollingTabController, ScrollingTabControllerDataSource {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.buildViewControllers()
        self.dataSource = self
//        self.sizeTabItemsToFit = true
        self.tabView.centerSelectTabs = true
    }
    
    func buildViewControllers() {
        for i in 1...10 {
            let viewController = TestingViewController()
            
            var color = UIColor.whiteColor()
            switch i % 5 {
            case 0:
                color = UIColor.redColor()
            case 1:
                color = UIColor.blueColor()
            case 2:
                color = UIColor.greenColor()
            case 3:
                color = UIColor.orangeColor()
            case 4:
                color = UIColor.purpleColor()
            default:
                color = UIColor.whiteColor()
            }
            viewController.view.backgroundColor = color
            viewController.itemTextLabel.text = "\(i)"
            viewController.tabBarItem.title = "VC \(i)"
            
            self.viewControllers.append(viewController)
        }
    }
    
    internal func tabView(tabView: ScrollingTabController, configureTitleCell cell: UICollectionViewCell, atIndex index: Int) -> UICollectionViewCell {
        guard let tabCell = cell as? ScrollingTabCell else {
            return cell
        }
        
        tabCell.titleLabel.text = "Item \(index)"
        
        return tabCell
    }
}

class TestingViewController: UIViewController {
    
    var itemTextLabel = UILabel(frame: CGRectZero)

    override func viewDidLoad() {
        self.view.addSubview(itemTextLabel)
        
        self.itemTextLabel.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
        self.itemTextLabel.textColor = UIColor.blackColor()
        self.itemTextLabel.font = UIFont.systemFontOfSize(100)
        self.itemTextLabel.translatesAutoresizingMaskIntoConstraints = false
        let horizontal = NSLayoutConstraint(item: itemTextLabel, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
        let vertical = NSLayoutConstraint(item: itemTextLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self.view, attribute: .CenterY, multiplier: 1.0, constant: 0.0)
        
        NSLayoutConstraint.activateConstraints([horizontal, vertical])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        usleep(1000)
    }
}