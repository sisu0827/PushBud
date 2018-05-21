//
//  TagsTableViewController.swift
//  PushBud
//
//  Created by Daria.R on 25/04/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit
import ObjectMapper

class TagsTableViewController: UITableViewController {
    
    fileprivate enum AlertAction: Int {
        case retryLoadData = 1
    }

    private let tagNameAttribs: [String: Any] = [
        NSFontAttributeName: Theme.Font.light.withSize(15),
        NSForegroundColorAttributeName: Theme.Dark.textColor
    ]
    private let localizableTagFollowerCount = LocStr("Tags.NumberOfFollowers")

    private let searchBar = UISearchBar()
    fileprivate var searchTimer: Timer?
    fileprivate var lastSearch = ""
    fileprivate var isSearching = false
    fileprivate var results: [Tag]? {
        didSet {
            self.tableView.reloadData()
        }
    }

    fileprivate let imgFollow = UIImage(named: "ic_plus")
    fileprivate let imgFollowed = UIImage(named: "ic_minus")

    fileprivate var items: [Tag]? {
        didSet {
            if (!self.isSearching) {
                self.tableView.reloadData()
            }
        }
    }
    
    fileprivate var toggleFollowTagId: Int!
    fileprivate let cellIdentifier = "TagCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(closeAction))
        
        self.tableView.allowsSelection = false
        self.tableView.rowHeight = 56
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.tableFooterView = UIView()
        self.tableView.register(TagTableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        
        if #available(iOS 11.0, *) {
            searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        
        searchBar.delegate = self
        searchBar.barTintColor = UIColor.white
        searchBar.sizeToFit()
        self.navigationItem.titleView = searchBar
        
        if let txtSearch = searchBar.value(forKey: "_searchField") as? UITextField {
            txtSearch.placeholder = LocStr("Tags.SearchPlaceholder")
            txtSearch.font = Theme.Font.medium.withSize(14)
            txtSearch.textColor = UIColor(red: 0.486275, green: 0.486275, blue: 0.486275, alpha: 1.0) //7C7C7C
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
    
    func toggleTag(_ sender: UIButton) {
        let tagId = sender.tag
        var tag: Tag
        if let index = self.results?.index(where: { $0.id == tagId }) {
            tag = self.results![index]
        } else if let index = self.items?.index(where: { $0.id == tagId }) {
            tag = self.items![index]
        } else {
            return
        }

        let newValue = !tag.isFollowed
        
        LoaderOverlay.shared.show()

        TagManager.toggle(follow: newValue, for: tagId) { [weak self] result in
            switch result {
            case .Success(_):
                tag.isFollowed = newValue
                tag.count += (newValue ? 1 : -1)
                self?.onToggle(tag: tag)
                LoaderOverlay.shared.tick()
            case .Failure(let error):
                LoaderOverlay.shared.hide()
                self?.onLoadDataError(true, error: error)
            }
        }
    }
    
    private func onToggle(tag: Tag) {
        let index = self.items?.index(where: { $0.id == tag.id })
        if (index != nil) {
            self.items![index!] = tag
        }

        guard let resultIndex = self.results?.index(where: { $0.id == tag.id }) else { return }
        
        self.results![resultIndex] = tag
        
        guard (index == nil) else { return }
        
        if (self.items == nil) {
            self.items = [tag]
        } else {
            self.items!.insert(tag, at: 0)
        }
    }
    
    func loadData() {
        var uri: String!
        let isSearch = self.isSearching
        if (isSearch) {
            let term = self.lastSearch
            guard let q = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
            uri = "search/tag?q=" + q
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        } else {
            uri = "follow"
            LoaderOverlay.shared.show()
        }
        
        HTTP.New(APIClient.baseURL + uri, type: .GET, headers: APIClient.Headers).start { [weak self] response in
            
            LoaderOverlay.shared.hide()
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("Tags:HTTP\(statusCode)::\(uri): \(String(data: response.data, encoding: .utf8) ?? "")")
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
                
                guard let json = response.data.jsonObject(), let tags = try? Mapper<Tag>().mapArray(JSONObject: json) else { return }

                if (isSearch) {
                    self?.results = tags
                } else {
                    self?.items = tags
                }

            default:
                self?.onLoadDataError(isSearch, error: response.error)
            }
        }
        
    }
    
    // MARK:- Private
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
        guard
            let tag = self.results?[indexPath.row] ?? self.items?[indexPath.row],
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TagTableViewCell
        else {
            return UITableViewCell()
        }
        
        let strAttr = NSMutableAttributedString(string: tag.name + "\n" + String(format: self.localizableTagFollowerCount, tag.count))
        strAttr.addAttributes(self.tagNameAttribs, range: NSRange(location: 0, length: tag.name.count))
        cell.lblTag.attributedText = strAttr
        
        cell.btnAction.removeTarget(nil, action: nil, for: .allEvents)
        cell.btnAction.setImage(tag.isFollowed ? imgFollowed : imgFollow, for: .normal)
        cell.btnAction.tag = tag.id
        cell.btnAction.addTarget(self, action: #selector(toggleTag(_:)), for: .touchUpInside)
        
        return cell
    }

}

extension TagsTableViewController: AlertViewControllerDelegate {
    
    func alertAction(_ actionCase: Int) {
        if AlertAction(rawValue: actionCase) == .retryLoadData {
            self.loadData()
        }
    }
    
}

// MARK: - UISearchBar Delegate
extension TagsTableViewController: UISearchBarDelegate {
    
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
        
        self.searchTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(loadData), userInfo: nil, repeats: false)
    }
    
}
