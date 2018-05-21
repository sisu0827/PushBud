//
//  NotifyViewController.swift
//  Pushbud
//
//  Created by Daria.R on 18/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit

class NotifyViewController: UIViewController {

    fileprivate enum AlertAction: Int {
        case retryLoadData
    }
    
    fileprivate let tableView = UITableView()

    private let deviceId = UIDevice.current.identifierForVendor!.uuidString
    private let refreshControl = UIRefreshControl()

    fileprivate let cellIdentifier = "NotifyCell"
    fileprivate var isLoading = true {
        didSet {
            self.tableView.reloadData()
        }
    }
    fileprivate var items: [Notify]?
    fileprivate let unreadBackgroundColor = UIColor(red: 0.976471, green: 0.866667, blue: 0.862745, alpha: 1.0) //f9dddc
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.allowsSelection = false
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(UINib(nibName: "NotifyTableViewCell", bundle: nil), forCellReuseIdentifier: self.cellIdentifier)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.tableFooterView = UIView()
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)
        Helper.addConstraints(["H:|-0-[Table]-0-|", "V:|-0-[Table]-0-|"], source: view, views: ["Table": tableView])
        
        self.refreshControl.backgroundColor = Theme.Splash.darkColor
        self.refreshControl.tintColor = UIColor.white
        self.refreshControl.addTarget(self, action: #selector(reloadAction), for: .valueChanged)
        self.tableView.addSubview(refreshControl)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(exitAction))
        self.loadData(true)
    }

    // MARK: - Actions
    func exitAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func reloadAction() {
        self.loadData()
    }
    
    // MARK: - Private
    private func loadData(_ force: Bool = false) {
        guard force || !self.isLoading else { return }
        
        LoaderOverlay.shared.show()
        self.items = nil
        self.isLoading = true
        
        NotifyManager.fetchAll(params: ["device": self.deviceId]) { [weak self] result in
            
            LoaderOverlay.shared.hide()
            
            guard let myself = self else { return }

            myself.refreshControl.endRefreshing()
            
            switch result {
            case .Success(let items):
                myself.items = items
            case .Failure(let error):
                if error?.isNetworkError == true {
                    Helper.alertNoNetRetry(myself, retryCase: AlertAction.retryLoadData.rawValue)
                } else {
                    UserMessage.shared.show(LocStr("Failure"), body: LocStr("Error.Unexpected"))
                }
            }

            myself.isLoading = false
        }
    }
    
}

// MARK: - TableView dataSource Delegate
extension NotifyViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 92
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteItem(at: indexPath)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard (self.items == nil) else {
            tableView.separatorStyle = .singleLine
            tableView.backgroundView = nil
            return 1
        }
        
        if (!self.isLoading) {
            if (tableView.separatorStyle != .none) {
                tableView.separatorStyle = .none
                tableView.setEmptyView(nibName: "EmptyMessageView", messageText: "Nofity.EmptyTip", image: UIImage(named: "tick"))
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath) as! NotifyTableViewCell

        guard let item = self.items?[indexPath.row] else { return cell }
        
        cell.lblText.text = item.text
        cell.lblDate.text = item.date.toReadable
//        cell.backgroundColor = item.isNew ? self.unreadBackgroundColor : .white
        
        return cell
    }
    
    // MARK: - Private
    private func deleteItem(at indexPath: IndexPath) {
//        guard let json = data.jsonDict(), let i = json["count"] as? Int else { return }
        
        let i = Int(arc4random_uniform(2))
        
        self.updateCount(i > 0 ? i : nil, rowMarkRead: nil, rowDelete: indexPath)
    }
    
    private func updateCount(_ count: Int?, rowMarkRead: IndexPath?, rowDelete: IndexPath?) {
        UIApplication.shared.applicationIconBadgeNumber = count ?? 0

        if let button = self.navigationItem.rightBarButtonItems?.filter({ $0 is BadgeBarButtonItem }).first as? BadgeBarButtonItem {
            button.badgeValue = count
        }
        
        guard (self.items != nil) else { return }
        
        if let indexPath = rowMarkRead {
            if let cell = self.tableView.cellForRow(at: indexPath) {
                cell.backgroundColor = UIColor.white
            }
        } else if let indexPath = rowDelete {
            self.items!.remove(at: indexPath.row)
            if (self.items!.isEmpty) {
                self.items = nil
                self.tableView.reloadData()
            } else {
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
}

extension NotifyViewController: AlertViewControllerDelegate {
    
    func alertAction(_ actionCase: Int) {
        if (AlertAction(rawValue: actionCase) == AlertAction.retryLoadData) {
            self.reloadAction()
        }
    }
    
}
