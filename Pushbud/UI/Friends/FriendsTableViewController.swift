//
//  FriendsTableViewController.swift
//  PushBud
//
//  Created by Daria.R on 25/04/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit
import ObjectMapper

enum FriendAction: Int {
    case profile, settings, tracking, delete, count
    
    var text: String {
        switch (self) {
        case .profile:
            return LocStr("Friendship.Profile")
        case .settings:
            return LocStr("Friendship.Settings")
        case .delete:
            return LocStr("Friendship.Delete")
        case .tracking:
            return LocStr("Friendship.Tracking")
        case .count:
            return ""
        }
    }
}

class FriendsTableViewController: UITableViewController {
    
    fileprivate enum AlertAction: Int {
        case unfollow = 1, retryLoadData
    }
    
    private let searchBar = UISearchBar()
    fileprivate var searchTimer: Timer?
    fileprivate var lastSearch = ""
    fileprivate var results: [UserExtended]? {
        didSet {
            self.tableView.reloadData()
        }
    }

    fileprivate var items: [UserExtended]? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    fileprivate var editIndex: Int!
    fileprivate let cellIdentifier = "FriendCell"
    fileprivate var isSearching = false

    private var dropMenu: DropMenuView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(closeAction))
        
        self.tableView.allowsSelection = false
        self.tableView.rowHeight = 56
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.tableFooterView = UIView()
        self.tableView.register(UINib(nibName: "FriendTableViewCell", bundle: nil), forCellReuseIdentifier: self.cellIdentifier)
        
        var actions = [(tag: Int, text: String, color: UIColor?)]()
        for i in 0..<FriendAction.count.rawValue {
            actions.append((i, FriendAction(rawValue: i)?.text ?? "", nil))
        }
        
        if let index = actions.index(where: { $0.tag == FriendAction.delete.rawValue }) {
            actions[index].color = Theme.destructiveTextColor
        }

        self.dropMenu = DropMenuView(target: self, actions: actions, selector: #selector(friendAction(_:)))

        if #available(iOS 11.0, *) {
            searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        
        searchBar.delegate = self
        searchBar.barTintColor = UIColor.white
        searchBar.sizeToFit()
        self.navigationItem.titleView = searchBar
        
        if let txtSearch = searchBar.value(forKey: "_searchField") as? UITextField {
            txtSearch.placeholder = LocStr("Friends.SearchPlaceholder")
            txtSearch.font = Theme.Font.medium.withSize(14)
            txtSearch.textColor = UIColor(red: 0.486275, green: 0.486275, blue: 0.486275, alpha: 1.0) // 7C7C7C
            txtSearch.layer.backgroundColor = UIColor.white.cgColor
            txtSearch.layer.borderColor = UIColor(red: 0.784314, green: 0.784314, blue: 0.784314, alpha: 1.0).cgColor
            txtSearch.layer.borderWidth = 1.0
            txtSearch.layer.cornerRadius = 2.5
        }

        self.loadData()
    }
    
    // MARK:- Actions
    func closeAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func friendAction(_ sender: UIButton) {
        self.dropMenu.hide()
        
        let index = self.dropMenu.contentView.tag - 1
        guard let action = FriendAction(rawValue: sender.tag), let user = self.results?[index] ?? self.items?[index] else { return }
        
        switch action {
        case .settings:
            self.showSettings(for: user)
        case .delete:
            self.removeConnection(on: user, at: index)
        case .tracking:
            let trackingVC = TrackingViewController(for: user)
            self.navigationController?.pushViewController(trackingVC, animated: true)
        case .profile:
            self.showUserProfile(user)
        case .count: break;
        }
    }
    
    func showProfile(_ tap: UITapGestureRecognizer) {
        guard let idx = tap.view?.subviews.index(where: { $0 is AvatarImageView }) else { return }

        let index = tap.view!.subviews[idx].tag - 1
        if let user = self.results?[index] ?? self.items?[index] {
            self.showUserProfile(user)
        }
    }
    
    func acceptInvitationAction(_ sender: UIButton) {
        guard sender.tag > 0, let user = self.results?[sender.tag - 1] ?? self.items?[sender.tag - 1], let id = user.friendshipId else { return }
        
        let userId = user.id
        LoaderOverlay.shared.show()
        
        UserManager.toggleInvitation(id, value: true) { [weak self] result in
            
            LoaderOverlay.shared.hide()
            
            guard let _self = self else { return }
            
            switch result {
            case .Success(_):
                if let index = _self.items?.index(where: { $0.id == userId }) {
                    var item = _self.items![index]
                    item.isFriend = true
                    _self.items![index] = item
                }
                if let index = _self.results?.index(where: { $0.id == userId }) {
                    var item = _self.results![index]
                    item.isFriend = true
                    _self.results![index] = item
                }
                _self.tableView.reloadData()
            case .Failure(let error):
                self?.onLoadDataError(true, error: error)
            }
        }
    }
    
    func declineInvitationAction(_ sender: UIButton) {
        guard sender.tag > 0, let user = self.results?[sender.tag - 1] ?? self.items?[sender.tag - 1], let id = user.friendshipId else { return }
        
        let userId = user.id
        LoaderOverlay.shared.show()
        
        UserManager.toggleInvitation(id, value: false) { [weak self] result in
            
            LoaderOverlay.shared.hide()
            
            guard let _self = self else { return }
            
            switch result {
            case .Success(_):
                if let index = _self.items?.index(where: { $0.id == userId }) {
                    _self.items!.remove(at: index)
                }
                if let index = _self.results?.index(where: { $0.id == userId }) {
                    _self.results!.remove(at: index)
                }
                _self.tableView.reloadData()
            case .Failure(let error):
                self?.onLoadDataError(true, error: error)
            }
        }
    }
    
    func friendMenu(_ sender: UIButton) {
        guard let point = sender.superview?.convert(sender.frame.origin, to: nil), let window = UIApplication.shared.keyWindow else { return }
        
        self.searchBar.resignFirstResponder()

        self.dropMenu.show(in: window, buttonRect: CGRect(origin: point, size: sender.frame.size))
        self.dropMenu.contentView.tag = sender.tag
    }
    
    func addConnection(_ sender: UIButton) {
        guard sender.tag > 0, let friend = self.results?[sender.tag - 1] ?? self.items?[sender.tag - 1] else { return }
        
        let userId = friend.id
        LoaderOverlay.shared.show()
        
        UserManager.addConnection(userId) { [weak self] result in
            
            guard let _self = self else { return }
            
            switch result {
            case .Success(_):
                if let index = _self.items?.index(where: { $0.id == userId }) {
                    var item = _self.items![index]
                    item.isInvitor = true
                    item.isInvitation = true
                    _self.items![index] = item
                }
                if let index = _self.results?.index(where: { $0.id == userId }) {
                    var item = _self.results![index]
                    item.isInvitor = true
                    item.isInvitation = true
                    _self.results![index] = item
                }
                _self.tableView.reloadData()
                LoaderOverlay.shared.tick()
            case .Failure(let error):
                LoaderOverlay.shared.hide()
                self?.onLoadDataError(true, error: error)
            }
        }
    }
    
    func loadData() {
        var uri: String!
        let isSearch = self.isSearching
        if (isSearch) {
            let term = self.lastSearch
            guard let q = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
            uri = "search/friend?q=" + q
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        } else {
            uri = "friends"
            LoaderOverlay.shared.show()
        }
        
        HTTP.New(APIClient.baseURL + uri, type: .GET, headers: APIClient.Headers).start { [weak self] response in
            
            LoaderOverlay.shared.hide()
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("UserExtended:HTTP\(statusCode)::\(uri): \(String(data: response.data, encoding: .utf8) ?? "")")
            }
            
            guard self?.isSearching == isSearch else { return }

            switch (statusCode) {
            case 204:
                if (isSearch) {
                    self?.results = []
                } else {
                    self?.items = nil
                }
            case 200:
                let array = response.data.jsonObject() as! [[String : Any]]
                
                if (isSearch) {
                    self?.results = try? Mapper<UserExtended>().mapArray(JSONObject: array)
                } else {
                    self?.items = try? Mapper<UserExtended>().mapArray(JSONObject: array)
                }
            default:
                self?.onLoadDataError(isSearch, error: response.error)
            }
        }
        
    }
    
    // MARK:- Private
    private func showUserProfile(_ user: UserExtended) {
        let profileVC = ProfileViewController()
        profileVC.user = user
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    private func showSettings(for user: UserExtended) {
        let viewController = RadiusViewController(distance: user.radius, for: user.id)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func removeConnection(on user: UserExtended, at index: Int) {
        let alert = String(format: LocStr("UnfollowAlert"), user.name)
        let viewController = AlertViewController(alert, text: nil, actions: [
            AlertActionCase(actionCase: AlertAction.unfollow.rawValue, title: "OK"),
            AlertActionCase(actionCase: 0, title: LocStr("Cancel"))])
            
        viewController.delegate = self
        self.present(viewController, animated: true)
        self.editIndex = index
    }
    
    fileprivate func onLoadDataError(_ isSearch: Bool, error: NSError?) {
        guard (error?.isNetworkError == true) else {
            UserMessage.shared.show(LocStr("Failure"), body: LocStr("Error.Unexpected"))
            return
        }

        if (isSearch) {
            UserMessage.shared.show(LocStr("Error.NoNetworkTitle"), body: LocStr("Error.NoNetworkTip"))
        } else {
            Helper.alertNoNetRetry(self, retryCase: AlertAction.retryLoadData.rawValue)
        }
    }
    
    // MARK: - TableView dataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return (self.results == nil && self.items == nil ? 0 : 1)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = self.results?.count {
            return count
        }
        
        return self.items?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let user = self.results?[indexPath.row] ?? self.items?[indexPath.row], let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FriendTableViewCell else {
            return UITableViewCell()
        }

//        let radius = user.radius == nil ? 0 : Int(user.radius! / 1000)
//        cell.btnRadius.setTitle(String(format: LocStr("Friends.Radius"), radius), for: .normal)
//        cell.btnRadius.removeTarget(nil, action: nil, for: .allEvents)
//        cell.btnRadius.addTarget(self, action: #selector(self.radiusAction(_:)), for: .touchUpInside)

        cell.imgUser.tag = indexPath.row + 1
        cell.btnUser.tag = indexPath.row + 1
        cell.btnUser.removeTarget(nil, action: nil, for: .allEvents)
        
        if (user.isFriend) {
            cell.btnUser.setImage(UIImage(named: "dropdown")?.withRenderingMode(.alwaysOriginal), for: .normal)
            cell.btnUser.setTitle(nil, for: .normal)
            cell.btnUser.contentEdgeInsets.right = 0
            cell.btnUser.addTarget(self, action: #selector(friendMenu(_:)) , for: .touchUpInside)
        } else if (user.isInvitation) {
            if (user.isInvitor) {
                cell.btnUser.updateToggleFriend(true)
                cell.btnUser.setTitle(LocStr("User.Invited"), for: .normal)
            } else {
                cell.btnUser.isHidden = true
                cell.setupUiForInvitaion(target: self, index: cell.btnUser.tag)
            }
        } else {
            cell.btnUser.updateToggleFriend(false)
            cell.btnUser.addTarget(self, action: #selector(addConnection(_:)) , for: .touchUpInside)
        }
        
        cell.lblUser.text = user.name
        cell.lblUser.superview?.addTarget(target: self, action: #selector(showProfile(_:)))
        cell.imgUser.setupAvatar(user.picture, text: cell.lblUser.text, textColor: Theme.Splash.lighterColor)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let user = self.results?[indexPath.row] ?? self.items?[indexPath.row]
        return user?.isFriend ?? false
    }
    
//    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        guard let user = self.results?[indexPath.row] ?? self.items?[indexPath.row] , user.isFriend
//            else { return nil }
//
//        let height = tableView.rectForRow(at: indexPath).height
//        let font = Theme.Font.medium.withSize(13)
//        let placeholder: String = "\t \t \t"
//
//        let muteImage = UIImage(named: user.isMuted ? "notifs_on" : "notifs_off")!
//        let muteLabel = LocStr(user.isMuted ? "Friends.Unmute" : "Friends.Mute")
//        let trackAction = UITableViewRowAction(style: .destructive, title: placeholder, handler: { [weak self] (editAction, indexPath) in
//            self?.toggleTracking(at: indexPath.row)
//        })
//        trackAction.draw(Theme.destructiveBackgroundColor, image: muteImage, text: muteLabel, font: font, cellHeight: height)
//
//        let radius = user.radius == nil ? 0 : Int(user.radius! / 1000)
//        let radiusAction = UITableViewRowAction(style: .normal, title: placeholder, handler: { [weak self] (editAction, indexPath) in
//            self?.radiusAction(at: indexPath.row)
//        })
//        let radiusLabel = String(format: LocStr("Friends.Radius"), radius)
//        let radiusBgColor = UIColor(red: 1.0, green: 0.32549, blue: 0.0, alpha: 1.0) // FF5300
//        radiusAction.draw(radiusBgColor, image: UIImage(named: "radius")!, text: radiusLabel, font: font, cellHeight: height)
//
//        return [trackAction, radiusAction]
//    }
    
}

extension FriendsTableViewController: AlertViewControllerDelegate {
    
    func alertAction(_ actionCase: Int) {
        guard let m = AlertAction(rawValue: actionCase) else { return }
        
        switch m {
        case .unfollow:
            self._removeConnection()
        case .retryLoadData:
            self.loadData()
        }
    }
    
    private func _removeConnection() {
        guard let user = self.results?[self.editIndex] ?? self.items?[self.editIndex], let id = user.friendshipId else { return }
        
        LoaderOverlay.shared.show()

        self.view.endEditing(true)

        let userId = user.id
        UserManager.removeFriendship(id) { [weak self] result in
            
            guard let _self = self else { return }
            
            switch result {
            case .Success(_):
                if let index = _self.items?.index(where: { $0.id == userId }) {
                    _self.items!.remove(at: index)
                }
                if let index = _self.results?.index(where: { $0.id == userId }) {
                    _self.results![index].isFriend = false
                }
                LoaderOverlay.shared.tick()
            case .Failure(let error):
                LoaderOverlay.shared.hide()
                self?.onLoadDataError(true, error: error)
            }
        }
    }

}

// MARK: - UISearchBar Delegate
extension FriendsTableViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        searchBar.text = ""
        self.isSearching = false
        self.lastSearch = ""
        self.results = nil
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        self.isSearching = true
        
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let text = searchText.trim(false)!
        
        if (text.caseInsensitiveCompare(self.lastSearch) == .orderedSame) {
            return
        }
        
        self.lastSearch = text
        self.searchTimer?.invalidate()
        
        if (text.isEmpty) {
            self.results = []
            return
        }
        
        if (text.count < 2) {
            return
        }
        
        self.searchTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(loadData), userInfo: nil, repeats: false)
    }
    
}
