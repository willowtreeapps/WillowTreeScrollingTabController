//
//  ScrollingTabView.swift
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

public let ScrollingTabVerticalDividerType = "VerticalDivider"
public let ScrollingTabTitleCell = "TabCell"

/**
 * View that contains the top set of tabs and their containing collection view.
 */
public class ScrollingTabView: UIView {

    public enum TabSizing {
        case fitViewFrameWidth
        case fixedSize(CGFloat)
        case sizeToContent
        ///Takes on the attributes of fitViewFrameWidth until the content is too large and then it takes on the attributes of sizeToContent
        case flexibleWidth
    }

    /// Collection view containing the tabs
    public var collectionView: UICollectionView!
    
    /// Collection view layout for the tab view.
    public var scrollingLayout: ScrollingTabViewFlowLayout!
    
    /// Specifies the offset of the selection indicator from the bottom of the view. Defaults to 0.
    public var selectionIndicatorOffset: CGFloat = 0 {
        didSet {
            if selectionIndicatorBottomConstraint != nil {
                selectionIndicatorBottomConstraint.constant = selectionIndicatorOffset
            }
        }
    }
    
    /// Returns the view used as the selection indicator
    public var selectionIndicator: UIView!
    
    /// Specifies the height of the selection indicator. Defaults to 5.
    public var selectionIndicatorHeight: CGFloat = 5 {
        didSet {
            if selectionIndicatorHeightConstraint != nil {
                selectionIndicatorHeightConstraint.constant = selectionIndicatorHeight
            }
        }
    }
    
    /// Specifies the edge insets of the selection indicator to the cells.  Defaults to 0 insets.
    public var selectionIndicatorEdgeInsets: UIEdgeInsets = UIEdgeInsetsZero
    
    /// Specifies if the tabs should size to fit their content
    public var tabSizing: TabSizing = .fitViewFrameWidth {
        didSet {
            switch tabSizing {
            case .fitViewFrameWidth:
                calculateItemSizeToFitWidth(frame.width)
                if let layout = collectionView.collectionViewLayout as? ScrollingTabViewFlowLayout {
                    layout.flexibleWidth = false
                }
            case .fixedSize(let width):
                if let layout = collectionView.collectionViewLayout as? ScrollingTabViewFlowLayout {
                    layout.itemSize = CGSizeMake(width, layout.itemSize.height)
                    layout.flexibleWidth = false
                    layout.invalidateLayout()
                }
            case .flexibleWidth:
                if let layout = collectionView.collectionViewLayout as? ScrollingTabViewFlowLayout {
                    layout.flexibleWidth = true
                }
                // Delegate will handle sizing per cell.
            default :
                if let layout = collectionView.collectionViewLayout as? ScrollingTabViewFlowLayout {
                    layout.flexibleWidth = false
                }
                break
            }
        }
    }
    
    /// Specifies if the selection of the tabs remains centered.
    public var centerSelectTabs: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// Specifies the cell to use for each tab.
    public var classForCell: AnyClass = ScrollingTabCell.classForCoder() {
        didSet {
            if collectionView != nil {
                collectionView.registerClass(classForCell, forCellWithReuseIdentifier: ScrollingTabTitleCell)
            }
        }
    }
    
    /// Specifies the class to use for the divider in the view.
    public var classForDivider: AnyClass = ScrollingTabDivider.classForCoder() {
        didSet {
            if collectionView != nil {
                collectionView.collectionViewLayout.registerClass(classForDivider, forDecorationViewOfKind: ScrollingTabVerticalDividerType)
                collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }
    
    var selectionIndicatorLeadingConstraint: NSLayoutConstraint!
    var selectionIndicatorBottomConstraint: NSLayoutConstraint!
    var selectionIndicatorHeightConstraint: NSLayoutConstraint!
    var selectionIndicatorWidthConstraint: NSLayoutConstraint!

    var lastPercentage: CGFloat = 0.0
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        backgroundColor = UIColor.whiteColor()
        
        scrollingLayout = ScrollingTabViewFlowLayout()
        collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: scrollingLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.clearColor()
        addSubview(collectionView)
        
        let horizontalContstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[collectionView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["collectionView": collectionView])
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["collectionView": collectionView])
        
        NSLayoutConstraint.activateConstraints(horizontalContstraints)
        NSLayoutConstraint.activateConstraints(verticalConstraints)
        
        selectionIndicator = UIView()
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.backgroundColor = selectionIndicator.tintColor
        collectionView.addSubview(selectionIndicator)
        selectionIndicatorBottomConstraint = NSLayoutConstraint(item: selectionIndicator, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: selectionIndicatorOffset)
        selectionIndicatorLeadingConstraint = NSLayoutConstraint(item: selectionIndicator, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: collectionView, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
        selectionIndicatorHeightConstraint = NSLayoutConstraint(item: selectionIndicator, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: selectionIndicatorHeight)
        selectionIndicatorWidthConstraint = NSLayoutConstraint(item: selectionIndicator, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 100)

        NSLayoutConstraint.activateConstraints([selectionIndicatorBottomConstraint, selectionIndicatorLeadingConstraint, selectionIndicatorHeightConstraint, selectionIndicatorWidthConstraint])
        
        collectionView.registerClass(classForCell, forCellWithReuseIdentifier: ScrollingTabTitleCell)
        collectionView.collectionViewLayout.registerClass(classForDivider, forDecorationViewOfKind: ScrollingTabVerticalDividerType)
        
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        bringSubviewToFront(selectionIndicator)
        
        switch tabSizing {
        case .fitViewFrameWidth:
            calculateItemSizeToFitWidth(frame.width)
        default:
            break
        }
        
        if centerSelectTabs {
            let inset = collectionView.frame.width / 2.0 - scrollingLayout.itemSize.width / 2.0
            collectionView.contentInset = UIEdgeInsetsMake(0, inset, 0, inset)
        }
    }
    
    public func panToPercentage(percentage: CGFloat) {
        lastPercentage = percentage

        let tabCount = collectionView.numberOfItemsInSection(0)
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
        collectionView.selectItemAtIndexPath(selectIndexPath, animated: false, scrollPosition: .None)

        let attrs1 = collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(firstPath!)
        let attrs2 = collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(secondPath!)
        
        let firstFrame = attrs1?.frame
        let secondFrame = attrs2?.frame
        
        var x = CGRectGetWidth(firstFrame!) * percentSecond + CGRectGetMinX(firstFrame!)
        if firstItem < 0 {
            x -= CGRectGetWidth(firstFrame!)
        }

        let width = CGRectGetWidth(firstFrame!) * percentFirst + CGRectGetWidth(secondFrame!) * percentSecond
        
        selectionIndicatorLeadingConstraint.constant = x + selectionIndicatorEdgeInsets.left
        selectionIndicatorWidthConstraint.constant = width - selectionIndicatorEdgeInsets.left - selectionIndicatorEdgeInsets.right
        
        if centerSelectTabs {
            collectionView.contentOffset = CGPointMake(x - (CGRectGetWidth(frame) / 2 - width / 2.0), 0)
        } else {
            if x > (CGRectGetWidth(frame) / 2.0) - (width / 2.0) {
                
                if (x < collectionView.contentSize.width - (CGRectGetWidth(frame) / 2.0) - (width / 2.0)) {
                    collectionView.contentOffset = CGPointMake(x - (CGRectGetWidth(frame) / 2 - width / 2.0), 0)
                }
            }
        }
    }

    func calculateItemSizeToFitWidth(width: CGFloat) {
        let numberOfItems = collectionView.numberOfItemsInSection(0)

        if numberOfItems > 0 {
            if let layout = collectionView.collectionViewLayout as? ScrollingTabViewFlowLayout {
                let calculatedSize = CGSizeMake(width / CGFloat(numberOfItems), layout.itemSize.height)

                if layout.itemSize != calculatedSize {
                    layout.itemSize = calculatedSize
                    layout.invalidateLayout()
                    collectionView.layoutIfNeeded()
                }
                panToPercentage(lastPercentage)
            }
        }
    }
}

/**
 * Custom collection view flow layout for the tab view.
 */
public class ScrollingTabViewFlowLayout: UICollectionViewFlowLayout {
    
    /// Specifies the divider spacing from the top of the tab view. Defaults to 10.
    public var topDividerMargin: CGFloat = 10.0
    
    /// Specifies the divider spacing from the bottom of the tab view. Defaults to 10.
    public var bottomDividerMargin: CGFloat = 10.0
    
    /// Specifies the width of the divider view. Defaults to 1.
    public var dividerWidth: CGFloat = 1.0
    
    /// Specifies the color of the divider. Defaults to black.
    public var dividerColor: UIColor = UIColor.blackColor()
    
    /// Specifies if the divider is visible. Defaults to false.
    public var showDivider: Bool = false

    public var flexibleWidth : Bool = false {
        didSet {
            self.invalidateLayout()
        }
    }

    override init() {
        super.init()
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        sectionInset = UIEdgeInsetsZero
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
        itemSize = CGSizeMake(100, 30.0)
        scrollDirection = .Horizontal
    }

    override public func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = layoutAttributesForItemAtIndexPath(indexPath)
        let dividerAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: ScrollingTabVerticalDividerType, withIndexPath: indexPath)
        
        if let attributes = attributes, collectionView = collectionView {
            dividerAttributes.frame = CGRectMake(CGRectGetMaxX(attributes.frame),
                topDividerMargin,
                dividerWidth,
                CGRectGetHeight(collectionView.frame) - topDividerMargin - bottomDividerMargin)
        }
        
        dividerAttributes.zIndex = -1
        
        return dividerAttributes
    }
    
    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElementsInRect(rect) else {
            return nil
        }
        
        var updatedAttributes = attributes
        
        if showDivider {
            for layoutAttribute in attributes {
                if (layoutAttribute.representedElementCategory == .Cell) {
                    if let dividerAttribute = layoutAttributesForDecorationViewOfKind(ScrollingTabVerticalDividerType,
                        atIndexPath: layoutAttribute.indexPath) {
                            updatedAttributes.append(dividerAttribute)
                    }
                }
            }
        }

        if let collectionView = self.collectionView
            where collectionView.contentSize.width < collectionView.frame.width
                && flexibleWidth {
            var index = 0
            var attributesIndex = 0

            let attributesCopy = updatedAttributes

            for attribute in attributesCopy {
                if attribute.representedElementCategory == .Cell {
                    if let layoutAttributes = layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) {
                        updatedAttributes.removeAtIndex(attributesIndex)
                        updatedAttributes.insert(layoutAttributes, atIndex: attributesIndex)
                    }
                    index++
                }

                attributesIndex++
            }
        }
        
        return updatedAttributes
    }

    override public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute = super.layoutAttributesForItemAtIndexPath(indexPath)!

        guard let collectionView = collectionView, let dataSource = collectionView.dataSource
            where collectionView.contentSize.width < collectionView.frame.width
                && flexibleWidth else {
            return attribute
        }

        var frame = attribute.frame

        let itemCount = dataSource.collectionView(collectionView, numberOfItemsInSection: 0)

        frame.size.width = collectionView.frame.width / CGFloat(itemCount)
        frame.origin.x = CGFloat(indexPath.row) * frame.size.width
        attribute.frame = frame

        return attribute;
    }


}


public class ScrollingTabDivider: UICollectionReusableView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        backgroundColor = UIColor.blackColor()
    }
}

