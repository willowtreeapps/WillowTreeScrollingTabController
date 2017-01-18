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
    
    @IBOutlet weak var scrollContainer: UIView!
    @IBOutlet weak var scrollTabModeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var centerSelectSwitch: UISwitch!
    @IBOutlet weak var numberOfViewsLabel: UILabel!
    @IBOutlet weak var viewCountStepper: UIStepper!
    
    let tabSizingMapping: [ScrollingTabView.TabSizing] = [.fitViewFrameWidth, .fixedSize(200), .sizeToContent, .flexibleWidth]
    var viewControllerCount = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()

        buildViewControllers()
        setupScrollTab()
        // Do any additional setup after loading the view.
        
        setupScrollTabModeSegmentedControl()
        viewCountStepper.value = Double(viewControllerCount)
    }
    
    func setupScrollTabModeSegmentedControl() {
        scrollTabModeSegmentedControl.removeAllSegments()
        scrollTabModeSegmentedControl.insertSegment(withTitle: "fitViewFrameWidth", at: 0, animated: false)
        scrollTabModeSegmentedControl.insertSegment(withTitle: "fixedSize(200)", at: 1, animated: false)
        scrollTabModeSegmentedControl.insertSegment(withTitle: "sizeToContent", at: 2, animated: false)
        scrollTabModeSegmentedControl.insertSegment(withTitle: "flexibleWidth", at: 3, animated: false)
        
        scrollTabModeSegmentedControl.selectedSegmentIndex = 0
    }
    
    func setupScrollTab() {
        scrollTab.delegate = self
        scrollTab.willMove(toParentViewController: self)
        addChildViewController(scrollTab)
        scrollTab.viewControllers = viewControllers
        scrollTab.view.translatesAutoresizingMaskIntoConstraints = false
        scrollContainer.addSubview(scrollTab.view)
        scrollContainer.layoutIfNeeded()
        
        let horizontal = NSLayoutConstraint.constraints(withVisualFormat: "|[view]|", options: [], metrics: nil, views: ["view": scrollTab.view])
        let vertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view": scrollTab.view])
        NSLayoutConstraint.activate(horizontal + vertical)
        
        scrollTab.didMove(toParentViewController: self)
        scrollTab.centerSelectTabs = centerSelectSwitch.isOn
    }
    
    func buildViewControllers() {
        viewControllers.removeAll()
        for i in 1...viewControllerCount {
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
    
    @IBAction func segmentedControlDidChange(_ segmentedControl: UISegmentedControl) {
        let tabSizing = tabSizingMapping[segmentedControl.selectedSegmentIndex]
        scrollTab.tabSizing = tabSizing
        scrollTab.selectTab(atIndex: 0, animated: true)
    }

    @IBAction func centerSelectSwitchChanged(_ sender: UISwitch) {
        scrollTab.centerSelectTabs = sender.isOn
        scrollTab.selectTab(atIndex: 0, animated: true)
    }
    
    @IBAction func stepperValueChanged(_ stepper: UIStepper) {
        viewControllerCount = Int(stepper.value)
        buildViewControllers()
        scrollTab.view.removeFromSuperview()
        scrollTab.removeFromParentViewController()
        scrollTab = ScrollingTabController()
        setupScrollTab()
        scrollTab.selectTab(atIndex: 0, animated: true)
    }
}

extension ContainerViewController: ScrollingTabControllerDelegate {
    func scrollingTabController(_ tabController: ScrollingTabController, displayedViewControllerAtIndex index: Int) {
        print("Index \(index) displayed")
    }
}
