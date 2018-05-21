//
//  TrackingTableViewController.swift
//  PushBud
//
//  Created by Daria.R on 12/9/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit
import ObjectMapper

enum TrackingAction: Int {
    case view, delete, count
    
    var text: String {
        switch (self) {
        case .delete:
            return LocStr("Tracking.Delete")
        case .view:
            return LocStr("Tracking.View")
        case .count:
            return ""
        }
    }
}

class TrackingTableViewController: UITableViewController {
    
    fileprivate enum AlertAction: Int {
        case retryLoadData = 1, delete
    }
    fileprivate var items: [Tracking]? {
        didSet {
            self.tableView.reloadData()
        }
    }
    fileprivate let cellIdentifier = "TrackingCell"
    fileprivate var editIndex: Int!
    
    private var dropMenu: DropMenuView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(closeAction))
        
        self.tableView.allowsSelection = false
        self.tableView.rowHeight = 56
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.tableFooterView = UIView()
        self.tableView.register(UINib(nibName: "TrackingTableViewCell", bundle: nil), forCellReuseIdentifier: self.cellIdentifier)
        
        var actions = [(tag: Int, text: String, color: UIColor?)]()
        for i in 0..<TrackingAction.count.rawValue {
            actions.append((i, TrackingAction(rawValue: i)?.text ?? "", nil))
        }
        
        if let index = actions.index(where: { $0.tag == TrackingAction.delete.rawValue }) {
            actions[index].color = Theme.destructiveTextColor
        }

        self.dropMenu = DropMenuView(target: self, actions: actions, selector: #selector(subMenuAction(_:)))

        self.loadData()
    }
    
    // MARK:- Actions
    func closeAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func menuAction(_ sender: UIButton) {
        guard let point = sender.superview?.convert(sender.frame.origin, to: nil), let window = UIApplication.shared.keyWindow else { return }
        
        self.dropMenu.show(in: window, buttonRect: CGRect(origin: point, size: sender.frame.size))
        self.dropMenu.contentView.tag = sender.tag
    }

    func subMenuAction(_ sender: UIButton) {
        self.dropMenu.hide()
        
        let index = self.dropMenu.contentView.tag - 1
        guard let action = TrackingAction(rawValue: sender.tag), let item = self.items?[index] else { return }
        
        switch action {
        case .delete:
            self.editIndex = index
            var message: String?
            if (item.isRequest || item.isAccepted) {
                message = LocStr("Tracking.Remove")
            }
            let viewController = AlertViewController(LocStr(message ?? "Tracking.Decline"), text: nil, actions: [
                AlertActionCase(actionCase: AlertAction.delete.rawValue, title: "OK"),
                AlertActionCase(actionCase: 0, title: LocStr("Cancel"))])
            viewController.delegate = self
            self.present(viewController, animated: true)
            self.editIndex = index
        case .view:
            break;
//            let trackingVC = TrackingViewController(for: item.user)
//            self.navigationController?.pushViewController(trackingVC, animated: true)
        case .count: break;
        }
    }
    
    func acceptAction(_ sender: UIView) {
        guard sender.tag > 0, let item = self.items?[sender.tag - 1], !item.isAccepted else { return }
        
        LoaderOverlay.shared.show()
        
        let trackingId = item.id
        TrackingManager.toggleInvitation(trackingId, value: true) { [weak self] result in
            
            LoaderOverlay.shared.hide()
            
            switch result {
            case .Success(_):
                if let index = self?.items?.index(where: { $0.id == trackingId }) {
                    self!.items![index].isAccepted = true
                }
            case .Failure(let error):
                self?.onRequestError(error)
            }
        }
    }
    
    func declineAction(_ sender: UIView) {
        guard sender.tag > 0, let item = self.items?[sender.tag - 1] else { return }

        let trackingId = item.id
        LoaderOverlay.shared.show()
        
        TrackingManager.toggleInvitation(trackingId, value: false) { [weak self] result in

            LoaderOverlay.shared.hide()
            
            switch result {
            case .Success(_):
                if let index = self?.items?.index(where: { $0.id == trackingId }) {
                    self!.items!.remove(at: index)
                }
            case .Failure(let error):
                self?.onRequestError(error)
            }
        }
    }
    
    func loadData() {
        LoaderOverlay.shared.show()
        
        TrackingManager.getList { [weak self] result in
            
            LoaderOverlay.shared.hide()
            
            switch result {
            case .Success(let items):
                self?.items = items
            case .Failure(let error):
                self?.onRequestError(error)
            }
        }
        
    }
    
//    func showProfile(_ tap: UITapGestureRecognizer) {
//        guard let idx = tap.view?.subviews.index(where: { $0 is AvatarImageView }) else { return }
//
//        let index = tap.view!.subviews[idx].tag - 1
//        if let user = self.items?[index].user {
//            self.showUserProfile(user)
//        }
//    }
    
    // MARK:- Private
    private func showUserProfile(_ user: UserExtended) {
        let profileVC = ProfileViewController()
        profileVC.user = user
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    private func onRequestError(_ error: NSError?) {
        if (error?.isNetworkError == true) {
            Helper.alertNoNetRetry(self, retryCase: AlertAction.retryLoadData.rawValue)
        } else {
            UserMessage.shared.show(LocStr("Failure"), body: LocStr("Error.Unexpected"))
        }
    }
    
    // MARK: - TableView dataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.items == nil ? 0 : 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = self.items?[indexPath.row] else { return UITableViewCell() }

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! TrackingTableViewCell

        cell.btnMenu.tag = indexPath.row + 1
        cell.btnMenu.removeTarget(nil, action: nil, for: .allEvents)
        
        let isInvitation = !item.isAccepted
        cell.btnMenu.isHidden = isInvitation
        
        if (isInvitation) {
            cell.setupUiForInvitaion(target: self, index: cell.btnMenu.tag)
        } else {
            cell.btnMenu.addTarget(self, action: #selector(menuAction(_:)) , for: .touchUpInside)
        }
        
//        cell.userTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(showProfile(_:)))
//        cell.lblUser.superview?.addGestureRecognizer(cell.userTapRecognizer!)
        cell.lblUser.text = item.user.name ?? item.user.username
        
        if (item.isAccepted) {
            cell.lblStatus.tag = 1
            cell.lblStatus.text = LocStr("TrackingStatus.Active")
            cell.lblStatus.textColor = .white
            cell.lblStatus.layer.backgroundColor = Theme.Splash.lightColor.cgColor
        } else {
            cell.lblStatus.text = LocStr(item.isRequest ? "TrackingStatus.Awaiting" : "TrackingStatus.Invitation")
        }

        cell.imgUser.setupAvatar(item.user.picture, text: cell.lblUser.text, textColor: Theme.Splash.lighterColor)
        return cell
    }

}

extension TrackingTableViewController: AlertViewControllerDelegate {
    
    func alertAction(_ actionCase: Int) {
        guard let m = AlertAction(rawValue: actionCase) else { return }
        
        switch m {
        case .retryLoadData:
            self.loadData()
        case .delete:
            let view = UIView()
            view.tag = self.editIndex + 1
            self.declineAction(view)
        }
    }

}

