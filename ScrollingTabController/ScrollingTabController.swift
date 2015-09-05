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
    func numberOfItemsInController(controller: ScrollingTabController) -> Int
    func viewControllerAtIndexForController(controller: ScrollingTabController, index: Int) -> UIViewController?
}

public class ScrollingTabController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    public var tabView = ScrollingTabView()
    
    var viewControllerCache = NSCache()
    var collectionView: UICollectionView!
    var collectionViewLayout = TabFlowController()
    var childControllers = [UIViewController]()
    var scrollingStarted = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.buildViewControllers()
        self.navigationItem
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: self.collectionViewLayout)
        
        self.collectionView.registerClass(ScrollingViewControllerCell.classForCoder(), forCellWithReuseIdentifier: "Cell")
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.pagingEnabled = true
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.collectionView)
        
        self.tabView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.tabView)
        var tabConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[tabBar]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["tabBar": self.tabView])

        tabConstraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("V:|[tabBar]", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["tabBar": self.tabView]))
        let height = NSLayoutConstraint(item: self.tabView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 44.0)
        self.tabView.addConstraint(height)
        self.view.addConstraints(tabConstraints)


        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[collectionView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["collectionView": self.collectionView])
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[tabBar][collectionView]|", options:  NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["tabBar": self.tabView, "collectionView": self.collectionView])

        self.view.addConstraints(horizontalConstraints)
        self.view.addConstraints(verticalConstraints)
        
        self.collectionViewLayout.itemSize = self.collectionView.bounds.size
        self.collectionViewLayout.scrollDirection = .Horizontal

        // Do any additional setup after loading the view.
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func buildViewControllers() {
        for i in 1...100 {
            let viewController = TestingViewController()
            
            var color = UIColor.whiteColor()
            switch i % 5 {
            case 0:
                color = UIColor.redColor()
            case 1:
                color = UIColor.blueColor()
            case 2:
                color = UIColor.greenColor()
            case 3:
                color = UIColor.orangeColor()
            case 4:
                color = UIColor.purpleColor()
            default:
                color = UIColor.whiteColor()
            }
            viewController.view.backgroundColor = color
            
            self.childControllers.append(viewController)
        }
    }
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.childControllers.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! ScrollingViewControllerCell
        
        let viewController = self.childControllers[indexPath.item]
        
        if cell.viewController == nil || !(cell.viewController === viewController) {
            
            cell.parentViewController = self
            cell.viewController = viewController
            
            if let snapshot = self.viewControllerCache.objectForKey(indexPath) as? UIView {
                cell.snapshotView = snapshot
            }
        }

            
        return cell
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if (!scrollingStarted)
        {
            scrollingStarted = true
            for indexPath in self.collectionView.indexPathsForVisibleItems() {
                if let vcCell = self.collectionView.cellForItemAtIndexPath(indexPath) as? ScrollingViewControllerCell {
                    let snapshot = vcCell.snapshotViewAfterScreenUpdates(false)
                    self.viewControllerCache.setObject(snapshot, forKey: indexPath)
                }
            }
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollingStarted = false
        for cell in self.collectionView.visibleCells() {
            if let vcCell = cell as? ScrollingViewControllerCell {
                vcCell.loadViewController()
            }
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollingStarted = false
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

class TestingViewController: UIViewController {
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        usleep(1000)
    }
}