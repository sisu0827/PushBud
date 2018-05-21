//
//  SideBar.swift
//  PushBud
//
//  Created by Daria.R on 24/04/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

protocol SidebarDelegate {
    func didTapSidebar(item: SidebarAction)
}

enum SidebarAction: Int {
    case friends, tags, feeds, settings, logout, count
    case changePassword = -1
    case account = -2
}

class SidebarView: UIView {

    var delegate: SidebarDelegate?
    
    fileprivate let cellIdentifier = "SidebarCell"
    private let barWidth: CGFloat = 265

    @IBOutlet var headerView: UIView!
    @IBOutlet var imgUser: AvatarImageView!
    @IBOutlet var btnChangePassword: UIButton!
    @IBOutlet var btnProfile: UIButton!

    private let tableViewTag = 2
    private let _colorOverlay = UIView()
    private let _whiteOverlay = UIView()

    fileprivate var defaultCell: UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: self.cellIdentifier)
        if let label = cell.textLabel {
            label.font = Theme.Font.light.withSize(16)
            label.textColor = Theme.Dark.textColor
        }
        return cell
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let _colorOverlay = UIView()
        _colorOverlay.alpha = 0.85
        _colorOverlay.backgroundColor = self.headerView.backgroundColor
        _colorOverlay.isOpaque = false
        _colorOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.headerView.insertSubview(_colorOverlay, at: 0)
        Helper.addConstraints(["H:|-0-[v]-0-|", "V:|-0-[v]-0-|"], source: headerView, views: ["v":_colorOverlay])
        
        let _whiteOverlay = UIView()
        _whiteOverlay.backgroundColor = UIColor(white: 0.97, alpha: 0.5)
        _whiteOverlay.isOpaque = false
        _whiteOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.headerView.insertSubview(_whiteOverlay, at: 0)
        Helper.addConstraints(["H:|-0-[v]-0-|", "V:|-0-[v]-0-|"], source: headerView, views: ["v":_whiteOverlay])

        let tableView = UITableView()
        tableView.tag = self.tableViewTag
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        tableView.rowHeight = 48
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let footerSize = Constants.screenSize.height - self.headerView.frame.height - (tableView.rowHeight * CGFloat(SidebarAction.count.rawValue))
        tableView.contentInset = UIEdgeInsetsMake(footerSize / 2, 0, 0, 0)
        
        self.addSubview(tableView)
        Helper.addConstraints(["H:|-0-[tv]-0-|", "V:[tv]-0-|"], source: self, views: ["tv":tableView])
        self.addConstraint(NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: self.headerView, attribute: .bottom, multiplier: 1, constant: 0))
        
        // Localization
        self.btnChangePassword.setTitle(LocStr("ChangePassword.Title"), for: UIControlState())
        self.btnProfile.setTitle(LocStr("Sidebar.EditProfile"), for: UIControlState())
    }
    
    func reloadProfile() {
        guard let user = Config.userProfile else {
            self.imgUser.setupAvatar(nil, text: nil, animated: true)
            return
        }
        
        let pictureUrl = user.picture
        if (pictureUrl == nil) {
            self.imgUser.image = nil
        }
        self.imgUser.setupAvatar(pictureUrl, text: user.name ?? user.username, textColor: Theme.Splash.lightColor, animated: true)
    }
    
    @IBAction func profileAction() {
        self.delegate?.didTapSidebar(item: .account)
    }
    
    @IBAction func changePasswordAction() {
        self.delegate?.didTapSidebar(item: .changePassword)
    }

}

//MARK:- TableView dataSource delegate
extension SidebarView: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SidebarAction.count.rawValue
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier) ?? self.defaultCell
        
        switch (SidebarAction(rawValue: indexPath.row)!) {
        case .friends:
            cell.textLabel?.text = LocStr("Sidebar.Friends")
            cell.imageView?.image = UIImage(named: "menu_friends")
        case .tags:
            cell.textLabel?.text = LocStr("Sidebar.Tags")
            cell.imageView?.image = UIImage(named: "menu_hashtag")
        case .feeds:
            cell.textLabel?.text = LocStr("Sidebar.Events")
            cell.imageView?.image = UIImage(named: "menu_pin")
        case .settings:
            cell.textLabel?.text = LocStr("Sidebar.Settings")
            cell.imageView?.image = UIImage(named: "menu_settings")
        case .logout:
            cell.textLabel?.text = LocStr("Logout")
            cell.imageView?.image = UIImage(named: "logout")
        case .count, .changePassword, .account: break
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if let item = SidebarAction(rawValue: indexPath.row) {
            self.delegate?.didTapSidebar(item: item)
        }
    }
}
