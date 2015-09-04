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
class ScrollingTabController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var viewControllerCache = NSCache()
    var collectionView: UICollectionView!
    var collectionViewLayout = TabFlowController()
    var childControllers = [UIViewController]()
    var scrollingStarted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.buildViewControllers()
        self.navigationItem
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: self.collectionViewLayout)
        
        self.collectionView.registerClass(ScrollingViewControllerCell.classForCoder(), forCellWithReuseIdentifier: "Cell")
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.pagingEnabled = true
        self.view.addSubview(self.collectionView)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[collectionView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["collectionView": self.collectionView])
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView]|", options:  NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["collectionView": self.collectionView])

        self.view.addConstraints(horizontalConstraints)
        self.view.addConstraints(verticalConstraints)
        
        self.collectionViewLayout.itemSize = self.collectionView.bounds.size
        self.collectionViewLayout.scrollDirection = .Horizontal

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
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
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.childControllers.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
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
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
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
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollingStarted = false
        for cell in self.collectionView.visibleCells() {
            if let vcCell = cell as? ScrollingViewControllerCell {
                vcCell.loadViewController()
            }
        }
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
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