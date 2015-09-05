//
//  ScrollingTabCell.swift
//  ScrollingTabControllerExample
//
//  Created by Erik LaManna on 9/4/15.
//  Copyright © 2015 WillowTree, Inc. All rights reserved.
//

import UIKit

class ScrollingTabCell: UICollectionViewCell {
    
    var titleLabel: UILabel!
    var backgroundImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        self.titleLabel = UILabel()
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.titleLabel)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[view]|",
            options: NSLayoutFormatOptions(rawValue:0),
            metrics: nil,
            views: ["view": self.titleLabel])
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|",
            options: NSLayoutFormatOptions(rawValue:0),
            metrics: nil,
            views: ["view": self.titleLabel])
        
        self.contentView.addConstraints(horizontalConstraints)
        self.contentView.addConstraints(verticalConstraints)
    }
}
