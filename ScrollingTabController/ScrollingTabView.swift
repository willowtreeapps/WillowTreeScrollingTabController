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


public class ScrollingTabView: UIView {
    
    public var collectionView: UICollectionView!
    public var scrollingLayout: ScrollingTabViewFlowLayout!
    
    public var selectionIndicatorOffset: CGFloat = 0 {
        didSet {
            if self.selectionIndicatorBottomConstraint != nil {
                self.selectionIndicatorBottomConstraint.constant = selectionIndicatorOffset
            }
        }
    }
    
    public var selectionIndicator: UIView!
    
    public var selectionIndicatorHeight: CGFloat = 5 {
        didSet {
            if self.selectionIndicatorHeightConstraint != nil {
                self.selectionIndicatorHeightConstraint.constant = selectionIndicatorHeight
            }
        }
    }
    
    public var selectionIndicatorEdgeInsets: UIEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5)
    
    public var sizeTabsToFitWidth: Bool = false {
        didSet {
            if (sizeTabsToFitWidth) {
                self.calculateItemSizeToFitWidth(self.frame.width)
            }
        }
    }
    
    public var centerSelectTabs: Bool = false {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    var selectionIndicatorLeadingConstraint: NSLayoutConstraint!
    var selectionIndicatorBottomConstraint: NSLayoutConstraint!
    var selectionIndicatorHeightConstraint: NSLayoutConstraint!
    var selectionIndicatorWidthConstraint: NSLayoutConstraint!
    
    private var lastPercentage: CGFloat = 0
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    func setup() {
        self.backgroundColor = UIColor.whiteColor()
        
        self.scrollingLayout = ScrollingTabViewFlowLayout()
        self.collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: self.scrollingLayout)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.backgroundColor = UIColor.clearColor()
        self.addSubview(self.collectionView)
        
        let horizontalContstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[collectionView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["collectionView": self.collectionView])
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["collectionView": self.collectionView])
        
        NSLayoutConstraint.activateConstraints(horizontalContstraints)
        NSLayoutConstraint.activateConstraints(verticalConstraints)
        
        
        self.selectionIndicator = UIView()
        self.selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.selectionIndicator.backgroundColor = self.selectionIndicator.tintColor
        self.collectionView.addSubview(self.selectionIndicator)
        self.selectionIndicatorBottomConstraint = NSLayoutConstraint(item: self.selectionIndicator, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: self.selectionIndicatorOffset)
        self.selectionIndicatorLeadingConstraint = NSLayoutConstraint(item: self.selectionIndicator, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.collectionView, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
        self.selectionIndicatorHeightConstraint = NSLayoutConstraint(item: self.selectionIndicator, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: self.selectionIndicatorHeight)
        self.selectionIndicatorWidthConstraint = NSLayoutConstraint(item: self.selectionIndicator, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 100)
        
        NSLayoutConstraint.activateConstraints([self.selectionIndicatorBottomConstraint, self.selectionIndicatorLeadingConstraint, self.selectionIndicatorHeightConstraint, self.selectionIndicatorWidthConstraint])
        
        self.collectionView.registerClass(ScrollingTabCell.classForCoder(), forCellWithReuseIdentifier: ScrollingTabTitleCell)
        self.collectionView.collectionViewLayout.registerClass(ScrollingTabDivider.classForCoder(), forDecorationViewOfKind: ScrollingTabVerticalDividerType)
        
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.showsVerticalScrollIndicator = false
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.bringSubviewToFront(self.selectionIndicator)
        if self.centerSelectTabs {
            let inset = self.collectionView.frame.width / 2.0 - self.scrollingLayout.itemSize.width / 2.0
            self.collectionView.contentInset = UIEdgeInsetsMake(0, inset, 0, inset)
        }
    }
    
    public func panToPercentage(percentage: CGFloat) {
        
        lastPercentage = percentage
        
        let tabCount = self.collectionView.numberOfItemsInSection(0)
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
        self.collectionView.selectItemAtIndexPath(selectIndexPath, animated: false, scrollPosition: .None)

        let attrs1 = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(firstPath!)
        let attrs2 = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(secondPath!)
        
        let firstFrame = attrs1?.frame
        let secondFrame = attrs2?.frame
        
        var x = CGRectGetWidth(firstFrame!) * percentSecond + CGRectGetMinX(firstFrame!)
        if firstItem < 0 {
            x -= CGRectGetWidth(firstFrame!)
        }

        let width = CGRectGetWidth(firstFrame!) * percentFirst + CGRectGetWidth(secondFrame!) * percentSecond
        
        self.selectionIndicatorLeadingConstraint.constant = x + self.selectionIndicatorEdgeInsets.left
        self.selectionIndicatorWidthConstraint.constant = width - self.selectionIndicatorEdgeInsets.left - self.selectionIndicatorEdgeInsets.right
        
        if self.centerSelectTabs {
            self.collectionView.contentOffset = CGPointMake(x - (CGRectGetWidth(self.frame) / 2 - width / 2.0), 0)
        } else {
            if x > (CGRectGetWidth(self.frame) / 2.0) - (width / 2.0) {
                
                if (x < self.collectionView.contentSize.width - (CGRectGetWidth(self.frame) / 2.0) - (width / 2.0)) {
                    self.collectionView.contentOffset = CGPointMake(x - (CGRectGetWidth(self.frame) / 2 - width / 2.0), 0)
                }
            
            }
        }
    }
    
    func calculateItemSizeToFitWidth(width: CGFloat) {
        let numberOfItems = self.collectionView.numberOfItemsInSection(0)
        
        if numberOfItems > 0 {
            if let layout = self.collectionView.collectionViewLayout as? ScrollingTabViewFlowLayout {
                layout.itemSize = CGSizeMake(width / CGFloat(numberOfItems), layout.itemSize.height)
                layout.invalidateLayout()
            }
        }
    }
}

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

