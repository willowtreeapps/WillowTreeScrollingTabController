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

/*
 * Provides a common container view that has a collection view of tabs at the top, with a
 * container collection view at the bottom.
 */
public class ScrollingTabController: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    /// The top ScrollingTabView
    public var tabView = ScrollingTabView()
    
    /// Array of the view controllers that are contained in the bottom view controller. Please note
    /// that if the data source is set, this array is no longer used.
    public var viewControllers = [UIViewController]() {
        didSet {
            if tabControllersView != nil {
                configureViewControllers()
            }
        }
    }
    
    /// Specifies if the tab view should size the width of the tabs to their content.
    public var tabSizing: ScrollingTabView.TabSizing = .fitViewFrameWidth {
        didSet {
            tabView.tabSizing = tabSizing
        }
    }
    
    /// Specifies if the selected tab item should remain centered within the containing view.
    public var centerSelectTabs: Bool = false {
        didSet {
            tabView.centerSelectTabs = centerSelectTabs
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

    static private var sizingCell = ScrollingTabCell(frame: CGRectMake(0, 0, 9999.0, 30.0))

    private let contentSizeKeyPath = "contentSize"
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        tabControllersView = UIScrollView()
        tabControllersView.showsHorizontalScrollIndicator = false
        tabControllersView.showsVerticalScrollIndicator = false
        automaticallyAdjustsScrollViewInsets = false
        
        tabControllersView.delegate = self
        tabControllersView.pagingEnabled = true
        tabControllersView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabControllersView)

        tabView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabView)
        var tabConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[tabBar]|", options: [], metrics: nil, views: ["tabBar": tabView])

        tabConstraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("V:[topGuide][tabBar]", options:[], metrics: nil, views: ["topGuide": topLayoutGuide, "tabBar": tabView]))
        let height = NSLayoutConstraint(item: tabView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 44.0)
        tabView.addConstraint(height)
        view.addConstraints(tabConstraints)

        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[tabControllersView]|", options: [], metrics: nil, views: ["tabControllersView": tabControllersView])
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[tabBar][tabControllersView]|", options:  [], metrics: nil, views: ["tabBar": tabView, "tabControllersView": tabControllersView])

        view.addConstraints(horizontalConstraints)
        view.addConstraints(verticalConstraints)

        tabControllersView.addObserver(self, forKeyPath: contentSizeKeyPath, options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        
        tabView.collectionView.delegate = self
        tabView.collectionView.dataSource = self
        
        configureViewControllers()
        reloadData()
        loadTab(0)
    }

    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tabView.panToPercentage(scrolledPercentage)
        self.tabView.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    /// Listen to the contentSize changing in order to provide a smooth animation during rotation.
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        tabControllersView.contentOffset = CGPointMake(CGFloat(currentPage) * tabControllersView.bounds.width, 0)
    }

    func configureViewControllers() {
        for item in items {
            let child = item.controller
            child.willMoveToParentViewController(nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
            item.container.removeFromSuperview()
        }
        
        for viewController in viewControllers {
            items.append(TabItem(addTabContainer(), viewController))
        }
    }
    
    func addTabContainer() -> UIView {
        let firstTab = (items.count == 0)
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let width = NSLayoutConstraint(item: container, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1.0, constant: 0.0)
        let height = NSLayoutConstraint(item: container, attribute: .Height, relatedBy: .Equal, toItem: tabControllersView, attribute: .Height, multiplier: 1.0, constant: 0.0)
        let top = NSLayoutConstraint(item: container, attribute: .Top, relatedBy: .Equal, toItem: tabControllersView, attribute: .Top, multiplier: 1.0, constant: 0.0)
        let left: NSLayoutConstraint
        if firstTab {
            left = NSLayoutConstraint(item: container, attribute: .Left, relatedBy: .Equal, toItem: tabControllersView, attribute: .Left, multiplier: 1.0, constant: 0.0)
        } else {
            left = NSLayoutConstraint(item: container, attribute: .Left, relatedBy: .Equal, toItem: items.last!.container, attribute: .Right, multiplier: 1.0, constant: 0.0)
        }
        let right = NSLayoutConstraint(item: container, attribute: .Right, relatedBy: .Equal, toItem: tabControllersView, attribute: .Right, multiplier: 1.0, constant: 0.0)
        
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
        let child = items[index].controller

        child.view.translatesAutoresizingMaskIntoConstraints = false
        let width = NSLayoutConstraint(item: child.view, attribute: .Width, relatedBy: .Equal, toItem: container, attribute: .Width, multiplier: 1.0, constant: 0.0)
        let height = NSLayoutConstraint(item: child.view, attribute: .Height, relatedBy: .Equal, toItem: container, attribute: .Height, multiplier: 1.0, constant: 0.0)
        let top = NSLayoutConstraint(item: child.view, attribute: .Top, relatedBy: .Equal, toItem: container, attribute: .Top, multiplier: 1.0, constant: 0.0)
        let left = NSLayoutConstraint(item: child.view, attribute: .Left, relatedBy: .Equal, toItem: container, attribute: .Left, multiplier: 1.0, constant: 0.0)
        
        addChildViewController(child)
        container.addSubview(child.view)
        NSLayoutConstraint.activateConstraints([width, height, top, left])
        child.didMoveToParentViewController(self)
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
        tabView.collectionView.reloadData()
        if items.count > 0 {
            tabView.collectionView.selectItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), animated: false, scrollPosition: .None)
        }
    }
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TabCell", forIndexPath: indexPath) as? ScrollingTabCell else {
            fatalError("Class for tab cells must be a subclass of the scrolling tab cell")
        }
        
        let viewController = viewControllers[indexPath.item]
        cell.title = viewController.tabBarItem.title

        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        switch tabSizing {
        case .fitViewFrameWidth, .fixedSize(_):
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.itemSize
            }
        case .flexibleWidth, .sizeToContent:
            ScrollingTabController.sizingCell.frame.size = CGSizeMake(9999.0, tabView.frame.height)
            ScrollingTabController.sizingCell.contentView.frame = ScrollingTabController.sizingCell.bounds
            
            ScrollingTabController.sizingCell.title = viewControllers[indexPath.row].tabBarItem.title
            ScrollingTabController.sizingCell.layoutIfNeeded()
            
            let size = ScrollingTabController.sizingCell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)

            return CGSizeMake(size.width, tabView.frame.height)
        }

        return CGSizeMake(100.0, tabView.frame.height)
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
            switch self.tabSizing {
            case .fitViewFrameWidth:
                self.tabView.calculateItemSizeToFitWidth(size.width)
            default:
                break
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
            checkAndLoadPages()
        }
        
        tabView.panToPercentage(scrolledPercentage)
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            checkAndLoadPages()
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        checkAndLoadPages()
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        loadedPages = HalfOpenInterval<Int>(currentPage, currentPage)
        lazyLoad(currentPage)
        jumpScroll = false
        
        // When scrolling with animation, not all items may be captured in the loadedPages interval.
        // This clears out any remaining views left on the scrollview.
        for index in 0..<items.count {
            unloadTab(index)
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
        return index >= 0 && index < items.count
    }
}


