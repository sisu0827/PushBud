//
//  FeedsViewController.swift
//  PushBud
//
//  Created by Daria.R on 16/04/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit
import ObjectMapper
import SVPullToRefresh

enum FeedFilterType: Int {
    case map = 1, global, friends, own
    var value: String? {
        switch self {
        case .map, .global:
            return nil
        case .friends:
            return "friends"
        case .own:
            return "self"
        }
    }
}

class FeedsViewController: UIViewController, CircleTransitionType {

    var circleView: UIView {
        return self.view.viewWithTag(btnCreateFeedTag) ?? self.view
    }
    
    fileprivate enum AlertAction: Int {
        case loadData = 1, unfollow
    }
    
    private struct FilterItem {
        let tag: FeedFilterType
        let text: String
    }

    private let btnCreateFeedTag = 27
    fileprivate let cellIdentifier = "FeedsCell"
    fileprivate let tableView = UITableView(frame: .zero, style: .grouped)
    fileprivate var bgView: UIView?
    fileprivate var popularTags: [Tag]?
    
    // MARK: - DataSource & Filtering
    fileprivate let tagsHelper = HashTagHelper()
    fileprivate let dataSource: MapDataSource?
    private let filters: [FilterItem]
    private let filterUserId: Int?
    private var filterTag: [Tag]

    fileprivate var items: [Feed]?
    fileprivate var total: Int? {
        didSet {
            guard let iTotal = self.total, let iCount = self.items?.count else { return }
            
            if (iTotal - iCount > 0) {
                self.newPage += 1
            } else {
                self.tableView.showsInfiniteScrolling = false
            }
            self.tableView.reloadData()
        }
    }
    private var selectedFilter: FeedFilterType {
        didSet {
            if (selectedFilter == .map) {
                self.tableView.showsInfiniteScrolling = false
            } else {
                self.loadData(byResettingPagination: true)
            }
        }
    }

    fileprivate var currentActionEvent: Feed!
    fileprivate var currentActionUser: UserExtended!
    
    fileprivate var newPage = 0
    fileprivate var indexToReload: Int?
    fileprivate var indexToScroll: Int?
    
    private var dropMenu: DropMenuView!
    
    var isCameraOn = false {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    private let pagerView = UIScrollView()
    private let searchBar = UISearchBar()

    override var prefersStatusBarHidden: Bool {
        return self.isCameraOn
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    // MARK: - LifeStyle
    init(dataSource: MapDataSource?, filter: FeedFilterType, index: Int?, filterTag: Tag? = nil, userId: Int? = nil) {
//        self.mediaManager.delegate = self
//        let imageWidth = Constants.screenSize.width * Constants.screenScale
//        self.imagePath = "tr:w-\(Int(imageWidth)),h-\(Int(imageWidth * 0.8)),c-extract/"
        
        self.dataSource = dataSource
        self.selectedFilter = filter
        self.filters = [
//            FilterItem(tag: .map, text: "Feed.FilterMap"),
//            FilterItem(tag: .nearBy, text: "Feed.FilterNearby"),
            FilterItem(tag: .global, text: "Feed.FilterGlobal"),
            FilterItem(tag: .friends, text: "Feed.FilterFriends"),
            FilterItem(tag: .own, text: "Feed.FilterOwnEvents"),
        ]
        self.filterTag = filterTag == nil ? [] : [filterTag!]
        self.filterUserId = userId ?? nil
        
        super.init(nibName: nil, bundle: nil)
        
        var actions = [(tag: Int, text: String, color: UIColor?)]()
        for i in 0..<FriendAction.count.rawValue {
            actions.append((i, FriendAction(rawValue: i)?.text ?? "", nil))
        }
        
        if let index = actions.index(where: { $0.tag == FriendAction.delete.rawValue }) {
            actions[index].color = Theme.destructiveTextColor
        }
        
        self.dropMenu = DropMenuView(target: self, actions: actions, selector: #selector(friendAction(_:)))
        
        if let index = index, index > 0 {
            self.tableView.isHidden = true
            self.indexToScroll = index
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(backAction))
        
        self.setupUI()
        
        self.selectPagerItem(at: self.selectedFilter.rawValue)
        if let tag = self.filterTag.first {
            self.showSearchBar(tag, force: true, isLoadDataRequired: false)
            self.navigationItem.titleView = searchBar
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.searchBar.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (self.currentActionEvent != nil) {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
        
        self.isCameraOn = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let index = self.indexToScroll {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: .top, animated: false)
            self.indexToScroll = nil
            self.tableView.isHidden = false
        } else if let index = self.indexToReload {
            self.tableView.reloadSection(index)
            self.indexToReload = nil
        }
    }
    
    // MARK:- Actions
    func friendAction(_ sender: UIButton) {
        self.dropMenu.hide()
        
        guard let action = FriendAction(rawValue: sender.tag) else { return }
        
        switch action {
        case .settings:
            self.showSettings()
        case .delete:
            self.removeConnection()
        case .tracking:
            self.showTracking()
        case .profile:
            self.showUserProfile()
        case .count: break;
        }
    }
    
    func showUserProfile(for user: UserExtended? = nil) {
        let profileVC = ProfileViewController()
        profileVC.user = user ?? self.currentActionUser
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func backAction() {
        guard (!self.filterTag.isEmpty) else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        self.filterTag.removeFirst()
        if let tag = self.filterTag.first {
            self.showSearchBar(tag, force: true)
        } else {
            self.hideSearchBar()
        }
    }
    
    func showSearchBar(_ tag: Tag, force: Bool = false, isLoadDataRequired: Bool = true) {
        self.searchBar.text = tag.name
        if !force {
            if let tagId = self.filterTag.first?.id, tag.id == tagId {
                return
            }
            self.filterTag.insert(tag, at: 0)
            self.searchBar.alpha = 0
            self.navigationItem.titleView = searchBar
        }

        if (isLoadDataRequired) {
            self.loadData(byResettingPagination: true)
        }

        UIView.animate(withDuration: force ? 0 : 0.4, animations: {
            self.searchBar.alpha = 1
        }, completion: { [weak self] _ in
            self?.addSearchBarToggleButton(tag.isFollowed)
        })
    }

    func hideSearchBar() {
        searchBar.resignFirstResponder()
        
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.searchBar.alpha = 0
        }) { [weak self] _ in
            self?.navigationItem.titleView = nil
            self?.searchBar.text = ""
        }
        
        self.loadData(byResettingPagination: true)
    }
    
    func showGallery(_ feed: Feed) {
        let gallery = GalleryViewController(dataSource: self, count: 1)
        gallery.backgroundColor = UIColor.black
        self.currentActionEvent = feed
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.present(gallery, animated: true, completion: nil)
    }
    
    func filterEvents(by tag: Tag) {
        self.showSearchBar(tag)
    }
    
    func filterAction(sender: UIButton) {
        self.selectPagerItem(at: sender.tag)
    }
    
    func friendMenu(at index: Int, sender: UIView) {
        guard let user = self.item(at: index)?.user, let point = sender.superview?.convert(sender.frame.origin, to: nil) else { return }
        
        self.searchBar.resignFirstResponder()

        let window = UIApplication.shared.keyWindow!
        self.dropMenu.show(in: window, buttonRect: CGRect(origin: point, size: sender.frame.size))
        self.currentActionUser = user
    }
    
    func toggleTagAction() {
        guard let tag = self.filterTag.first else { return }
        
        var indicator: UIActivityIndicatorView?
        if let textField = self.searchBar.value(forKey: "searchField") as? UITextField, let button = textField.rightView?.subviews.first {
            indicator = button.addProgress(.white)
            (button as? UIButton)?.setTitleColor(.clear, for: .normal)
        }

        let tagId = tag.id
        let newValue = !tag.isFollowed
        
        TagManager.toggle(follow: newValue, for: tagId) { [weak self] result in
            
            switch result {
            case .Success(_):
                guard let myself = self else { return }
                
                LoaderOverlay.shared.tick {
                    myself.onToggleTag(tagId, newValue: newValue)
                }
            case .Failure(let err):

                indicator?.removeFromSuperview()
                if let textField = self?.searchBar.value(forKey: "searchField") as? UITextField, let button = textField.rightView?.subviews.first as? UIButton {
                    button.setTitleColor(button.tintColor, for: .normal)
                }
                
                guard let error = err else { return }
                
                if (error.isNetworkError == true) {
                    UserMessage.shared.show(LocStr("Error.NoNetworkTip"))
                } else {
                    error.record()
                }
            }
        }
    }
    
    func toggleLike(for feedId: Int, newValue: Bool) {
        FeedManager.setLike(newValue, feedId: feedId) { [weak self] result in
            
            let items = self?.items ?? self?.dataSource?.nearByFeeds
            guard let index = items?.index(where: { $0.id == feedId }) else { return }
            
            switch result {
            case .Success(_):
                let likes: Int = (newValue ? 1 : -1)
                if (self!.items == nil) {
                    var feed = items![index]
                    feed.isLike = newValue
                    feed.likes += likes
                    self!.dataSource!.update(feed, at: index)
                } else {
                    self!.items![index].isLike = newValue
                    self!.items![index].likes += likes
                }
            case .Failure(let error):
                Helper.notifyApiError(error)
            }
            
            self!.tableView.reloadSection(index)
        }
    }
    
    func toggleReport(for feedId: Int, newValue: Bool) {
        LoaderOverlay.shared.show()
        
        FeedManager.setReport(newValue, feedId: feedId) { [weak self] result in
            
            let items = self?.items ?? self?.dataSource?.nearByFeeds
            guard let index = items?.index(where: { $0.id == feedId }) else {
                LoaderOverlay.shared.hide()
                return
            }
            
            switch result {
            case .Success(_):
                if (self!.items == nil) {
                    var feed = items![index]
                    feed.isReport = newValue
                    self!.dataSource!.update(feed, at: index)
                } else {
                    self!.items![index].isReport = newValue
                }
                LoaderOverlay.shared.tick(LocStr(newValue ? "Feed.Report" : "Feed.UnReport"))
            case .Failure(let error):
                LoaderOverlay.shared.hide()
                Helper.notifyApiError(error)
            }
            
            self!.tableView.reloadSection(index)
        }
    }
    
    func showComments(for feedId: Int) {
        let viewController = CommentsViewController(feedId, delegate: self)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    /* private func _follow(_ feedId: Int, userId: Int) {
        UserManager.addConnection(userId) { [weak self] result in
            
            let items = self?.items ?? self?.dataSource?.nearByFeeds
            guard let index = items?.index(where: { $0.id == feedId }) else { return }
            
            switch result {
            case .Success(_):
                self!.onToggleFollow(userId, newValue: true, index: index)
            case .Failure(let error):
                Helper.notifyApiError(error)
                self!.tableView.reloadSection(index)
            }
        }
    }
    
    fileprivate func onToggleFollow(_ userId: Int, newValue: Bool, index: Int) {
        if (self.items == nil) {
            self.dataSource?.onToggleFollow(userId: userId, newValue: newValue)
        } else {
            for (i,f) in self.items!.enumerated() {
                if (f.user.id == userId) {
                    self.items![i].isFriend = newValue
                }
            }
        }
        
        guard let visibleRows = tableView.indexPathsForVisibleRows else { return }
        
        var set = IndexSet()
        visibleRows.forEach {
            set.insert($0.section)
        }
        self.tableView.reloadSections(set, with: .none)
    } */
    
    func addAction() {
        let cameraVC = CameraViewController()
        cameraVC.transitioningDelegate = cameraVC
        self.present(cameraVC, animated: true) { [weak self] in
            self?.isCameraOn = true
        }
    }
    
    func friendsAction() {
        self.navigationController?.pushViewController(FriendsTableViewController(), animated: true)
    }
    
    // MARK: - Private
    fileprivate func item(at index: Int) -> Feed? {
        if (self.items != nil) {
            return self.items![index]
        } else if let feeds = self.dataSource?.nearByFeeds, index < feeds.count  {
            return feeds[index]
        }
        
        return nil
    }
    
    private func onToggleTag(_ tagId: Int, newValue: Bool) {
        self.items?.enumerated().forEach { (i, _) in
            self.items![i].tags?.enumerated().forEach { (ii, tag) in
                if (tag.id == tagId) {
                    self.items![i].tags![ii].isFollowed = newValue
                }
            }
        }
        
        for (i, tag) in self.filterTag.enumerated() {
            guard (tag.id == tagId) else { continue }
            
            self.filterTag[i].isFollowed = newValue
            if (i == 0) {
                self.addSearchBarToggleButton(newValue)
            }
        }
    }
    
    private func addSearchBarToggleButton(_ isFollowed: Bool) {
        guard let textField = self.searchBar.value(forKey: "searchField") as? UITextField else { return }
        
        let button = UIButton()
        button.addTarget(self, action: #selector(toggleTagAction), for: .touchUpInside)
        button.backgroundColor = Theme.destructiveBackgroundColor

        var vPadding: CGFloat?
        if #available(iOS 11.0, *) {
            vPadding = 9.0
        }
        button.contentEdgeInsets = UIEdgeInsets(top: vPadding ?? 6.0, left: 10, bottom: vPadding ?? 6.0, right: 10)
        button.setTitle(LocStr(isFollowed ? "Unfollow" : "Follow"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = Theme.Font.medium.withSize(12)
        button.sizeToFit()
        button.frame.size.height -= 3
        
        let rightView = UIView(frame: button.frame)
        button.frame.origin.x = 7
        rightView.addSubview(button)
        
        self.searchBar.subviews.first?.subviews.forEach { textField in
            if textField is UITextField {
                textField.layer.borderWidth = 0.5
                textField.layer.borderColor = Theme.Splash.lightColor.cgColor
                textField.layer.backgroundColor = UIColor(white: 1.0, alpha: 0.1).cgColor
            }
        }
        
        textField.clearButtonMode = .never
        textField.rightView = rightView
        textField.rightViewMode = .always
    }
    
    private func selectPagerItem(at itemTag: Int) {
        guard let filter = FeedFilterType(rawValue: itemTag) else { return }
        
        self.pagerView.subviews.forEach {
            let btn = $0 as! UIButton
            if (btn.isSelected) {
                btn.titleLabel?.font = Theme.Font.light.withSize(13)
                btn.isSelected = false
            }
            if (btn.tag == itemTag) {
                btn.isSelected = true
                btn.titleLabel?.font = Theme.Font.medium.withSize(13)
            }
        }
        
        self.selectedFilter = filter
    }
    
    private func showTracking() {
        let viewController = TrackingViewController(for: self.currentActionUser)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func showSettings() {
        let viewController = RadiusViewController(distance: self.currentActionUser.radius, for: self.currentActionUser.id)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func removeConnection() {
        let alert = String(format: LocStr("UnfollowAlert"), self.currentActionUser.name)
        let viewController = AlertViewController(alert, text: nil, actions: [
            AlertActionCase(actionCase: AlertAction.unfollow.rawValue, title: "OK"),
            AlertActionCase(actionCase: 0, title: LocStr("Cancel"))])
        
        viewController.delegate = self
        self.present(viewController, animated: true)
    }
    
    fileprivate func loadData(byResettingPagination reset: Bool = false) {
        if (reset) {
            self.newPage = 0
            self.total = nil
            self.items = []
            self.tableView.reloadData()
            self.tableView.showsInfiniteScrolling = true
            self.tableView.infiniteScrollingView.startAnimating()
        }
        
        let filter = self.selectedFilter
        
        var params: [String : Any] = ["page": self.newPage, "page_size": 20, "filter": filter.value ?? ""]
        if let tagId = self.filterTag.first?.id {
            params["tag_id"] = tagId
        }
        if let userId = self.filterUserId {
            params["user_id"] = userId
        }

        FeedManager.get(params: params) { [weak self] result in
            
            guard self != nil, self!.selectedFilter == filter else { return }

            self!.tableView.infiniteScrollingView.stopAnimating()
            
            switch (result) {
            case .Success(let data):
                if (data == nil) {
                    self!.total = 0
                } else if (self != nil) {
                    if (self!.items == nil) {
                        self!.items = data!.1
                    } else {
                        self!.items! += data!.1
                    }
                    self!.total = data!.0
                }
            case .Failure(let error):
                if (error?.isNetworkError == true) {
                    UserMessage.shared.show(LocStr("Error.NoNetworkTip"))
                }
            }
        }
    }

    private func setupUI() {
        self.view.backgroundColor = Theme.Light.background

        //
        pagerView.showsHorizontalScrollIndicator = false
        pagerView.showsVerticalScrollIndicator = false
        pagerView.scrollsToTop = false
        pagerView.backgroundColor = .white
        pagerView.translatesAutoresizingMaskIntoConstraints = false
        pagerView.layer.borderWidth = 0.5
        pagerView.layer.borderColor = Theme.Light.separator
        view.addSubview(pagerView)
        Helper.addConstraints(["H:|-0-[Pager]-0-|", "V:[TlG]-0-[Pager(60)]"], source: view, views: ["Pager": pagerView, "TlG": topLayoutGuide])
        
        var btnPrev: UIButton!
        let lastIndex = self.filters.count - 1
        let imgBtnBgHighlighted = UIColor(red: 0.929412, green: 0.929412, blue: 0.929412, alpha: 1.0).toImage // EDEDED
        
        for (i, item) in self.filters.enumerated() {
            let button = UIButton()
            button.addTarget(self, action: #selector(filterAction(sender:)), for: .touchUpInside)
            button.tag = item.tag.rawValue
            button.setTitle(LocStr(item.text), for: .normal)
            button.setTitleColor(UIColor(red: 0.552941, green: 0.552941, blue: 0.552941, alpha: 1.0), for: .normal) // 8D8D8D
            button.setBackgroundImage(imgBtnBgHighlighted, for: .selected)
            button.setTitleColor(Theme.Dark.textColor, for: .selected)
            button.titleLabel?.font = Theme.Font.light.withSize(13)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.layer.cornerRadius = 4
            button.layer.borderWidth = 0.5
            button.layer.borderColor = Theme.Light.separator
            
            pagerView.addSubview(button)
            
            if (i == 0) {
                Helper.addConstraints(["H:|-8-[Button]", "V:|-8-[Button(44)]-8-|"], source: pagerView, views: ["Button" : button])
            } else {
                var constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[Button(44)]", options: [], metrics: nil, views: ["Button" : button])
                constraints.append(NSLayoutConstraint(item: button, attribute: .leading, relatedBy: .equal, toItem: btnPrev, attribute: .trailing, multiplier: 1.0, constant: 8.0))
                if (i == lastIndex) {
                    constraints.append(NSLayoutConstraint(item: button, attribute: .trailing, relatedBy: .equal, toItem: pagerView, attribute: .trailing, multiplier: 1.0, constant: -8.0))
                }
                pagerView.addConstraints(constraints)
            }
            
            btnPrev = button
        }
   
        //
        self.tableView.allowsSelection = false
        self.tableView.backgroundColor = Theme.Light.background
        self.tableView.contentInset = UIEdgeInsetsMake(-35, 0, 0, 0);
        self.tableView.register(UINib(nibName: "FeedTableViewCell", bundle: nil), forCellReuseIdentifier: self.cellIdentifier)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.separatorStyle = .none
        self.tableView.tableFooterView = UIView()
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.addInfiniteScrolling(actionHandler: {
            self.loadData()
        })
        self.view.addSubview(tableView)
        Helper.addConstraints(["H:|-0-[TableView]-0-|", "V:[TableView]-0-|"], source: view, views: ["TableView" : tableView])
        self.view.addConstraint(NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: pagerView, attribute: .bottom, multiplier: 1.0, constant: 0))
        
        //
        let button = UIButton()
        button.addTarget(self, action: #selector(addAction), for: .touchUpInside)
        button.layer.cornerRadius = 30
        button.backgroundColor = Theme.Dark.badge
        button.tag = self.btnCreateFeedTag
        button.tintColor = Theme.Dark.tint
        button.setImage(UIImage(named: "Photos")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(button)
        Helper.addConstraints(["H:[Button]-16-|", "V:[Button(60)]-16-|", "[Button(60)]"], source: view, views: ["Button" : button])

        self.searchBar.showsCancelButton = false
        self.searchBar.searchBarStyle = .minimal
        if let textField = self.searchBar.value(forKey: "searchField") as? UITextField {
            textField.borderStyle = .none
            textField.leftView = UIView(frame: CGRect(origin: .zero, size: .zero))
            textField.textColor = .white
        }
    }
    
}

// MARK:- TableViewDataSource, TableViewDelegate
extension FeedsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var count: Int?
        if let iCount = self.items?.count {
            if (iCount > 0 || self.total == nil) {
                count = iCount
            }
        } else {
            count = self.dataSource?.nearByFeeds?.count
        }
        
        if (count == nil) {
            if (self.bgView == nil) {
                self.setupEmptyView()
            }
        } else if (self.bgView != nil) {
            self.bgView!.removeFromSuperview()
            self.bgView = nil
            self.tableView.isHidden = false
        }
        
        return count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0.01 : 32.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let feed = self.item(at: indexPath.section) else { return UITableViewCell() }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath) as! FeedTableViewCell
        
        let attribs: [String : Any] = [NSFontAttributeName: Theme.Font.light.withSize(13)]
        var attrStr: NSAttributedString?
        if feed.tags != nil {
            attrStr = self.tagsHelper.find(in: feed.tags!, toText: feed.text, attributes: attribs)
        }
        
        cell.setData(feed, text: attrStr ?? NSAttributedString(string: feed.text, attributes: attribs))
        cell.userView.tag = indexPath.section + 1

        return cell
    }

    private func loadPopularTags() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        TagManager.getPopularTags(withLimit: 8) { [weak self] result in
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            guard (self?.tableView.isHidden == true) else { return }
            
            var responseTags: [Tag]?
            
            switch result {
            case .Success(let tags):
                responseTags = tags
            case .Failure:
                responseTags = self?.popularTags ?? []
            }

            self!.popularTags = responseTags
            self!.setupEmptyView()
        }
    }
    
    private func setupEmptyView() {
        self.tableView.isHidden = true
        
        guard let tags = self.popularTags else {
            self.loadPopularTags()
            return
        }

        let messageText = LocStr("Feed.EmptyTip") + "\n"
        let textView = AutoHeightTextView()
        textView.backgroundColor = UIColor.clear
        textView.font = Theme.Font.medium.withSize(20)
        textView.heightConstraint = NSLayoutConstraint(item: textView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        textView.isEditable = false
        textView.textAlignment = .center
        textView.textColor = UIColor.darkGray
        textView.isScrollEnabled = false
        textView.bounces = false
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.addConstraint(textView.heightConstraint!)

        if (tags.isEmpty) {
            textView.text = messageText
        } else {
            var location = messageText.characters.count
            var names = [String]()
            var ranges: [(id: Int, start: Int, end: Int)] = []
            for tag in tags {
                names.append("#" + tag.name)
                let length = tag.name.characters.count + 1
                ranges.append((tag.id, location, length))
                location += length + 2
            }
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attrString = NSMutableAttributedString(string: messageText + names.joined(separator: ", "), attributes: [
                NSForegroundColorAttributeName: textView.textColor!,
                NSFontAttributeName: textView.font!,
                NSParagraphStyleAttributeName: paragraphStyle])
            ranges.forEach {
                attrString.addAttribute(NSLinkAttributeName, value: "\($0.id):", range: NSRange(location: $0.start, length: $0.end))
            }
            textView.attributedText = attrString
            textView.delegate = self
        }

        let button = UIButton()
        button.addTarget(self, action: #selector(friendsAction), for: .touchUpInside)
        button.setTitle(LocStr("Feed.EmptyButtonTitle"), for: .normal)
        self.bgView = self.view.addEmptyView(textView, button: button, image: UIImage(named: "no_results"))
        self.bgView!.alpha = 0
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.bgView?.alpha = 1
        }
    }
    
}

extension FeedsViewController: AlertViewControllerDelegate {
    
    func alertAction(_ actionCase: Int) {
        guard let m = AlertAction(rawValue: actionCase) else { return }
        
        switch m {
//        case .unfollow:
//            self._unfollow()
        case .loadData:
            self.loadData()
        case .unfollow:
            self._removeConnection()
        }
    }
    
    private func _removeConnection() {
        guard let id = self.currentActionUser.friendshipId else { return }
        
        LoaderOverlay.shared.show()
        
        self.view.endEditing(true)
        
        let userId = self.currentActionUser.id
        UserManager.removeFriendship(id) { [weak self] result in
            
            guard let _self = self else { return }
            
            switch result {
            case .Success(_):
                if let index = _self.items?.index(where: { $0.user.id == userId }) {
                    _self.items!.remove(at: index)
                }
                LoaderOverlay.shared.tick {
                    _self.tableView.reloadData()
                }
            case .Failure(let error):
                LoaderOverlay.shared.hide()
                // TODO: - Impl. some kind of BaseViewController to extend all vcs
                // to perform common functions, such as displaying common errors
            }
        }
    }
    
    /* func toggleUser(in item: Feed) {
        if (item.isFriend) {
            self.currentActionEvent = item
            let alertTitle = String(format: LocStr("UnfollowAlert"), item.user.displayName ?? item.user.username)
            let viewController = AlertViewController(alertTitle, text: nil, actions: [
                AlertActionCase(actionCase: AlertAction.unfollow.rawValue, title: "OK"),
                AlertActionCase(actionCase: 0, title: LocStr("Cancel"))
                ])
            viewController.delegate = self
            self.present(viewController, animated: true)
        } else {
            self._follow(item.id, userId: item.user.id)
        }
    }
    
    private func _unfollow() {
        LoaderOverlay.shared.show()
        
        let feedId = self.currentActionEvent.id
        let userId = self.currentActionEvent.user.id

        UserManager.removeConnection(userId) { [weak self] result in
            
            LoaderOverlay.shared.hide()
            
            let items = self?.items ?? self?.dataSource?.nearByFeeds
            guard let index = items?.index(where: { $0.id == feedId }) else { return }
            
            switch result {
            case .Success(_):
                self!.onToggleFollow(userId, newValue: false, index: index)
            case .Failure(let error):
                Helper.notifyApiError(error)
                self!.tableView.reloadSection(index)
            }

        }
    } */
    
}

// MARK: - SearchBar delegate
extension FeedsViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.hideSearchBar()
    }
    
}

// MARK: - TextView delegate
extension FeedsViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if URL.scheme != nil, let tagId = Int(URL.scheme!), let tag = self.popularTags?.filter( { $0.id == tagId } ).first {
            self.filterEvents(by: tag)
        }
        return false
    }
    
}

// MARK: Gallery DataSource
extension FeedsViewController: GalleryDataSource {

    func imageInGallery(at: Int) -> String {
        return self.currentActionEvent.pictureUrl
    }
    
}

extension FeedsViewController: CommentsDelegateController {
    
    func commentsDidChange(for id: Int, with count: Int) {
        guard let items = self.items ?? self.dataSource?.nearByFeeds, let index = items.index(where: { $0.id == id }) else { return }
        
        if (self.items == nil) {
            var feed = items[index]
            feed.comments = count
            self.dataSource!.update(feed, at: index)
        } else {
            self.items![index].comments = count
        }
        
        self.indexToReload = index
    }
    
}
