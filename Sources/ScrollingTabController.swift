//
//  ScrollingTabController.swift
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
 * Protocol used to provide data to the tab portion of the ScrollingTabController.
 */
public protocol TabDataSource: class {
    
    /**
     * Returns the number of items in the tab view.
     *
     * - Parameter tabView: the tab controller requesting the tab count
     *
     * - Returns: An optional integer value representing the number of items in the tab view
     */
    func numberOfItemsInTabView(tabView: ScrollingTabController) -> Int?
    
    /**
     * Returns the view controller for the specified view index.
     *
     * - Parameter tabView: the tab controller requesting the tab count
     * - Parameter viewControllerAtIndex: the index for the requested view controller
     *
     * - Returns: The view controller at the specified index or nil if not found
     */
    func tabView(tabView: ScrollingTabController, viewControllerAtIndex index: Int) -> UIViewController?
    
    /**
     * Configures the tab cell at the specified index.
     *
     * - Parameter tabView: the tab controller requesting the cell configuration
     * - Parameter configureTitleCell: the UICollectionViewCell to configure
     * - Parameter atIndex: the index of the cell to configure
     *
     * - Returns: The configured collection view cell
     */
    func tabView(tabView: ScrollingTabController, configureTitleCell cell: UICollectionViewCell, atIndex index: Int) -> UICollectionViewCell?
    
    /**
     * Returns the width for a specific tab cell at a given index.
     *
     * - Parameter tabView: the tab controller requesting the cell width
     * - Parameter widthForCellAtIndex: the index of the cell to return the width for
     *
     * - Returns: The width of the cell at the index path.  Default nil (equal widths)
     */
    func tabView(tabView: ScrollingTabController, widthForCellAtIndex index: Int) -> CGFloat?
}

/**
 * Default protocol extension
 */
public extension TabDataSource {
    
    func numberOfItemsInTabView(tabView: ScrollingTabController) -> Int? {
        return nil;
    }
    
    func tabView(tabView: ScrollingTabController, viewControllerAtIndex index: Int) -> UIViewController?
    {
        return nil
    }
    
    func tabView(tabView: ScrollingTabController, configureTitleCell cell: UICollectionViewCell, atIndex index: Int) -> UICollectionViewCell?
    {
        return nil
    }
    
    func tabView(tabView: ScrollingTabController, widthForCellAtIndex index: Int) -> CGFloat?
    {
        return nil
    }
    
}

/**
 * Provides a common container view that has a collection view of tabs at the top, with a
 * container collection view at the bottom.
 */
public class ScrollingTabController: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    /// The top ScrollingTabView
    public var tabView = ScrollingTabView()
    
    /// Array of the view controllers that are contained in the bottom view controller
    public var viewControllers = [UIViewController]() {
        didSet {
            if self.tabControllersView != nil {
                self.configureViewControllers()
            }
        }
    }
    
    /// Data source for the tab controller
    @IBInspectable public weak var dataSource: TabDataSource?
    
    /// Specifies if the tab view should size the width of the tabs to their content.
    public var sizeTabItemsToFit: Bool = false {
        didSet {
            self.tabView.sizeTabsToFitWidth = sizeTabItemsToFit
        }
    }
    
    /// Specifies if the selected tab item should remain centered within the containing view.
    public var centerSelectTabs: Bool = false {
        didSet {
            self.tabView.centerSelectTabs = centerSelectTabs
        }
    }
    
    /// The current scrolled percentage
    var scrolledPercentage: CGFloat {
        return self.tabControllersView.contentOffset.x / tabControllersView.contentSize.width
    }
    
    var viewControllerCache = NSCache()
    var tabControllersView: UIScrollView!
    var jumpScroll = false
    
    var currentPage: Int = 0
    var updatingCurrentPage = true
    var loadedPages = HalfOpenInterval<Int>(0, 0)
    var numToPreload = 1
    
    var tabControllersViewRightConstraint: NSLayoutConstraint?
    
    typealias TabItem = (container: UIView, controller: UIViewController)
    var items = [TabItem]()
    
    private let contentSizeKeyPath = "contentSize"
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabControllersView = UIScrollView()
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.tabControllersView.delegate = self
        self.tabControllersView.pagingEnabled = true
        self.tabControllersView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.tabControllersView)
        
        self.tabView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.tabView)
        var tabConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[tabBar]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["tabBar": self.tabView])
        
        tabConstraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("V:[topGuide][tabBar]", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["topGuide": self.topLayoutGuide, "tabBar": self.tabView]))
        let height = NSLayoutConstraint(item: self.tabView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 44.0)
        self.tabView.addConstraint(height)
        self.view.addConstraints(tabConstraints)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[tabControllersView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["tabControllersView": self.tabControllersView])
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[tabBar][tabControllersView]|", options:  NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["tabBar": self.tabView, "tabControllersView": self.tabControllersView])
        
        self.view.addConstraints(horizontalConstraints)
        self.view.addConstraints(verticalConstraints)
        
        tabControllersView.addObserver(self, forKeyPath: contentSizeKeyPath, options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        
        tabView.collectionView.registerClass(ScrollingTabCell.classForCoder(), forCellWithReuseIdentifier: "TabCell")
        tabView.collectionView.delegate = self
        tabView.collectionView.dataSource = self
        
        self.configureViewControllers()
        reloadData()
        
        self.loadTab(0)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if self.sizeTabItemsToFit {
            self.tabView.calculateItemSizeToFitWidth(self.view.frame.size.width)
        }
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tabView.panToPercentage(scrolledPercentage)
    }
    
    /// Listen to the contentSize changing in order to provide a smooth animation during rotation.
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        tabControllersView.contentOffset = CGPointMake(CGFloat(currentPage) * tabControllersView.bounds.width, 0)
    }

    func configureViewControllers() {
        for item in self.items {
            let child = item.controller
            child.willMoveToParentViewController(nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
            item.container.removeFromSuperview()
        }
        
        for viewController in self.viewControllers {
            self.items.append(TabItem(self.addTabContainer(), viewController))
        }
    }
    
    func addTabContainer() -> UIView {
        let firstTab = (self.items.count == 0)
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let width = NSLayoutConstraint(item: container, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1.0, constant: 0.0)
        let height = NSLayoutConstraint(item: container, attribute: .Height, relatedBy: .Equal, toItem: self.tabControllersView, attribute: .Height, multiplier: 1.0, constant: 0.0)
        let top = NSLayoutConstraint(item: container, attribute: .Top, relatedBy: .Equal, toItem: self.tabControllersView, attribute: .Top, multiplier: 1.0, constant: 0.0)
        let left: NSLayoutConstraint
        if firstTab {
            left = NSLayoutConstraint(item: container, attribute: .Left, relatedBy: .Equal, toItem: self.tabControllersView, attribute: .Left, multiplier: 1.0, constant: 0.0)
        } else {
            left = NSLayoutConstraint(item: container, attribute: .Left, relatedBy: .Equal, toItem: items.last!.container, attribute: .Right, multiplier: 1.0, constant: 0.0)
        }
        let right = NSLayoutConstraint(item: container, attribute: .Right, relatedBy: .Equal, toItem: self.tabControllersView, attribute: .Right, multiplier: 1.0, constant: 0.0)
        
        if tabControllersViewRightConstraint != nil {
            tabControllersViewRightConstraint!.active = false
        }
        tabControllersViewRightConstraint = right
        
        tabControllersView.addSubview(container)
        NSLayoutConstraint.activateConstraints([width, height, top, left, right])
        return container
    }
    
    func lazyLoad(index: Int) {
        guard inRange(index) else { return }
        
        if shouldLoadTab(index) {
            loadTab(index)
        } else {
            unloadTab(index)
        }
    }
    
    func loadTab(index: Int) {
        guard inRange(index) else { return }
        guard shouldLoadTab(index) else { return }
        guard !loadedPages.contains(index) else { return }
        
        switch index {
        case loadedPages.start - 1:
            loadedPages = HalfOpenInterval<Int>(index, loadedPages.end)
        case loadedPages.end:
            loadedPages = HalfOpenInterval<Int>(loadedPages.start, index + 1)
        default:
            loadedPages = HalfOpenInterval<Int>(index, index)
        }
        
        let container = items[index].container
        
        var childViewController = self.dataSource?.tabView(self, viewControllerAtIndex: index)
        
        if childViewController == nil {
            childViewController = items[index].controller
        }

        if let child = childViewController {
            child.view.translatesAutoresizingMaskIntoConstraints = false
            let width = NSLayoutConstraint(item: child.view, attribute: .Width, relatedBy: .Equal, toItem: container, attribute: .Width, multiplier: 1.0, constant: 0.0)
            let height = NSLayoutConstraint(item: child.view, attribute: .Height, relatedBy: .Equal, toItem: container, attribute: .Height, multiplier: 1.0, constant: 0.0)
            let top = NSLayoutConstraint(item: child.view, attribute: .Top, relatedBy: .Equal, toItem: container, attribute: .Top, multiplier: 1.0, constant: 0.0)
            let left = NSLayoutConstraint(item: child.view, attribute: .Left, relatedBy: .Equal, toItem: container, attribute: .Left, multiplier: 1.0, constant: 0.0)
            
            self.addChildViewController(child)
            container.addSubview(child.view)
            NSLayoutConstraint.activateConstraints([width, height, top, left])
            child.didMoveToParentViewController(self)
        }
    }
    
    func unloadTab(index: Int) {
        guard inRange(index) else { return }
        guard !shouldLoadTab(index) else { return }
        
        switch index {
        case loadedPages.start:
            loadedPages = HalfOpenInterval<Int>(index + 1, loadedPages.end)
        case loadedPages.end - 1:
            loadedPages = HalfOpenInterval<Int>(loadedPages.start, index)
        default:
            break
        }
        
        let child = items[index].controller
        child.willMoveToParentViewController(nil)
        child.view.removeFromSuperview()
        child.removeFromParentViewController()
    }
    
    func unloadTabs() {
        
    }
    
    func reloadData() {
        self.tabView.collectionView.reloadData()
        if self.items.count > 0 {
            self.tabView.collectionView.selectItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), animated: false, scrollPosition: .None)
        }
    }
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let count = self.dataSource?.numberOfItemsInTabView(self) {
            return count
        }
        
        return self.items.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TabCell", forIndexPath: indexPath) as! ScrollingTabCell
        
        let configuredCell = self.dataSource?.tabView(self, configureTitleCell: cell, atIndex: indexPath.item)
        
        if configuredCell == nil {
            let viewController = viewControllers[indexPath.item]
            cell.titleLabel.text = viewController.tabBarItem.title
        }
        
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let height = CGRectGetHeight(collectionView.frame)

        if let width = self.dataSource?.tabView(self, widthForCellAtIndex: indexPath.item) {
            return CGSizeMake(width, height)
        } else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.itemSize
            }
            
            return CGSizeMake(100.0, height)
        }
    }
    
    public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        var view = UICollectionReusableView()
        if kind == ScrollingTabVerticalDividerType {
            view = collectionView.dequeueReusableSupplementaryViewOfKind(ScrollingTabVerticalDividerType, withReuseIdentifier: ScrollingTabVerticalDividerType, forIndexPath: indexPath)
        }
        
        return view;
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        scrollToPage(indexPath.item, animate: true)
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        updatingCurrentPage = false

        coordinator.animateAlongsideTransition({ _ in
            if self.sizeTabItemsToFit {
                self.tabView.calculateItemSizeToFitWidth(size.width)
            }

            }, completion: { context in
                self.updatingCurrentPage = true
                self.tabView.panToPercentage(self.scrolledPercentage)
        })
    }
    
    func checkAndLoadPages() {
        let width = tabControllersView.frame.size.width
        let page = Int(tabControllersView.contentOffset.x / width)
        if page != currentPage {
            currentPage = page
            
            for offset in 0...(numToPreload + 1) {
                lazyLoad(page - offset)
                if offset > 0 {
                    lazyLoad(page + offset)
                }
            }
        }
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        guard scrollView == tabControllersView else {
            return
        }
        
        guard updatingCurrentPage else {
            return
        }
        
        if scrollView.tracking {
            self.checkAndLoadPages()
        }
        
        self.tabView.panToPercentage(scrolledPercentage)
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.checkAndLoadPages()
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.checkAndLoadPages()
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        loadedPages = HalfOpenInterval<Int>(currentPage, currentPage)
        lazyLoad(currentPage)
        jumpScroll = false
        
        // When scrolling with animation, not all items may be captured in the loadedPages interval.
        // This clears out any remaining views left on the scrollview.
        for index in 0..<items.count {
            self.unloadTab(index)
        }
    }
    
    func scrollToPage(index: Int, animate: Bool) {
        let rect = CGRectMake(CGFloat(index) * tabControllersView.bounds.width, 0, tabControllersView.bounds.width, tabControllersView.bounds.height)
        jumpScroll = true
        currentPage = index
        tabControllersView.setContentOffset(rect.origin, animated: true)
    }
    
    deinit {
        tabControllersView?.removeObserver(self, forKeyPath: contentSizeKeyPath, context: nil)
    }
    
    func shouldLoadTab(index: Int) -> Bool {
        return index >= (currentPage - numToPreload) && index <= (currentPage + numToPreload)
    }
    
    func inRange(index: Int) -> Bool {
        return index >= 0 && index < self.items.count
    }
}


