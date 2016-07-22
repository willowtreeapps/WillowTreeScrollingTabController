//
//  ContainerViewController.swift
//  ScrollingTabControllerExample
//
//  Created by Erik LaManna on 2/25/16.
//  Copyright © 2016 WillowTree, Inc. All rights reserved.
//

import UIKit
import ScrollingTabController

class ContainerViewController: UIViewController {

    var scrollTab = ScrollingTabController()
    
    var viewControllers: [UIViewController] = []
    
    @IBOutlet var scrollContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollTab.delegate = self
        
        buildViewControllers()
        scrollTab.willMoveToParentViewController(self)
        addChildViewController(scrollTab)
        scrollTab.viewControllers = viewControllers
        scrollTab.view.translatesAutoresizingMaskIntoConstraints = false
        
        scrollContainer.addSubview(scrollTab.view)
    
        let horizontal = NSLayoutConstraint.constraintsWithVisualFormat("|[view]|", options: [], metrics: nil, views: ["view": scrollTab.view])
        let vertical = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: ["view": scrollTab.view])
        NSLayoutConstraint.activateConstraints(horizontal + vertical)
        
        scrollTab.didMoveToParentViewController(self)
        
        scrollTab.tabView.tabSizing = .fitViewFrameWidth
        // Do any additional setup after loading the view.
    }
    
    func buildViewControllers() {
        for i in 1...3 {
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
            
            viewControllers.append(viewController)
        }
    }
}

extension ContainerViewController: ScrollingTabControllerDelegate {
    func scrollingTabController(tabController: ScrollingTabController, displayedViewControllerAtIndex index: Int) {
        print("Index \(index) displayed")
    }
}