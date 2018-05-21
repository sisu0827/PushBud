//
//  ProfileViewController.swift
//  PushBud
//
//  Created by Daria.R on 31/10/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit
import ObjectMapper

class ProfileViewController: UIViewController {

    fileprivate enum AlertAction: Int {
        case quit = 1, reloadData, unfollow
    }
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var imgUser: AvatarImageView!
    @IBOutlet var imgUserWidth: NSLayoutConstraint!

    private var dummyConstraints: [NSLayoutConstraint]?
    
    var user: UserExtended!
    
    fileprivate var tags: [Tag]? {
        didSet {
            self.setupTagsUI()
        }
    }

    private let statsView = UIView()
    private let busyTag = 7
    private let actionViewTag = 8
    private var actionView: UIView? {
        let button = UIButton()
        button.layer.cornerRadius = 3.0
        button.setTitleColor(UIColor(white: 1.0, alpha: 0.6), for: .normal)
        button.titleLabel?.font = Theme.Font.light.withSize(16)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 16.0)

        let isSelf = (user.id == Config.userProfile?.id)
        guard (!isSelf && !user.isFriend) else {
            if (isSelf) {
                button.setTitle(LocStr("EditProfile"), for: .normal)
                button.addTarget(self, action: #selector(editAccount), for: .touchUpInside)
            } else {
                button.setTitle(LocStr("User.Following"), for: .normal)
                button.addTarget(self, action: #selector(friendMenu), for: .touchUpInside)
            }
            
            button.backgroundColor = UIColor(red: 0.054902, green: 0.133333, blue: 0.227451, alpha: 1.0) // 0E223A
            return button
        }
        
        if (user.isInvitation) {
            guard (user.isInvitor) else { return nil }

            button.setTitle(LocStr("User.Invited"), for: .normal)
            button.layer.borderColor = UIColor(white: 1.0, alpha: 0.5).cgColor
        } else {
            button.setImage(UIImage(named: "user_invite"), for: .normal)
            button.setTitle(LocStr("User.Follow"), for: .normal)
            button.addTarget(self, action: #selector(inviteAction) , for: .touchUpInside)
            button.layer.borderColor = UIColor(white: 1.0, alpha: 0.8).cgColor
        }

        button.layer.borderWidth = 1.5
        
        return button
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.user.name
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(closeAction))

        self.dummyConstraints = [
            NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: imgUser.superview, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: imgUser, attribute: .bottom, multiplier: 1.0, constant: 24.0)
        ]
        self.contentView.addConstraints(self.dummyConstraints!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.setupBaseUI()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // MARK:- Actions
    func closeAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func editAccount() {
        let accountVC = AccountViewController()
        accountVC.profile = Config.userProfile
        self.navigationController?.pushViewController(accountVC, animated: true)
    }
    
    func friendMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = Theme.Dark.textColor
        alert.addAction(UIAlertAction(title: LocStr("Friendship.Delete"), style: .destructive, handler: {_ in
            self.removeConnection()
        }))
        alert.addAction(UIAlertAction(title: LocStr("Cancel"), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func eventsAction() {
        let viewController = FeedsViewController(dataSource: nil, filter: .global, index: nil, userId: self.user.id)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func tagAction(_ sender: UIView) {
        guard let index = self.tags?.index(where: { $0.id == sender.tag }) else { return }

        let viewController = FeedsViewController(dataSource: nil, filter: .global, index: nil, filterTag: self.tags![index])
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func inviteAction() {
        self.userSet(invitation: false, invite: true)
    }
    
    func acceptAction() {
        self.userSet(invitation: true)
    }
    
    func declineAction() {
        self.userSet(invitation: false)
    }
    
    // MARK:- Private
    fileprivate func userSet(invitation: Bool, invite: Bool = false, remove: Bool = false) {
        LoaderOverlay.shared.show()

        let handler: (Result<Bool, NSError?>) -> () = { [weak self] result in
            
            guard let topView = self?.imgUser.superview else { return }
            
            switch result {
            case .Success:
                if (remove) {
                    self!.user.isFriend = false
                    self!.user.isInvitor = false
                    self!.user.isInvitation = false
                } else if (invite) {
                    self!.user.isInvitor = true
                    self!.user.isInvitation = true
                } else if (invitation) {
                    self!.user.isFriend = true
                } else {
                    self!.user.isInvitation = false
                    self!.user.isInvitor = false
                }
                self!.setupActionView(in: topView)
                LoaderOverlay.shared.tick()
            case .Failure(let error):
                LoaderOverlay.shared.hide()
                self!.apiFailure(with: error)
            }
        }

        if (remove) {
            if let id = self.user.friendshipId {
                UserManager.removeFriendship(id, callback: handler)
            }
        } else if (invite) {
            UserManager.addConnection(self.user.id, callback: handler)
        } else if let id = self.user.friendshipId {
            UserManager.toggleInvitation(id, value: invitation, callback: handler)
        }
    }
    
    private func removeConnection() {
        let alert = String(format: LocStr("UnfollowAlert"), user.name)
        let viewController = AlertViewController(alert, text: nil, actions: [
            AlertActionCase(actionCase: AlertAction.unfollow.rawValue, title: "OK"),
            AlertActionCase(actionCase: 0, title: LocStr("Cancel"))])
        
        viewController.delegate = self
        self.present(viewController, animated: true)
    }
    
    fileprivate func apiFailure(with error: NSError?) {
        if (error?.isNetworkError == true) {
            UserMessage.shared.show(LocStr("Error.NoNetworkTitle"), body: LocStr("Error.NoNetworkTip"))
        } else {
            UserMessage.shared.show(LocStr("Failure"), body: LocStr("Error.Unexpected"))
        }
    }
    
    fileprivate func loadData() {
        let url = APIClient.baseURL + "profile?user_id=\(self.user.id)"
        HTTP.New(url, type: .GET, headers: APIClient.Headers).start { [weak self] response in
            
            guard let strongSelf = self else { return }
            
            let statusCode = response.statusCode ?? 0
            let dict = response.data.jsonObject() as? [String: Any]
            
            if (Config.IsDevelopmentMode) {
                print("Profile-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            guard (statusCode == 200 && dict != nil)
//                , let user = try? Mapper<UserExtended>().map(JSON: dict!)
                else {
                if (response.error?.isNetworkError == true) {
                    Helper.alertNoNetRetry(strongSelf, retryCase: AlertAction.reloadData.rawValue, cancelCase: AlertAction.quit.rawValue)
                } else {
                    UserMessage.shared.show(LocStr("Failure"), body: LocStr("Error.Unexpected"))
                    response.error?.record()
                }
                return
            }

//            strongSelf.user = user
            
            let postsCount = dict!["events_count"] as? Int
            let tagsCount = dict!["tags_count"] as? Int
            let friendsCount = dict!["friends_count"] as? Int
            strongSelf.setupUI(postsCount: postsCount ?? 0, tagsCount: tagsCount ?? 0, friendsCount: friendsCount ?? 0)
            if let array = dict!["tags"] as? [[String : Any]], let tags = try? Mapper<Tag>().mapArray(JSONArray: array), !tags.isEmpty {
                strongSelf.tags = tags
            } else {
                strongSelf.loadPopularTags()
            }
        }
    }
    
    private func loadPopularTags() {
        TagManager.getPopularTags(withLimit: 8) { [weak self] result in
            switch result {
            case .Success(let tags):
                self?.tags = tags
            case .Failure:
                self?.tags = self?.tags ?? []
            }
        }
    }

    private func setupBaseUI() {
        guard let topView = self.imgUser.superview as? GradientView else { return }
        
        topView.gradientColors = [
            UIColor(red: 0.16, green: 0.33, blue: 0.48, alpha: 1.0).cgColor, //29557B
            UIColor(red: 0.121569, green: 0.239216, blue: 0.360784, alpha: 1.0).cgColor //1F3D5C
        ]
        
        let imageSize = min(Constants.screenSize.width * 0.56, 400.0)
        self.imgUserWidth.constant = imageSize
        self.imgUser.targetSize = imageSize
        self.imgUser.setupAvatar(self.user.picture, text: self.user.name, textColor: UIColor(white: 1.0, alpha: 0.4), animated: false)
        
        let yPos = imageSize + 48.0
        let progressView = UIView(frame: CGRect(x: 0, y: yPos, width: Constants.screenSize.width, height: self.view.frame.height - yPos))
        progressView.tag = self.busyTag
        self.view.addSubview(progressView)
        Helper.addProgress(in: progressView, style: .gray)
        
        self.loadData()
    }
    
    private func setupTagsUI() {
        self.view.viewWithTag(busyTag)?.removeFromSuperview()
        
        guard let tags = self.tags, !tags.isEmpty else { return }

        let tagsView = UIView()
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(tagsView)

//        let messageText = LocStr("User.NotFollowingTags") + "\n"
        
        let margin: CGFloat = 24.0
        let maxWidth = Constants.screenSize.width - (margin * 2)
        let horizontalSpacing: CGFloat = 16.0
        let verticalSpacing: CGFloat = 16.0
        let cellHeight: CGFloat = 38.0
        let buttonFont = Theme.Font.light.withSize(16)
        
        var availableWidth = maxWidth
        var nextOrigin = CGPoint(x: 0, y: 0)
        var lastY: CGFloat!
        
        for tag in tags {
            let button = UIButton()
            button.addTarget(self, action: #selector(tagAction(_:)), for: .touchUpInside)
            button.backgroundColor = UIColor(red: 0.945098, green: 0.945098, blue: 0.945098, alpha: 1.0) // F1F1F1
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            button.setTitle("#" + tag.name, for: .normal)
            button.setTitleColor(Theme.Dark.textColor, for: .normal)
            button.tag = tag.id
            button.titleLabel?.font = buttonFont
            button.sizeToFit()
            button.frame.size.height = cellHeight
            button.layer.cornerRadius = 18.0

            if (button.frame.width > availableWidth) {
                if (availableWidth == maxWidth) {
                    button.frame.origin = nextOrigin
                    button.frame.size.width = maxWidth
                    nextOrigin = CGPoint(x: 0, y: nextOrigin.y + cellHeight + verticalSpacing)
                } else {
                    nextOrigin = CGPoint(x: 0, y: nextOrigin.y + cellHeight + verticalSpacing)
                    button.frame.origin = nextOrigin

                    let nextX = button.frame.width + horizontalSpacing
                    nextOrigin.x += nextX
                    availableWidth = maxWidth - nextX
                }
            } else {
                button.frame.origin = nextOrigin

                let nextX = button.frame.width + horizontalSpacing
                nextOrigin.x += nextX
                availableWidth -= nextX
            }
            
            lastY = button.frame.origin.y
            tagsView.addSubview(button)
        }
        
        let height = lastY + cellHeight + margin
        Helper.addConstraints(["H:|-\(Int(margin))-[tv]-0-|", "V:[tv(\(Int(height)))]-0-|"], source: self.contentView, views: ["tv": tagsView])
        
        self.contentView.addConstraint(NSLayoutConstraint(item: tagsView, attribute: .top, relatedBy: .equal, toItem: statsView, attribute: .bottom, multiplier: 1.0, constant: margin))
    }
    
    private func setupUI(postsCount: Int, tagsCount: Int, friendsCount: Int) {
        if let constraints = self.dummyConstraints {
            self.contentView.removeConstraints(constraints)
            self.dummyConstraints = nil
        }
        
        self.statsView.backgroundColor = UIColor(red: 0.898039, green: 0.898039, blue: 0.898039, alpha: 1.0) // E5E5E5
        self.statsView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(statsView)
        Helper.addConstraints(["H:|-0-[sv]-0-|", "V:[sv(64)]"], source: contentView, views: ["sv": statsView])

        let labels: [(label: String, count: Int)] = [
            ("User.PostsTitle", postsCount),
            ("User.TagsTitle", tagsCount),
            ("User.FriendsTitle", friendsCount)
        ]

        for i in 0...2 {
            let label = UILabel()
            label.numberOfLines = 0
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            
            let count = String(labels[i].count)
            let chars = count.characters.count
            let attrStr = NSMutableAttributedString(string: count + "\n" + LocStr(labels[i].label), attributes: [
                NSFontAttributeName: Theme.Font.medium.withSize(18),
                NSForegroundColorAttributeName: i == 1 ? UIColor.gray : UIColor.lightGray])
            attrStr.addAttributes([
                NSFontAttributeName: Theme.Font.bold.withSize(18),
                NSForegroundColorAttributeName: Theme.Dark.textColor], range: NSRange(location: 0, length: chars))
            attrStr.addAttribute(NSFontAttributeName, value: Theme.Font.light.withSize(8), range: NSRange(location: chars, length: 1))
            label.attributedText = attrStr
            
            guard (i != 1) else {
                statsView.addSubview(label)
                statsView.addConstraints([
                    NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: statsView, attribute: .centerX, multiplier: 1.0, constant: 0),
                    NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: statsView, attribute: .centerY, multiplier: 1.0, constant: 0)])
                continue
            }

            let view = UIView()
            if (i == 0 && self.user.isFriend) {
                view.addTarget(target: self, action: #selector(eventsAction))
            }
            view.backgroundColor = .white
            view.translatesAutoresizingMaskIntoConstraints = false
            statsView.addSubview(view)

            let attrib: NSLayoutAttribute = i == 0 ? .leading : .trailing
            statsView.addConstraints([
                NSLayoutConstraint(item: view, attribute: attrib, relatedBy: .equal, toItem: statsView, attribute: attrib, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: statsView, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: statsView, attribute: .width, multiplier: 0.33, constant: 0),
                NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: statsView, attribute: .bottom, multiplier: 1.0, constant: -1.0)])

            view.addSubview(label)
            view.addConstraints([
                NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)])
        }
        
        let tagsView = UIView()
        tagsView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(tagsView)
        Helper.addConstraints(["H:|-0-[tv]-0-|", "V:[tv]-0-|"], source: contentView, views: ["tv": tagsView])
        self.contentView.addConstraint(NSLayoutConstraint(item: tagsView, attribute: .top, relatedBy: .equal, toItem: statsView, attribute: .bottom, multiplier: 1.0, constant: 0))
        
        guard let topView = self.imgUser.superview else { return }

        self.contentView.addConstraint(NSLayoutConstraint(item: statsView, attribute: .top, relatedBy: .equal, toItem: topView, attribute: .bottom, multiplier: 1.0, constant: 0))
        
        self.setupActionView(in: topView)
    }

    private func setupActionView(in topView: UIView) {
        if let actionView = topView.viewWithTag(self.actionViewTag) {
            actionView.removeFromSuperview()
        }
        
        let actionView: UIView = self.actionView ?? UIView()
        actionView.tag = self.actionViewTag
        actionView.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(actionView)
        topView.addConstraints([
            NSLayoutConstraint(item: actionView, attribute: .top, relatedBy: .equal, toItem: imgUser, attribute: .bottom, multiplier: 1.0, constant: 16.0),
            NSLayoutConstraint(item: actionView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40.0),
            NSLayoutConstraint(item: actionView, attribute: .centerX, relatedBy: .equal, toItem: topView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: topView, attribute: .bottom, relatedBy: .equal, toItem: actionView, attribute: .bottom, multiplier: 1.0, constant: 16.0)])
        
        guard !(actionView is UIButton) else { return }
        
        topView.addConstraint(NSLayoutConstraint(item: actionView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 96.0))
        
        let btnAccept = UIButton()
        btnAccept.backgroundColor = UIColor(red: 0.0, green: 0.709804, blue: 0.0352941, alpha: 1.0) // 00B509
        btnAccept.setImage(UIImage(named: "profile_accept"), for: .normal)
        btnAccept.addTarget(target, action: #selector(acceptAction), for: .touchUpInside)
        
        let btnDecline = UIButton()
        btnDecline.backgroundColor = Theme.destructiveBackgroundColor
        btnDecline.setImage(UIImage(named: "profile_decline"), for: .normal)
        btnDecline.addTarget(target, action: #selector(declineAction), for: .touchUpInside)
        
        for btn in [btnAccept, btnDecline] {
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.layer.cornerRadius = 20
            actionView.addSubview(btn)
        }
        
        topView.addConstraints([
            NSLayoutConstraint(item: btnAccept, attribute: .leading, relatedBy: .equal, toItem: actionView, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnDecline, attribute: .trailing, relatedBy: .equal, toItem: actionView, attribute: .trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnAccept, attribute: .top, relatedBy: .equal, toItem: actionView, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnDecline, attribute: .top, relatedBy: .equal, toItem: actionView, attribute: .top, multiplier: 1.0, constant: 0)])
    }
}

extension ProfileViewController: AlertViewControllerDelegate {
    
    func alertAction(_ actionCase: Int) {
        guard let m = AlertAction(rawValue: actionCase) else { return }
        
        switch m {
        case .quit:
            self.closeAction()
        case .reloadData:
            self.loadData()
        case .unfollow:
            self.userSet(invitation: false, remove: true)
        }
    }
    
}
