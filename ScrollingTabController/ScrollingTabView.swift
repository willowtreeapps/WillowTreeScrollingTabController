//
//  ScrollingTabView.swift
//  ScrollingTabControllerExample
//
//  Created by Erik LaManna on 9/4/15.
//  Copyright © 2015 WillowTree, Inc. All rights reserved.
//

import UIKit

public class ScrollingTabViewFlowLayout: UICollectionViewFlowLayout {

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
}

public class ScrollingTabView: UICollectionView {
    
    public convenience init()
    {
        self.init(frame: CGRectZero, collectionViewLayout: ScrollingTabViewFlowLayout())
        self.backgroundColor = UIColor.whiteColor()
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
        self.registerClass(ScrollingTabCell.classForCoder(), forCellWithReuseIdentifier: "TabCell")
        
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
    }
}
