//
//  GalleryFlowLayout.swift
//  Pushbud
//
//  Created by Daria.R on 7/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class GalleryFlowLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        self.itemSize = UIScreen.main.bounds.size
        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 0
        self.minimumLineSpacing = 0
        self.sectionInset = UIEdgeInsets.zero
        self.footerReferenceSize = CGSize.zero
        self.headerReferenceSize = CGSize.zero
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard super.shouldInvalidateLayout(forBoundsChange: newBounds) else {
            return false
        }
        
        invalidateLayout()
        return true
    }
    
}
