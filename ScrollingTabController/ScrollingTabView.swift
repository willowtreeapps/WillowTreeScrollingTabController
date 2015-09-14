//
//  ScrollingTabView.swift
//  ScrollingTabControllerExample
//
//  Created by Erik LaManna on 9/4/15.
//  Copyright © 2015 WillowTree, Inc. All rights reserved.
//

import UIKit

public let ScrollingTabVerticalDividerType = "VerticalDivider"
public let ScrollingTabTitleCell = "TabCell"

public class ScrollingTabViewFlowLayout: UICollectionViewFlowLayout {

    public var topDividerMargin: CGFloat = 10.0
    public var bottomDividerMargin: CGFloat = 10.0
    public var dividerWidth: CGFloat = 1.0
    public var dividerColor: UIColor = UIColor.blackColor()
    public var showDivider: Bool = false
    
    override init() {
        super.init()
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        self.sectionInset = UIEdgeInsetsZero
        self.minimumInteritemSpacing = 0
        self.minimumLineSpacing = 0
        self.itemSize = CGSizeMake(100, 30.0)
        self.scrollDirection = .Horizontal
    }
    
    override public func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = self.layoutAttributesForItemAtIndexPath(indexPath)
        let dividerAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: ScrollingTabVerticalDividerType, withIndexPath: indexPath)
        
        if let attributes = attributes, collectionView = self.collectionView {
            dividerAttributes.frame = CGRectMake(CGRectGetMaxX(attributes.frame),
                self.topDividerMargin,
                self.dividerWidth,
                CGRectGetHeight(collectionView.frame) - self.topDividerMargin - self.bottomDividerMargin)
        }
        
        dividerAttributes.zIndex = -1
        
        return dividerAttributes
    }

    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElementsInRect(rect) else {
            return nil
        }
        
        var updatedAttributes = attributes
        
        if self.showDivider {
            for layoutAttribute in attributes {
                if (layoutAttribute.representedElementCategory == .Cell) {
                    if let dividerAttribute = self.layoutAttributesForDecorationViewOfKind(ScrollingTabVerticalDividerType,
                        atIndexPath: layoutAttribute.indexPath) {
                            updatedAttributes.append(dividerAttribute)
                    }
                }
            }
        }
        
        return updatedAttributes
    }
}

public class ScrollingTabDivider: UICollectionReusableView {
   
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        self.backgroundColor = UIColor.blackColor()
    }
}

public class ScrollingTabView: UICollectionView {
    
    public var selectionIndicatorOffset: CGFloat = 40
    public var selectionIndicator: UIView!
    public var selectionIndicatorHeight: CGFloat = 5
    public var selectionIndicatorEdgeInsets: UIEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5)
    
    var selectionIndicatorLeadingConstraint: NSLayoutConstraint!
    var selectionIndicatorBottomConstraint: NSLayoutConstraint!
    var selectionIndicatorHeightConstraint: NSLayoutConstraint!
    var selectionIndicatorWidthConstraint: NSLayoutConstraint!
    
    public convenience init()
    {
        self.init(frame: CGRectZero, collectionViewLayout: ScrollingTabViewFlowLayout())
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        self.backgroundColor = UIColor.whiteColor()
    
        self.selectionIndicator = UIView()
        self.selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.selectionIndicator.backgroundColor = self.selectionIndicator.tintColor
        self.addSubview(self.selectionIndicator)
        self.selectionIndicatorBottomConstraint = NSLayoutConstraint(item: self.selectionIndicator, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: self.selectionIndicatorOffset)
        self.selectionIndicatorLeadingConstraint = NSLayoutConstraint(item: self.selectionIndicator, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
        self.selectionIndicatorHeightConstraint = NSLayoutConstraint(item: self.selectionIndicator, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: self.selectionIndicatorHeight)
        self.selectionIndicatorWidthConstraint = NSLayoutConstraint(item: self.selectionIndicator, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 100)
        
        NSLayoutConstraint.activateConstraints([self.selectionIndicatorBottomConstraint, self.selectionIndicatorLeadingConstraint, self.selectionIndicatorHeightConstraint, self.selectionIndicatorWidthConstraint])
        
        self.registerClass(ScrollingTabCell.classForCoder(), forCellWithReuseIdentifier: ScrollingTabTitleCell)
        self.collectionViewLayout.registerClass(ScrollingTabDivider.classForCoder(), forDecorationViewOfKind: ScrollingTabVerticalDividerType)
        
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.bringSubviewToFront(self.selectionIndicator)
    }
    
    public func panToPercentage(percentage: CGFloat) {
        
        let tabCount = self.numberOfItemsInSection(0)
        let percentageInterval = CGFloat(1.0 / Double(tabCount))
        
        let firstItem = floorf(Float(percentage / percentageInterval))
        let secondItem = firstItem + 1

        var firstPath: NSIndexPath?
        var secondPath: NSIndexPath?
        
        if (firstItem < 0)
        {
            firstPath = NSIndexPath(forItem: 0, inSection: 0)
            secondPath = firstPath
        }
        else if (Int(firstItem) >= tabCount) {
            firstPath = NSIndexPath(forItem: tabCount - 1, inSection: 0)
            secondPath = firstPath
        }
        else
        {
            firstPath = NSIndexPath(forItem: Int(firstItem), inSection: 0)
            if (secondItem < 0) {
                secondPath = NSIndexPath(forItem: 0, inSection: 0)
            } else if (Int(secondItem) >= tabCount) {
                secondPath = NSIndexPath(forItem: tabCount - 1, inSection: 0)
            }
            else {
                secondPath = NSIndexPath(forItem: Int(secondItem), inSection: 0)
            }
        }
        
        
        let shareSecond = percentage + percentageInterval - CGFloat(secondItem) * percentageInterval
        let shareFirst = percentageInterval - shareSecond
        let percentFirst = shareFirst / percentageInterval
        let percentSecond = shareSecond / percentageInterval
        
        let selectIndexPath = percentFirst >= 0.5 ? firstPath : secondPath
        self.selectItemAtIndexPath(selectIndexPath, animated: false, scrollPosition: .None)

        let attrs1 = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(firstPath!)
        let attrs2 = self.collectionViewLayout.layoutAttributesForItemAtIndexPath(secondPath!)
        
        let firstFrame = attrs1?.frame
        let secondFrame = attrs2?.frame
        
        var x = CGRectGetWidth(firstFrame!) * percentSecond + CGRectGetMinX(firstFrame!)
        if firstItem < 0 {
            x -= CGRectGetWidth(firstFrame!)
        }

        let width = CGRectGetWidth(firstFrame!) * percentFirst + CGRectGetWidth(secondFrame!) * percentSecond
        
        self.selectionIndicatorLeadingConstraint.constant = x + self.selectionIndicatorEdgeInsets.left
        self.selectionIndicatorWidthConstraint.constant = width - self.selectionIndicatorEdgeInsets.left - self.selectionIndicatorEdgeInsets.right
        
        if x > (CGRectGetWidth(self.frame) / 2.0) - (width / 2.0) {
            
            if (x < self.contentSize.width - (CGRectGetWidth(self.frame) / 2.0) - (width / 2.0)) {
                self.contentOffset = CGPointMake(x - (CGRectGetWidth(self.frame) / 2 - width / 2.0), 0)
            }
            
        }
    }
    

}
