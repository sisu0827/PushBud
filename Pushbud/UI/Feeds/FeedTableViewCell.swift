//
//  FeedTableViewCell.swift
//  Pushbud
//
//  Created by Daria.R on 16/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class FeedTableViewCell: UITableViewCell, UITextViewDelegate {

    private var imagePath: String!
    private var feed: Feed?
    private var imageUri: String?
    
    @IBOutlet var imageContainer: UIView!
    private let imgFeed = UIImageView(image: UIImage(named: "pixel"))
    private let imgFeedIndicatorViewTag = 29
    private var imageHeightConstraint: NSLayoutConstraint!
    private var imageWidthConstraint: NSLayoutConstraint!
    private let imgFeedWidthMin = Constants.screenSize.width
    private let imgFeedHeightMin = min(Constants.screenSize.width * 1.25, 250)
    
    @IBOutlet var userView: UIView!
    @IBOutlet var imgUser: AvatarImageView!
    @IBOutlet var lblUser: UILabel!
    @IBOutlet var txtSlug: UITextView!
    
    @IBOutlet var txtSlugHeight: NSLayoutConstraint!
    
    @IBOutlet var lblLikes: UILabel!
    @IBOutlet var lblDate: UILabel!
    
    @IBOutlet var bottomBar: UIView!
    @IBOutlet var btnComment: UIButton!
    @IBOutlet var btnLike: UIButton!
    @IBOutlet var btnReport: UIButton!
    @IBAction func onGoMapLoc(_ sender: UIButton) {
        print("map button click")
        self.feedsVC?.showMapView()
    }
    
    private let btnMenu = UIButton()
    
    var btnMapPin = UIButton()
    
    var feedsVC: FeedsViewController? {
        let navVC = (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController as? UINavigationController
        return navVC?.topViewController as? FeedsViewController
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.isUserInteractionEnabled = true
        
        self.imageContainer.addConstraint(NSLayoutConstraint(item: imageContainer, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: imgFeedWidthMin))
        self.imageContainer.addTarget(target: self, action: #selector(zoomAction))
        
        self.lblUser.superview?.addTarget(target: self, action: #selector(profileAction))
        
        self.imgFeed.contentMode = .scaleAspectFit
        self.imgFeed.translatesAutoresizingMaskIntoConstraints = false
        self.imageContainer.addSubview(imgFeed)
        self.imageWidthConstraint = NSLayoutConstraint(item: imgFeed, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1)
        self.imageHeightConstraint = NSLayoutConstraint(item: imgFeed, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1)
        self.contentView.addConstraints([self.imageWidthConstraint, self.imageHeightConstraint,
            NSLayoutConstraint(item: imgFeed, attribute: .centerX, relatedBy: .equal, toItem: imageContainer, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: imgFeed, attribute: .centerY, relatedBy: .equal, toItem: imageContainer, attribute: .centerY, multiplier: 1.0, constant: 0)])
        
        self.txtSlug.delegate = self

        btnMenu.addTarget(self, action: #selector(menuAction(_:)), for: .touchUpInside)
        btnMenu.tintColor = .white
        btnMenu.setImage(UIImage(named: "dropdown")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btnMenu.contentEdgeInsets = UIEdgeInsetsMake(5, 8, 5, 8)
        btnMenu.translatesAutoresizingMaskIntoConstraints = false
        self.userView.addSubview(btnMenu)
        self.userView.addConstraints([
            NSLayoutConstraint(item: userView, attribute: .trailing, relatedBy: .equal, toItem: btnMenu, attribute: .trailing, multiplier: 1.0, constant: 8.0),
            NSLayoutConstraint(item: btnMenu, attribute: .centerY, relatedBy: .equal, toItem: userView, attribute: .centerY, multiplier: 1.0, constant: 0)
        ])
        
        // map pin button add
        btnMapPin.setImage(#imageLiteral(resourceName: "feed_map_icon2"), for: .normal)
        btnMapPin.contentEdgeInsets = UIEdgeInsetsMake(5, 8, 5, 8)
        btnMapPin.translatesAutoresizingMaskIntoConstraints = false
        self.userView.addSubview(btnMapPin)
        self.userView.addConstraints([
            NSLayoutConstraint(item: userView, attribute: .trailing, relatedBy: .equal, toItem: btnMapPin, attribute: .trailing, multiplier: 1.0, constant: 8.0),
            NSLayoutConstraint(item: btnMapPin, attribute: .centerY, relatedBy: .equal, toItem: userView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnMapPin, attribute: .leftMargin, relatedBy: .equal, toItem: userView, attribute: .leadingMargin, multiplier: 1.0, constant: 10.0),
//            NSLayoutConstraint(item: btnMapPin, attribute: .rightMargin, relatedBy: .equal, toItem: userView, attribute: .leadingMargin, multiplier: 1.0, constant: 10.0)
        ])
        
        let _colorOverlay = UIView()
        _colorOverlay.alpha = 0.85
        _colorOverlay.backgroundColor = self.userView.backgroundColor
        _colorOverlay.isOpaque = false
        _colorOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.userView.insertSubview(_colorOverlay, at: 0)
        Helper.addConstraints(["H:|-0-[v]-0-|", "V:|-0-[v]-0-|"], source: userView, views: ["v":_colorOverlay])
        
        let _whiteOverlay = UIView()
        _whiteOverlay.backgroundColor = UIColor(white: 0.97, alpha: 0.5)
        _whiteOverlay.isOpaque = false
        _whiteOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.userView.insertSubview(_whiteOverlay, at: 0)
        Helper.addConstraints(["H:|-0-[v]-0-|", "V:|-0-[v]-0-|"], source: userView, views: ["v":_whiteOverlay])
        
        self.lblLikes.addTarget(target: self, action: #selector(likeAction))
        self.lblLikes.isUserInteractionEnabled = true
        
        let separator = CALayer()
        separator.backgroundColor = Theme.Light.separator
        separator.frame.size = CGSize(width: Constants.screenSize.width, height: 1.0)
        self.bottomBar.layer.addSublayer(separator)
        
        let btnCommentSeparator = CALayer()
        btnCommentSeparator.frame = CGRect(x: 0, y: 0, width: 0.5, height: 44)
        btnCommentSeparator.backgroundColor = Theme.Light.separator
        self.btnComment.layer.addSublayer(btnCommentSeparator)
        
        self.btnReport.isHidden = true // Hidden until next version
//        self.btnReport.image = UIImage(named: "report")
//        self.btnReport.tintColor = .red
//        self.btnReport.setImage(UIImage(named: "report")?.withRenderingMode(.alwaysTemplate), for: UIControlState.selected)
        
//        self.imagePath = ImageClient.scaledUriParam(CGSize(width: Constants.screenSize.width, height: 200))

        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
        
        // Shadow
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        self.layer.shadowOpacity = 0.3
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.imageUri = ""
        self.feed = nil
        
        self.btnLike.layer.removeAllAnimations()
        
        btnLike.tag = 0
//        btnReport.tag = 0
        
        self.imgFeed.alpha = 0
        self.imgUser.reset()
        self.imageContainer.viewWithTag(self.imgFeedIndicatorViewTag)?.removeFromSuperview()
    }
    
    // MARK: - Private
    private func setImage(_ image: UIImage, animated: Bool = false) {
        let imageSize = image.size
        
        var ratio  = imageSize.width / self.imgFeedWidthMin
        var width = imageSize.width / ratio
        var height = imageSize.height / ratio

        if (width < self.imgFeedWidthMin || height < self.imgFeedHeightMin) {
            ratio = imageSize.height / self.imgFeedHeightMin
            width = imageSize.width / ratio
            height = imageSize.height / ratio
        }
        
        self.imageWidthConstraint.constant = width
        self.imageHeightConstraint.constant = height
        self.imgFeed.image = image
        
        guard animated else { return }
        
        self.imgFeed.alpha = 0
        UIView.animate(withDuration: 0.3) { self.imgFeed.alpha = 1 }
    }
    
    // MARK: - Actions
    func zoomAction() {
        if let feed = self.feed {
            self.feedsVC?.showGallery(feed)
        }
    }
    
    func profileAction() {
        self.feedsVC?.showUserProfile(for: self.feed?.user)
    }
    
    func menuAction(_ sender: UIButton) {
        self.feedsVC?.friendMenu(at: self.userView.tag - 1, sender: sender)
    }
    
    @IBAction func likeAction() {
        guard self.btnLike.tag == 0, let feed = self.feed else { return }

        self.btnLike.tag = 1
        self.btnLike.addPulseAnimation()
        
        self.feedsVC?.toggleLike(for: feed.id, newValue: !feed.isLike)
    }
    
    @IBAction func commentAction() {
        if let feedId = self.feed?.id {
            self.feedsVC?.showComments(for: feedId)
        }
    }
    
    /* @IBAction func reportAction() {
        guard (self.feed != nil && self.btnReport.tag == 0) else { return }
        
        self.btnReport.tag = 1
        
        self.feedsVC?.toggleReport(for: self.feed!.id, newValue: !self.feed!.isReport)
    }
    
    @IBAction func userAction() {
        guard (self.feed != nil && self.btnUserProgress == nil) else { return }

        self.btnUserWidth = NSLayoutConstraint(item: self.btnUser, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.btnUser.bounds.width)
        self.btnUser.addConstraint(self.btnUserWidth!)
        self.btnUserProgress = self.btnUser.addProgress()
        self.btnUser.setTitle(nil, for: .normal)
        self.feedsVC?.toggleUser(in: self.feed!)
    } */

    func setData(_ feed: Feed, text: NSAttributedString) {
        self.imageUri = "1080/" + feed.pictureUrl
        if let image = ImageClient.shared.getCached(imageUri!) {
            self.setImage(image)
            self.imgFeed.alpha = 1
        } else {
            if (self.imageContainer.viewWithTag(self.imgFeedIndicatorViewTag) == nil) {
                self.imageContainer.addProgress().tag = self.imgFeedIndicatorViewTag
            }
            
            ImageClient.shared.download(imageUri!) { [weak self] image, url, loadedFromCache in
                
                guard let tag = self?.imgFeedIndicatorViewTag else { return }
                
                self!.imageContainer.viewWithTag(tag)?.removeFromSuperview()
                
                if (image != nil && self!.imageUri == url) {
                    self!.setImage(image!, animated: true)
                }
            }
        }

        let profile = feed.user
        self.btnMenu.isHidden = (!profile.isFriend || profile.id == Config.userProfile?.id)

        self.imgUser.setupAvatar(profile.picture, text: profile.name, textColor: .lightGray)
        self.lblUser.text = profile.name
        
        self.txtSlug.attributedText = text
        self.txtSlugHeight.constant = text.height(considering: Constants.screenSize.width - 16) + 18
        
        if feed.likes > 0 {
            self.lblLikes.text = String(format: FeedTerm.numberOfLikes, feed.likes)
        } else {
            self.lblLikes.text = ""
        }
        
        if feed.comments > 0 {
            self.btnComment.setTitle(String(format: FeedTerm.numberOfComments, feed.comments), for: .normal)
        } else {
            self.btnComment.setTitle(nil, for: .normal)
        }
        
        self.lblDate.text = feed.date.toReadable
//        self.btnReport.isSelected = feed.isReport
        self.btnLike.setImage(UIImage(named: feed.isLike ? "like_on" : "like_off"), for: .normal)
        
        self.feed = feed
    }
    
    // MARK: - TextView delegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if URL.scheme != nil, let tagId = Int(URL.scheme!), let tag = self.feed?.tags?.filter( { $0.id == tagId } ).first {
            self.feedsVC?.filterEvents(by: tag)
        }
        return false
    }
}
