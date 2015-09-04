//
//  ScrollingViewControllerCell.swift
//  ScrollingTabControllerExample
//
//  Created by Erik LaManna on 9/4/15.
//  Copyright © 2015 WillowTree, Inc. All rights reserved.
//

import UIKit

class ScrollingViewControllerCell: UICollectionViewCell {
    weak var viewController: UIViewController?
    weak var parentViewController: UIViewController?
    
    weak var snapshotView: UIView? {
        didSet {
            if let snapshotView = self.snapshotView {
                self.contentView.addSubview(snapshotView)
                let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[view]|",
                    options: NSLayoutFormatOptions(rawValue:0),
                    metrics: nil,
                    views: ["view": snapshotView])
                let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|",
                    options: NSLayoutFormatOptions(rawValue:0),
                    metrics: nil,
                    views: ["view": snapshotView])
                
                self.contentView.addConstraints(horizontalConstraints)
                self.contentView.addConstraints(verticalConstraints)
                self.contentView.layoutIfNeeded()
            }
        }
    }

    func loadViewController() {
        guard let viewController = self.viewController else {
            return
        }
        
        viewController.willMoveToParentViewController(self.parentViewController)
        self.parentViewController?.addChildViewController(viewController)
        
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(viewController.view)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[view]|",
            options: NSLayoutFormatOptions(rawValue:0),
            metrics: nil,
            views: ["view": viewController.view])
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|",
            options: NSLayoutFormatOptions(rawValue:0),
            metrics: nil,
            views: ["view": viewController.view])
        
        self.contentView.addConstraints(horizontalConstraints)
        self.contentView.addConstraints(verticalConstraints)
        self.contentView.layoutIfNeeded()
        
        self.snapshotView?.removeFromSuperview()
        viewController.didMoveToParentViewController(self.parentViewController)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        if let viewController = self.viewController{
            viewController.willMoveToParentViewController(nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParentViewController()
            self.viewController = nil
        }
        
        if let snapshot = self.snapshotView {
            snapshot.removeFromSuperview()
            self.snapshotView = nil
        }
    }
}
