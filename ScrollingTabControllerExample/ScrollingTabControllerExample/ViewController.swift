//
//  ViewController.swift
//  ScrollingTabControllerExample
//
//  Created by Erik LaManna on 9/2/15.
//  Copyright © 2015 WillowTree, Inc. All rights reserved.
//

import UIKit

class ViewController: ScrollingTabController, ScrollingTabControllerDataSource {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.buildViewControllers()
    }
    
    func buildViewControllers() {
        for i in 1...100 {
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
            
            self.viewControllers.append(viewController)
        }
    }
}

class TestingViewController: UIViewController {
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        usleep(1000)
    }
}