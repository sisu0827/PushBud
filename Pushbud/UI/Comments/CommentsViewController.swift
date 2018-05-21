//
//  CommentsViewController.swift
//  PushBud
//
//  Created by Daria.R on 25/04/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

protocol CommentsDelegateController {
    func commentsDidChange(for id: Int, with count: Int)
}

class CommentsViewController: UIViewController {
    
    fileprivate enum AlertAction: Int {
        case retryLoadData
    }
    
    private let feedId: Int
    fileprivate var isLoading = true
    fileprivate var items: [FeedComment]? {
        didSet {
            self.tableView.reloadData()
        }
    }

    fileprivate let cellIdentifier = "FeedCommentCell"
    private let tableView = UITableView()
    private var bottomInset: NSLayoutConstraint!
    private let btnSend = UIButton()
    private let txtComment = UITextField()

    private let delegate: CommentsDelegateController
    
    // MARK: - LifeStyle
    init(_ feedId: Int, delegate: CommentsDelegateController) {
        self.feedId = feedId
        self.delegate = delegate
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsSelection = false
        self.tableView.tableFooterView = UIView()
        self.tableView.register(UINib(nibName: "CommentsTableViewCell", bundle: nil), forCellReuseIdentifier: self.cellIdentifier)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)
        Helper.addConstraints(["H:|-0-[Table]-0-|", "V:[TlG]-0-[Table]"], source: view, views: ["Table": tableView, "TlG": topLayoutGuide])
        
        let bottomView = UIView()
        let bottomViewSeparator = CALayer()
        bottomViewSeparator.frame = CGRect(x: 0, y: 0, width: 999, height: 0.5)
        bottomViewSeparator.backgroundColor = Theme.Light.separator
        bottomView.layer.addSublayer(bottomViewSeparator)
        bottomView.backgroundColor = .white
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(bottomView)
        Helper.addConstraints(["H:|-0-[BottomView]-0-|", "V:[BottomView(42)]"], source: view, views: ["BottomView" : bottomView])
        self.bottomInset = NSLayoutConstraint(item: bottomView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0)
        self.view.addConstraints([bottomInset, NSLayoutConstraint(item: bottomView, attribute: .top, relatedBy: .equal, toItem: tableView, attribute: .bottom, multiplier: 1.0, constant: 0)])
        
        self.btnSend.addTarget(self, action: #selector(postAction), for: .touchUpInside)
        self.btnSend.setTitle(LocStr("Post"), for: .normal)
        self.btnSend.setTitleColor(Theme.Light.textButton, for: UIControlState())
        self.btnSend.titleLabel?.font = Theme.Font.medium.withSize(15)
        self.btnSend.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(btnSend)
        
        //let txtComment = UITextField()
        self.txtComment.borderStyle = .none
        self.txtComment.backgroundColor = .clear
        self.txtComment.font = Theme.Font.medium.withSize(15)
        self.txtComment.placeholder = LocStr("Comments.Placeholder")
        self.txtComment.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(self.txtComment)
        bottomView.addConstraints([
            NSLayoutConstraint(item: self.txtComment, attribute: .top, relatedBy: .equal, toItem: bottomView, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.txtComment, attribute: .bottom, relatedBy: .equal, toItem: bottomView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.txtComment, attribute: .leading, relatedBy: .equal, toItem: bottomView, attribute: .leading, multiplier: 1.0, constant: 8.0),
            NSLayoutConstraint(item: self.txtComment, attribute: .trailing, relatedBy: .equal, toItem: btnSend, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnSend, attribute: .centerY, relatedBy: .equal, toItem: self.txtComment, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnSend, attribute: .trailing, relatedBy: .equal, toItem: bottomView, attribute: .trailing, multiplier: 1.0, constant: -8.0)
            ])

        self.loadData(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK:- Actions
    func keyboardWillShow(_ notification: Notification) {
        if let value = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            self.bottomInset.constant = -value.cgRectValue.size.height
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func keyboardWillHide() {
        self.bottomInset.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func postAction() {
        guard let text = self.txtComment.text?.trim() else {
            self.txtComment.becomeFirstResponder()
            self.txtComment.errorShake()
            return
        }
        
        let values: [String : Any] = [
            "event_id" : feedId,
            "text" : text
        ]

        LoaderOverlay.shared.show()
        
        HTTP.New(APIClient.baseURL + "comments", type: .POST, params: values, headers: APIClient.JsonHeaders).start { [weak self] response in
            
            LoaderOverlay.shared.hide()
            
            let statusCode = response.statusCode ?? 0
            
            if (Config.IsDevelopmentMode) {
                print("CreateComment-HTTP\(statusCode)\n\(String(data: response.data, encoding: .utf8) ?? "")")
            }

            if statusCode == 200, let dict = response.data.jsonObject() as? [String: Any], let commentId: Int = dict["id"] as? Int {
                self?.appendRow(id: commentId, text: dict["text"] as? String)
            } else if let apiError = response.data.apiError {
                UserMessage.shared.show(LocStr("Failure"), body: LocStr(apiError))
            } else if (response.error?.isNetworkError == true) {
                UserMessage.shared.show(LocStr("Error.NoNetworkTitle"), body: LocStr("Error.NoNetworkTip"))
            } else {
                UserMessage.shared.show(LocStr("Failure"), body: LocStr("Error.Unexpected"))
            }
        }
    } // End Post Action
    
    private func appendRow(id: Int, text: String?) {
        let comment = FeedComment(id: id, text: text ?? "", date: Date(), user: Config.userProfile!)
        if let count = self.items?.count {
            self.items!.append(comment)
            self.delegate.commentsDidChange(for: self.feedId, with: count + 1)
        } else {
            self.items = [comment]
            self.delegate.commentsDidChange(for: self.feedId, with: 1)
        }
        self.txtComment.text = ""
        self.view.endEditing(true)
    }
    
    /* func likeAction(_ sender: UIButton) {
        if let comment = self.items?[sender.tag] {
            sender.addPulseAnimation()
            self.toggleLike(for: comment.id, newValue: comment.isLike)
        }
    }
    
    // MARK:- Private
    private func toggleLike(for commentId: Int, newValue: Bool) {
        FeedManager.setCommentLike(commentId, value: newValue) { [weak self] result in
            
            guard let index = self?.items?.index(where: { $0.id == commentId }) else { return }
            
            switch result {
            case .Success(_):
                self!.items![index].isLike = newValue
                self!.items![index].likes = (newValue ? 1 : -1)
                self!.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            case .Failure(let error):
                Helper.notifyApiError(error)
            }
        }
    } */
    
    fileprivate func loadData(_ force: Bool = false) {
        LoaderOverlay.shared.show()
        self.isLoading = true
        
        CommentManager.fetch(by: self.feedId) { [weak self] result in
            
            LoaderOverlay.shared.hide()
            
            guard let sself = self else { return }
            
            sself.isLoading = false
            
            switch result {
            case .Success(let items):
                sself.items = items
            case .Failure(let error):
                if error?.isNetworkError == true {
                    Helper.alertNoNetRetry(sself, retryCase: AlertAction.retryLoadData.rawValue)
                } else {
                    UserMessage.shared.show(LocStr("Failure"), body: LocStr("Error.Unexpected"))
                }
            }
        }
    }
}

// MARK: - Table view data source
extension CommentsViewController: UITableViewDataSource, UITableViewDelegate {
        
    func numberOfSections(in tableView: UITableView) -> Int {
        guard (self.items == nil) else {
            tableView.backgroundView = nil
            return 1
        }
            
        if (!self.isLoading && tableView.backgroundView == nil) {
            let label = UILabel()
            label.textAlignment = .center
            label.font = Theme.Font.medium.withSize(16)
            label.textColor = UIColor.lightGray
            label.text = LocStr("Comments.EmptyTip")
            tableView.backgroundView = label
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let comment = self.items?[indexPath.row], let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CommentsTableViewCell else { return UITableViewCell() }

        cell.lblText.attributedText = comment.attributedText
        cell.lblDate.text = comment.date.toReadable
        cell.imgUser.setupAvatar(comment.user.picture, text: comment.user.username, textColor: Theme.Splash.lighterColor)
        
        /* if comment.likes > 0 {
            cell.lblLikes.text = String(format: FeedTerm.numberOfLikes, comment.likes)
        } else {
            cell.lblLikes.text = ""
        }
        
        cell.btnLike.isSelected = comment.isLike
        cell.btnLike.tag = indexPath.row
        cell.btnLike.removeTarget(nil, action: nil, for: .allEvents)
        cell.btnLike.addTarget(self, action: #selector(likeAction(_:)), for: .touchUpInside) */

        return cell
    }
    
}

extension CommentsViewController: AlertViewControllerDelegate {
    
    func alertAction(_ actionCase: Int) {
        if (AlertAction(rawValue: actionCase) == AlertAction.retryLoadData) {
            self.loadData()
        }
    }
    
}
