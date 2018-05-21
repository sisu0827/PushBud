//
//  GalleryViewController.swift
//  Pushbud
//
//  Created by Daria.R on 7/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

protocol GalleryDataSource {
    func imageInGallery(at: Int) -> String
}

class GalleryViewController: UIViewController {

    var dataSource: GalleryDataSource?
    var numberOfImages: Int {
        get {
            return collectionView(self.collectionView, numberOfItemsInSection: 0)
        }
        set {
            self.numberOfImagesInGallery = newValue
        }
    }
    
    fileprivate var numberOfImagesInGallery = 0
    
    lazy var collectionView: UICollectionView = self.setupCollectionView(rect: UIScreen.main.bounds)
    
    var backgroundColor: UIColor {
        get {
            return view.backgroundColor!
        }
        set {
            view.backgroundColor = newValue
        }
    }
    
    private var pageBeforeRotation = 0
    fileprivate let flowLayout = GalleryFlowLayout()
    
    private var orientation: UIInterfaceOrientation = .unknown
    
    // MARK: Public Interface
    init(dataSource: GalleryDataSource, count: Int) {
        super.init(nibName: nil, bundle: nil)
        
        self.dataSource = dataSource
        self.numberOfImagesInGallery = count
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var prefersStatusBarHidden : Bool {
        if let navVC = self.navigationController {
            if (navVC.isNavigationBarHidden || (UIDevice.current.userInterfaceIdiom == .phone && UIInterfaceOrientationIsLandscape(orientation))) {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.view.backgroundColor = UIColor.black
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        singleTap.numberOfTapsRequired = 1
        singleTap.delegate = self
        self.collectionView.addGestureRecognizer(singleTap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Actions
    func tapAction() {
        if let navVC = self.navigationController {
            navVC.setNavigationBarHidden(!navVC.isNavigationBarHidden, animated: true)
            self.setNeedsStatusBarAppearanceUpdate()
        } else {
            self.closeAction()
        }
    }
    
    func closeAction() {
        if let navVC = self.navigationController {
            navVC.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: Private
    private func setupCollectionView(rect: CGRect) -> UICollectionView {
        let collectionView = UICollectionView(frame: rect, collectionViewLayout: self.flowLayout)
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: "GalleryCell")
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = UIColor.clear
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(collectionView)
        self.view.sendSubview(toBack: collectionView)
        
        return collectionView
    }
}

extension GalleryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: DataSource Methods
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ imageCollectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.numberOfImagesInGallery
    }
    
    func collectionView(_ imageCollectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let url = self.dataSource?.imageInGallery(at: indexPath.row) else { return UICollectionViewCell() }
        
        let cell = imageCollectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! GalleryCell
        
        if let image = ImageClient.shared.getCached("1080/" + url) {
            cell.image = image
        } else {
            cell.downloadImage("1080/" + url)
        }
        
        return cell
    }
}

extension GalleryViewController: UIGestureRecognizerDelegate {
    
    // MARK: UIGestureRecognizerDelegate Methods
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer is UITapGestureRecognizer &&
            gestureRecognizer is UITapGestureRecognizer &&
            otherGestureRecognizer.view is GalleryCell &&
            gestureRecognizer.view == self.collectionView
    }
    
}
