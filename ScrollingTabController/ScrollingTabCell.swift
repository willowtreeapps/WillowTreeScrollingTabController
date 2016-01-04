//
//  ScrollingTabCell.swift
//  ScrollingTabControllerExample
//
//  Copyright (c) 2015 WillowTree, Inc.
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
