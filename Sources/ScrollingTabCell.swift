//
//  ScrollingTabCell.swift
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

/**
 * Default tab cell implementation for the tab controller
 */
public class ScrollingTabCell: UICollectionViewCell {
    
    /// Title label shown in the cell.
    public var titleLabel: UILabel!
    
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    public override var selected: Bool {
        didSet {
            if selected {
                titleLabel.textColor = tintColor
            } else {
                titleLabel.textColor = UIColor.darkTextColor()
            }
        }
    }
    
    public override var highlighted: Bool {
        didSet {
            if highlighted {
                titleLabel.textColor = tintColor
            } else {
                titleLabel.textColor = UIColor.darkTextColor()
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        
        backgroundColor = UIColor.clearColor()
        
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .Center
        contentView.addSubview(titleLabel)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|-[view]-|",
            options: NSLayoutFormatOptions(rawValue:0),
            metrics: nil,
            views: ["view": titleLabel])
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-[view]-|",
            options: NSLayoutFormatOptions(rawValue:0),
            metrics: nil,
            views: ["view": titleLabel])
        titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)

        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
}
