//
//  ScrollingTabController.swift
//  ScrollingTabControllerExample
//
//  Created by Erik LaManna on 9/2/15.
//  Copyright © 2015 WillowTree, Inc. All rights reserved.
//

import UIKit

class TabFlowController: UICollectionViewFlowLayout {

    override init() {
        super.init()
        self.minimumInteritemSpacing = 0
        self.minimumLineSpacing = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.minimumInteritemSpacing = 0
        self.minimumLineSpacing = 0
        
    }
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = self.collectionView else {
            return proposedContentOffset
        }
        
        var offset = CGFloat(MAXFLOAT)
        let halfWidth = CGRectGetWidth(collectionView.bounds) / 2.0
        let horizontalCenter = proposedContentOffset.x + halfWidth
        
        let targetRect = CGRectMake(proposedContentOffset.x, 0.0, collectionView.bounds.size.width, collectionView.bounds.size.height)
        
        let layoutAttributes = self.layoutAttributesForElementsInRect(targetRect)
        
            for attributes in (layoutAttributes ?? []) {
                let itemHorizontalCenter = attributes.center.x
                if abs(itemHorizontalCenter - horizontalCenter) < abs(offset) {
                    offset = itemHorizontalCenter - horizontalCenter
                }
            }
        
        let targetPoint = CGPointMake(min(collectionView.contentSize.width - collectionView.frame.size.width, max(0, proposedContentOffset.x + offset)), 0)
        return targetPoint
    }
    
//    - (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
//    withScrollingVelocity:(CGPoint)velocity
//    {
//    CGFloat offsetAdjustment = MAXFLOAT;
//    CGFloat cvHalfWidth = (CGRectGetWidth(self.collectionView.bounds) / 2.0);
//    CGFloat horizontalCenter = proposedContentOffset.x + cvHalfWidth;
//    
//    CGRect targetRect = CGRectMake(proposedContentOffset.x,
//    0.0,
//    self.collectionView.bounds.size.width,
//    self.collectionView.bounds.size.height);
//    
//    NSArray *array = [super layoutAttributesForElementsInRect:targetRect];
//    
//    for (UICollectionViewLayoutAttributes* layoutAttributes in array)
//    {
//    CGFloat itemHorizontalCenter = layoutAttributes.center.x;
//    if (ABS(itemHorizontalCenter - horizontalCenter) < ABS(offsetAdjustment))
//    {
//    offsetAdjustment = itemHorizontalCenter - horizontalCenter;
//    }
//    }
//    
//    CGPoint p = CGPointMake(
//    MIN(self.collectionView.contentSize.width - [self.collectionView frameSizeWidth],
//    MAX(0, proposedContentOffset.x + offsetAdjustment)),
//    proposedContentOffset.y);
//    
//    return p;
//    }

}

protocol ScrollingTabControllerDataSource {
}

public class ScrollingTabController: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    public var tabView = ScrollingTabView()
    
    public var viewControllers = [UIViewController]() {
        didSet {
            if self.tabControllersView != nil {
                self.configureViewControllers()
            }
        }
    }
    
    var viewControllerCache = NSCache()
    var tabControllersView: UIScrollView!
    var collectionViewLayout = TabFlowController()
    var scrollingStarted = false

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
        
        tabView.registerClass(ScrollingTabCell.classForCoder(), forCellWithReuseIdentifier: "TabCell")
        tabView.delegate = self
        tabView.dataSource = self
        
        self.configureViewControllers()
        reloadData()
        
        self.loadTab(0)
        // Do any additional setup after loading the view.
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        tabControllersView.contentOffset = CGPointMake(CGFloat(currentPage) * tabControllersView.bounds.width, 0)
    }

    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
//        self.logger?.trace("Lazy evaluating tab \(index); loaded \(loadedPages); current: \(currentPage)")
        
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
        
//        logger?.trace("Loading tab \(index)")
        
        switch index {
        case loadedPages.start - 1:
            loadedPages = HalfOpenInterval<Int>(index, loadedPages.end)
        case loadedPages.end:
            loadedPages = HalfOpenInterval<Int>(loadedPages.start, index + 1)
        default:
            fatalError("Should not be able to load tabs not adjacent to loaded tabs")
        }
        
        let container = items[index].container
        let child = items[index].controller
        
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
    
    func unloadTab(index: Int) {
        guard inRange(index) else { return }
        guard !shouldLoadTab(index) else { return }
        guard loadedPages.contains(index) else { return }
        
//        logger?.trace("Unloading tab \(index)")
        
        switch index {
        case loadedPages.start:
            loadedPages = HalfOpenInterval<Int>(index + 1, loadedPages.end)
        case loadedPages.end - 1:
            loadedPages = HalfOpenInterval<Int>(loadedPages.start, index)
        default:
            fatalError("Should not be able to unload tabs not on the edges of loaded range")
        }
        
        let child = items[index].controller
        child.willMoveToParentViewController(nil)
        child.view.removeFromSuperview()
        child.removeFromParentViewController()
    }
    
    func reloadData() {
        self.tabView.reloadData()
        if self.items.count > 0 {
            self.tabView.selectItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), animated: false, scrollPosition: .None)
        }
    }
    
    func tabWidth() -> CGFloat {
//        guard self.items.count > 0 else {
////            return theme.tab.minWidth
//        }
        
        let fittingWidth = view.bounds.width / CGFloat(items.count)
        return max(fittingWidth, /*theme.tab.minWidth*/100)
    }
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TabCell", forIndexPath: indexPath) as! ScrollingTabCell
        
        cell.titleLabel.text = "item \(indexPath.item)"
        
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        scrollToPage(indexPath.item, animate: true)
    }

//    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
//        return 1
//    }
//    
//    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return self.childControllers.count
//    }
//    
//    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! ScrollingViewControllerCell
//        
//        let viewController = self.childControllers[indexPath.item]
//        
//        if cell.viewController == nil || !(cell.viewController === viewController) {
//            
//            cell.parentViewController = self
//            cell.viewController = viewController
//            
//            if let snapshot = self.viewControllerCache.objectForKey(indexPath) as? UIView {
//                cell.snapshotView = snapshot
//            }
//        }
//
//            
//        return cell
//    }
    
//    public func scrollViewDidScroll(scrollView: UIScrollView) {
//        if (!scrollingStarted)
//        {
//            scrollingStarted = true
//            for indexPath in self.collectionView.indexPathsForVisibleItems() {
//                if let vcCell = self.collectionView.cellForItemAtIndexPath(indexPath) as? ScrollingViewControllerCell {
//                    let snapshot = vcCell.snapshotViewAfterScreenUpdates(false)
//                    self.viewControllerCache.setObject(snapshot, forKey: indexPath)
//                }
//            }
//        }
//    }
//    
//    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
//        scrollingStarted = false
//        for cell in self.collectionView.visibleCells() {
//            if let vcCell = cell as? ScrollingViewControllerCell {
//                vcCell.loadViewController()
//            }
//        }
//    }
//    
//    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
//        scrollingStarted = false
//    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        updatingCurrentPage = false
//        self.tabsCollectionView.collectionViewLayout.invalidateLayout()
        coordinator.animateAlongsideTransition(nil, completion: { context in
            self.updatingCurrentPage = true
        })
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        guard scrollView == tabControllersView else {
            return
        }
        
        guard updatingCurrentPage else {
            return
        }
        
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
    
    func scrollToPage(index: Int, animate: Bool) {
        let rect = CGRectMake(CGFloat(index) * tabControllersView.bounds.width, 0, tabControllersView.bounds.width, tabControllersView.bounds.height)
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

