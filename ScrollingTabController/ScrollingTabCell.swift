//
//  ScrollingTabCell.swift
//  ScrollingTabControllerExample
//
//  Created by Erik LaManna on 9/4/15.
//  Copyright © 2015 WillowTree, Inc. All rights reserved.
//

import UIKit

/**
 * Default tab cell implementation for the tab controller
 */
class ScrollingTabCell: UICollectionViewCell {
    
    /// Title label shown in the cell.
    var titleLabel: UILabel!
    
    override var selected: Bool {
        didSet {
            if selected {
                self.titleLabel.textColor = self.tintColor
            } else {
                self.titleLabel.textColor = UIColor.darkTextColor()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        
        self.backgroundColor = UIColor.clearColor()
        
        self.titleLabel = UILabel()
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.textAlignment = .Center
        self.contentView.addSubview(self.titleLabel)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|-[view]-|",
            options: NSLayoutFormatOptions(rawValue:0),
            metrics: nil,
            views: ["view": self.titleLabel])
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-[view]-|",
            options: NSLayoutFormatOptions(rawValue:0),
            metrics: nil,
            views: ["view": self.titleLabel])
        
        self.contentView.addConstraints(horizontalConstraints)
        self.contentView.addConstraints(verticalConstraints)
    }
}
