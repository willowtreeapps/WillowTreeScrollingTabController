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
        scrollTab.willMove(toParentViewController: self)
        addChildViewController(scrollTab)
        scrollTab.injectInitialViewControllers(viewControllers)
        scrollTab.view.translatesAutoresizingMaskIntoConstraints = false
        
        scrollContainer.addSubview(scrollTab.view)
        scrollContainer.layoutIfNeeded()
    
        let horizontal = NSLayoutConstraint.constraints(withVisualFormat: "|[view]|", options: [], metrics: nil, views: ["view": scrollTab.view])
        let vertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view": scrollTab.view])
        NSLayoutConstraint.activate(horizontal + vertical)
        
        scrollTab.didMove(toParentViewController: self)
        
        scrollTab.tabView.tabSizing = .fitViewFrameWidth
        scrollTab.selectTab(atIndex: 1, animated: false)
        // Do any additional setup after loading the view.
    }

    func buildViewControllers() {
        for i in 1...3 {
            let viewController = TestingViewController()
            
            var color = UIColor.white
            switch i % 5 {
            case 0:
                color = UIColor.red
            case 1:
                color = UIColor.blue
            case 2:
                color = UIColor.green
            case 3:
                color = UIColor.orange
            case 4:
                color = UIColor.purple
            default:
                color = UIColor.white
            }
            viewController.view.backgroundColor = color
            viewController.itemTextLabel.text = "\(i)"
            viewController.tabBarItem.title = "VC \(i)"
            
            viewControllers.append(viewController)
        }
    }
}

extension ContainerViewController: ScrollingTabControllerDelegate {
    func scrollingTabController(_ tabController: ScrollingTabController, displayedViewControllerAtIndex index: Int) {
        print("Index \(index) displayed")
    }
}
