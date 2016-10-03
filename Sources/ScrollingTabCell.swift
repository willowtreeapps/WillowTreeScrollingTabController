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
open class ScrollingTabCell: UICollectionViewCell {
    
    /// Title label shown in the cell.
    open var titleLabel: UILabel!
    
    open var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    open override var isSelected: Bool {
        didSet {
            if isSelected {
                titleLabel.textColor = tintColor
            } else {
                titleLabel.textColor = UIColor.darkText
            }
        }
    }
    
    open override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                titleLabel.textColor = tintColor
            } else {
                titleLabel.textColor = UIColor.darkText
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
        
        backgroundColor = UIColor.clear
        
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|-[view]-|",
            options: NSLayoutFormatOptions(rawValue:0),
            metrics: nil,
            views: ["view": titleLabel])
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[view]-|",
            options: NSLayoutFormatOptions(rawValue:0),
            metrics: nil,
            views: ["view": titleLabel])
        titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)

        NSLayoutConstraint.activate(horizontalConstraints + verticalConstraints)
    }
}
