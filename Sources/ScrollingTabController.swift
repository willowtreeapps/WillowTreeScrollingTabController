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

public protocol ScrollingTabControllerDelegate: class {
    func scrollingTabController(_ tabController: ScrollingTabController, displayedViewControllerAtIndex: Int)
}

/*
 * Provides a common container view that has a collection view of tabs at the top, with a
 * container collection view at the bottom.
 */
open class ScrollingTabController: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {

    public struct CellTheme {
        public let font: UIFont
        public let defaultColor: UIColor
        public let selectedColor: UIColor

        public init(font: UIFont, defaultColor: UIColor, selectedColor: UIColor) {
            self.font = font
            self.defaultColor = defaultColor
            self.selectedColor = selectedColor
        }
    }
    
    /// The top ScrollingTabView
    open var tabView = ScrollingTabView()
    
    /// Array of the view controllers that are contained in the bottom view controller. Please note
    /// that if the data source is set, this array is no longer used.
    var viewControllers = [UIViewController]()

    public var viewControllerCount: Int {
        return viewControllers.count
    }

    public var tabTheme: CellTheme = CellTheme(font: UIFont.systemFont(ofSize: UIFont.systemFontSize),
                                               defaultColor: .darkText, selectedColor: .blue)
    
    /// Specifies if the tab view should size the width of the tabs to their content.
    open var tabSizing: ScrollingTabView.TabSizing = .fitViewFrameWidth {
        didSet {
            tabView.tabSizing = tabSizing
        }
    }
    
    /// Specifies if the selected tab item should remain centered within the containing view.
    open var centerSelectTabs: Bool = false {
        didSet {
            tabView.centerSelectTabs = centerSelectTabs
        }
    }

    /// Specifies the height of the top tab bar. Defaults to 44.0
    open var tabBarHeight: CGFloat = 44.0 {
        didSet {
            guard let heightConstraint = tabBarHeightConstraint else {
                return
            }

            heightConstraint.constant = tabBarHeight
        }
    }
    
    /// The current scrolled percentage
    var scrolledPercentage: CGFloat {
        guard tabControllersView.contentSize.width > 0 else {
            return 0
        }

        return self.tabControllersView.contentOffset.x / tabControllersView.contentSize.width
    }
    
    open weak var delegate: ScrollingTabControllerDelegate? = nil
    
    var tabControllersView: UIScrollView!
    var jumpScroll = false
    
    open internal(set) var currentPage: Int = 0
    var previousPage: Int = 0
    var updatingCurrentPage = true
    var loadedPages = (0 ..< 0)
    var numToPreload = 1
    fileprivate var deferredInitialSelectedPage: Int?
    fileprivate var initialAppearanceComplete = false
    
    var tabControllersViewRightConstraint: NSLayoutConstraint?
    
    typealias TabItem = (container: UIView, controller: UIViewController)
    var items = [TabItem]()

    static fileprivate var sizingCell = ScrollingTabCell(frame: CGRect(x: 0, y: 0, width: 9999.0, height: 30.0))

    fileprivate let contentSizeKeyPath = "contentSize"
    fileprivate var tabBarHeightConstraint: NSLayoutConstraint!
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        tabControllersView = UIScrollView()
        tabControllersView.showsHorizontalScrollIndicator = false
        tabControllersView.showsVerticalScrollIndicator = false
        automaticallyAdjustsScrollViewInsets = false
        
        tabControllersView.delegate = self
        tabControllersView.isPagingEnabled = true
        tabControllersView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabControllersView)

        tabView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabView)
        var tabConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|[tabBar]|", options: [], metrics: nil, views: ["tabBar": tabView])

        tabConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[topGuide][tabBar]", options:[], metrics: nil, views: ["topGuide": topLayoutGuide, "tabBar": tabView]))
        tabBarHeightConstraint = NSLayoutConstraint(item: tabView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: tabBarHeight)

        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|[tabControllersView]|", options: [], metrics: nil, views: ["tabControllersView": tabControllersView])
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[tabBar][tabControllersView]|", options:  [], metrics: nil, views: ["tabBar": tabView, "tabControllersView": tabControllersView])

        NSLayoutConstraint.activate([tabBarHeightConstraint] + tabConstraints + horizontalConstraints + verticalConstraints)

        tabControllersView.addObserver(self, forKeyPath: contentSizeKeyPath, options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        
        tabView.collectionView.delegate = self
        tabView.collectionView.dataSource = self
        
        configureViewControllers()
        reloadData()
        loadTab(0)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let selectedPage = deferredInitialSelectedPage , !initialAppearanceComplete {
            initialAppearanceComplete = true
            selectTab(atIndex: selectedPage, animated: false)
            deferredInitialSelectedPage = nil
        } else {
            childBeginAppearanceTransition(currentPage, isAppearing: true, animated: animated)
            tabView.panToPercentage(scrolledPercentage)
        }

        delegate?.scrollingTabController(self, displayedViewControllerAtIndex: currentPage)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if initialAppearanceComplete {
            childEndAppearanceTransition(currentPage)
        }

        initialAppearanceComplete = true
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        childBeginAppearanceTransition(currentPage, isAppearing: false, animated: animated)
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        childEndAppearanceTransition(currentPage)
    }

    open override var shouldAutomaticallyForwardAppearanceMethods : Bool {
        // In order to send child view controllers the view(Will/Did)(Appear/Disappear) calls at the 
        // correct times and only when the view controller is visible, we will fully control the 
        // appearance calls.
        return false
    }
    
    /// Listen to the contentSize changing in order to provide a smooth animation during rotation.
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        tabControllersView.contentOffset = CGPoint(x: CGFloat(currentPage) * tabControllersView.bounds.width, y: 0)
    }

    func configureViewControllers() {
        for viewController in viewControllers {
            items.append(TabItem(addTabContainer(), viewController))
        }
    }

    public func injectInitialViewControllers(_ viewControllers: [UIViewController]) {
        self.viewControllers = viewControllers
        guard tabControllersView != nil else { return }

        for item in items {
            let child = item.controller
            child.willMove(toParentViewController: nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
            item.container.removeFromSuperview()
        }
        items = []

        configureViewControllers()
    }

    public func appendViewController(_ newViewControllers: [UIViewController]) {
        var inserts: [IndexPath] = []
        for index in 0..<newViewControllers.count {
            inserts.append(IndexPath(item: index + viewControllers.count, section: 0))
        }
        for vc in newViewControllers {
            addChildViewController(vc)
            vc.willMove(toParentViewController: self)
            items.append(TabItem(addTabContainer(), vc))
        }
        viewControllers += newViewControllers
        updateTabView(inserts: inserts, deletes: [])
    }

    public func removeViewControllers(indices: [Int]) {
        var deletes: [IndexPath] = []
        let orginalCount = viewControllers.count
        for index in indices {
            guard index < orginalCount else {
                continue
            }
            removeViewController(at: index)
            deletes.append(IndexPath(item: index, section: 0))
        }
        updateTabView(inserts: [], deletes: deletes)
    }

    private func removeViewController(at index: Int) {
        let viewController = viewControllers[index]
        viewController.willMove(toParentViewController: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
        viewControllers.remove(at: index)
    }

    private func updateTabView(inserts: [IndexPath], deletes: [IndexPath]) {
        tabView.collectionView.performBatchUpdates({
            self.tabView.collectionView.insertItems(at: inserts)
            self.tabView.collectionView.deleteItems(at: deletes)
        }, completion: { _ in
            if case .fitViewFrameWidth = self.tabSizing {
                self.tabView.collectionView.collectionViewLayout.invalidateLayout()
            }
            self.tabView.panToPercentage(self.scrolledPercentage)
        })
    }
    
    func addTabContainer() -> UIView {
        let firstTab = (items.count == 0)
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let width = NSLayoutConstraint(item: container, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0.0)
        let height = NSLayoutConstraint(item: container, attribute: .height, relatedBy: .equal, toItem: tabControllersView, attribute: .height, multiplier: 1.0, constant: 0.0)
        let top = NSLayoutConstraint(item: container, attribute: .top, relatedBy: .equal, toItem: tabControllersView, attribute: .top, multiplier: 1.0, constant: 0.0)
        let left: NSLayoutConstraint
        if firstTab {
            left = NSLayoutConstraint(item: container, attribute: .left, relatedBy: .equal, toItem: tabControllersView, attribute: .left, multiplier: 1.0, constant: 0.0)
        } else {
            left = NSLayoutConstraint(item: container, attribute: .left, relatedBy: .equal, toItem: items.last!.container, attribute: .right, multiplier: 1.0, constant: 0.0)
        }
        let right = NSLayoutConstraint(item: container, attribute: .right, relatedBy: .equal, toItem: tabControllersView, attribute: .right, multiplier: 1.0, constant: 0.0)
        
        if tabControllersViewRightConstraint != nil {
            tabControllersViewRightConstraint!.isActive = false
        }
        tabControllersViewRightConstraint = right
        
        tabControllersView.addSubview(container)
        NSLayoutConstraint.activate([width, height, top, left, right])
        return container
    }
    
    func lazyLoad(_ index: Int) {
        guard inRange(index) else { return }
        
        if shouldLoadTab(index) {
            loadTab(index)
        } else {
            unloadTab(index)
        }
    }
    
    func loadTab(_ index: Int) {
        guard inRange(index) else { return }
        guard shouldLoadTab(index) else { return }
        guard !loadedPages.contains(index) else { return }
        
        switch index {
        case loadedPages.lowerBound - 1:
            loadedPages = (index ..< loadedPages.upperBound)
        case loadedPages.upperBound:
            loadedPages = (loadedPages.lowerBound ..< index + 1)
        default:
            loadedPages = (index ..< index)
        }
        
        let container = items[index].container
        let child = items[index].controller

        child.view.translatesAutoresizingMaskIntoConstraints = false
        let width = NSLayoutConstraint(item: child.view, attribute: .width, relatedBy: .equal, toItem: container, attribute: .width, multiplier: 1.0, constant: 0.0)
        let height = NSLayoutConstraint(item: child.view, attribute: .height, relatedBy: .equal, toItem: container, attribute: .height, multiplier: 1.0, constant: 0.0)
        let top = NSLayoutConstraint(item: child.view, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0.0)
        let left = NSLayoutConstraint(item: child.view, attribute: .left, relatedBy: .equal, toItem: container, attribute: .left, multiplier: 1.0, constant: 0.0)

        addChildViewController(child)
        container.addSubview(child.view)
        NSLayoutConstraint.activate([width, height, top, left])
        child.didMove(toParentViewController: self)
    }
    
    func unloadTab(_ index: Int) {
        guard inRange(index) else { return }
        guard !shouldLoadTab(index) else { return }
        
        switch index {
        case loadedPages.lowerBound:
            loadedPages = ((index + 1) ..< loadedPages.upperBound)
        case loadedPages.upperBound - 1:
            loadedPages = (loadedPages.lowerBound ..< index)
        default:
            break
        }
        
        let child = items[index].controller
        child.willMove(toParentViewController: nil)
        child.view.removeFromSuperview()
        child.removeFromParentViewController()
    }
    
    func unloadTabs() {
        
    }
    
    func reloadData() {
        tabView.collectionView.reloadData()
        if items.count > 0 {
            tabView.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: UICollectionViewScrollPosition())
        }
    }
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCell", for: indexPath) as? ScrollingTabCell else {
            fatalError("Class for tab cells must be a subclass of the scrolling tab cell")
        }
        
        let viewController = viewControllers[(indexPath as NSIndexPath).item]
        cell.title = viewController.tabBarItem.title
        cell.theme = tabTheme

        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        switch tabSizing {
        case .fitViewFrameWidth, .fixedSize(_):
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.itemSize
            }
        case .sizeToContent:

            ScrollingTabController.sizingCell.frame.size = CGSize(width: 9999.0, height: tabView.frame.height)
            ScrollingTabController.sizingCell.contentView.frame = ScrollingTabController.sizingCell.bounds
            
            ScrollingTabController.sizingCell.title = viewControllers[(indexPath as NSIndexPath).row].tabBarItem.title
            ScrollingTabController.sizingCell.layoutIfNeeded()
            
            let size = ScrollingTabController.sizingCell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)

            return CGSize(width: size.width, height: tabView.frame.height)
        }

        return CGSize(width: 100.0, height: tabView.frame.height)
    }
    
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var view = UICollectionReusableView()
        if kind == ScrollingTabVerticalDividerType {
            view = collectionView.dequeueReusableSupplementaryView(ofKind: ScrollingTabVerticalDividerType, withReuseIdentifier: ScrollingTabVerticalDividerType, for: indexPath)
        }
        
        return view;
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectTab(atIndex: (indexPath as NSIndexPath).item, animated: true)
    }

    open func selectTab(atIndex index: Int, animated: Bool = true) {
        guard 0..<viewControllers.count ~= index else {
            return
        }

        if !isViewLoaded || !initialAppearanceComplete {
            deferredInitialSelectedPage = index
            return
        }

        // Tell the current view it is disappearing, scroll to the new page and tell that view
        // that it did appear
        childBeginAppearanceTransition(currentPage, isAppearing: false, animated: animated)
        previousPage = currentPage

        lazyLoad(index)
        childBeginAppearanceTransition(index, isAppearing: true, animated: animated)
        scrollToTab(atIndex: index, animated: animated)
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        updatingCurrentPage = false

        coordinator.animate(alongsideTransition: { _ in
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
        let width = tabControllersView.bounds.width
        guard width > 0 else {
            return
        }

        let page = Int(tabControllersView.contentOffset.x / width)
        if page != currentPage {

            // Tell the former current page that it is going to disappear
            childBeginAppearanceTransition(currentPage, isAppearing: false, animated: true)
            childEndAppearanceTransition(currentPage)

            currentPage = page
            
            for offset in 0...(numToPreload + 1) {
                lazyLoad(page + offset)
            }

            // Tell the new current page that it will appear
            childBeginAppearanceTransition(currentPage, isAppearing: true, animated: true)
            childEndAppearanceTransition(currentPage)
            
            delegate?.scrollingTabController(self, displayedViewControllerAtIndex: currentPage)
        }
    }

    /**
    Begins an appearance transition of the current page of the scrolling tab bar
    */
    func childBeginAppearanceTransition(_ index: Int, isAppearing: Bool, animated: Bool) {
        guard index >= 0 && index < viewControllers.count else {
            return
        }

        let child = viewControllers[index]
        child.beginAppearanceTransition(isAppearing, animated: animated)
    }

    /**
    Completes an appearance transition of the current page of the scrolling tab bar
    */
    func childEndAppearanceTransition(_ index: Int) {
        guard index >= 0 && index < viewControllers.count else {
            return
        }

        let child = viewControllers[index]
        child.endAppearanceTransition()
    }

    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == tabControllersView else {
            return
        }
        
        guard updatingCurrentPage else {
            return
        }
        
        if scrollView.isTracking {
            checkAndLoadPages()
        }
        
        tabView.panToPercentage(scrolledPercentage)
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            checkAndLoadPages()
        }
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        checkAndLoadPages()
    }
    
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        loadedPages = (currentPage ..< currentPage)
        lazyLoad(currentPage)
        jumpScroll = false

        childEndAppearanceTransition(currentPage)
        childEndAppearanceTransition(previousPage)
        
        // When scrolling with animation, not all items may be captured in the loadedPages interval.
        // This clears out any remaining views left on the scrollview.
        for index in 0..<items.count {
            unloadTab(index)
        }
    }

    // Internally scroll to a tab at a given index. This only handles the scroll and not management 
    // of the child view appearance
    func scrollToTab(atIndex index: Int, animated: Bool = true) {
        let rect = CGRect(x: CGFloat(index) * tabControllersView.bounds.width, y: 0, width: tabControllersView.bounds.width, height: tabControllersView.bounds.height)
        jumpScroll = true
        currentPage = index

        tabControllersView.setContentOffset(rect.origin, animated: animated)
        delegate?.scrollingTabController(self, displayedViewControllerAtIndex: index)
    }
    
    deinit {
        tabControllersView?.removeObserver(self, forKeyPath: contentSizeKeyPath, context: nil)
    }
    
    func shouldLoadTab(_ index: Int) -> Bool {
        return index >= (currentPage - numToPreload) && index <= (currentPage + numToPreload)
    }
    
    func inRange(_ index: Int) -> Bool {
        return index >= 0 && index < items.count
    }
}


