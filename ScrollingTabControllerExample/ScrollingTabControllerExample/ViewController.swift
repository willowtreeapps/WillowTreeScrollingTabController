//
//  ViewController.swift
//  ScrollingTabControllerExample
//
//  Copyright (c) 2016 WillowTree, Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


import UIKit
import ScrollingTabController

class ViewController: ScrollingTabController {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.buildViewControllers()
        self.tabSizing = .sizeToContent
        self.tabView.centerSelectTabs = true

        let nextBarButtonItem = UIBarButtonItem(barButtonSystemItem: .FastForward, target: self, action: #selector(jumpAhead))
        let previousBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Rewind, target: self, action: #selector(jumpBack))
        navigationItem.rightBarButtonItems = [nextBarButtonItem, previousBarButtonItem]
    }

    func jumpAhead() {
        var page = currentPage + 1
        if page == viewControllers.count {
            page = 0
        }
        selectTab(atIndex: page)
    }

    func jumpBack() {
        var page = currentPage - 1
        if page < 0 {
            page = viewControllers.count - 1
        }
        selectTab(atIndex: page)
    }
    
    func buildViewControllers() {
        for i in 1...10 {
            let viewController = TestingViewController()
            
            viewController.tabBarItem.title = "VC \(i)"
            viewController.itemTextLabel.text = "\(i)"
            
            var color = UIColor.whiteColor()
            switch i % 5 {
            case 0:
                color = UIColor.redColor()
            case 1:
                color = UIColor.blueColor()
                viewController.tabBarItem.title = "REALLY LONG VC NAME \(i)"
            case 2:
                color = UIColor.greenColor()
            case 3:
                color = UIColor.orangeColor()
            case 4:
                color = UIColor.purpleColor()
                viewController.tabBarItem.title = "LONG VC NAME \(i)"
            default:
                color = UIColor.whiteColor()
            }
            viewController.backgroundColor = color
            
            
            self.viewControllers.append(viewController)
        }
    }
}

class TestingViewController: UIViewController {
    
    var itemTextLabel = UILabel(frame: CGRectZero)
    var backgroundColor: UIColor = UIColor.purpleColor()

    override func viewDidLoad() {
        view.backgroundColor = backgroundColor
        self.view.addSubview(itemTextLabel)

        print("Did Load \(itemTextLabel.text)")
        
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
        print("Will appear \(itemTextLabel.text)")
        usleep(1000)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        print("Did appear \(itemTextLabel.text)")
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        print("Will disappear \(itemTextLabel.text)")
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        print("Did disappear \(itemTextLabel.text)")
    }
}