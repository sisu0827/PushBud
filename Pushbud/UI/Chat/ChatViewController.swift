//
//  ChatViewController.swift
//  PushBud
//
//  Created by Daria.R on 13/06/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
    
    fileprivate var conversation: EMConversation?
    var conversationId: String? {
        didSet {
            self.conversation = EMClient.shared().chatManager.getConversation(conversationId, type: EMConversationTypeChat, createIfNotExist: true)
        }
    }

    private var messages = [JSQMessage]()

    private let bubbleIn = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: .white)
    private let avatarIn: JSQMessagesAvatarImage

    private let bubbleOut: JSQMessagesBubbleImage
    private let avatarOut: JSQMessagesAvatarImage
    
    init(toUser: User) {
        let bubbleOutColor = UIColor(red: 0.682353, green: 0.878431, blue: 0.952941, alpha: 1.0) //AEE0F3
        self.bubbleOut = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: bubbleOutColor)
        
        var avatarImage: UIImage?
        if let url = toUser.pictureUrl {
            avatarImage = ImageClient.shared.getCached(url)
        }
        self.avatarIn = JSQMessagesAvatarImage(avatarImage: avatarImage, highlightedImage: nil, placeholderImage: UIImage(named: "ChatPlaceholderAvatar"))
        
        let user = Config.userProfile!
        if let url = user.pictureUrl {
            avatarImage = ImageClient.shared.getCached(url)
        } else if (avatarImage != nil) {
            avatarImage = nil
        }
        self.avatarOut = JSQMessagesAvatarImage(avatarImage: avatarImage, highlightedImage: nil, placeholderImage: UIImage(named: "ChatPlaceholderAvatar"))

        super.init(nibName: nil, bundle: nil)
        
        self.senderId = "\(user.id)"
        self.senderDisplayName = user.displayName ?? user.username
        EMClient.shared().chatManager.add(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private
    fileprivate func processEmMessage(_ message: EMMessage) {
        switch message.body {
        case is EMTextMessageBody:
            let text = (message.body as! EMTextMessageBody).text
            let date = Date(timeIntervalSince1970: TimeInterval(message.timestamp/1000))
            if let msg = JSQMessage(senderId: message.from, senderDisplayName: message.from, date: date, text: text) {
                self.messages.append(msg)
            }
        default:
            // TODO: - Impl. location and photo messages
            break
        }
    }
    
    // MARK: - JSQCollectionView Layout, Datasource, Delegate
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if (indexPath.row % 3 == 0) {
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: self.messages[indexPath.row].date)
        }
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return self.messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        // TODO: - Impl. Photo or Location message tap delegate
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        if (self.senderId == self.messages[indexPath.row].senderId) {
            return self.bubbleOut
        }
        
        return self.bubbleIn
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        if (self.senderId == self.messages[indexPath.row].senderId) {
            return self.avatarOut
        }
        
        return self.avatarIn
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        
        if (indexPath.row % 3 == 0) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0
    }
    
}

extension ChatViewController: EMChatManagerDelegate {
    
    func messagesDidReceive(_ aMessages: [Any]!) {
        for a in (aMessages ?? []) {
            if let message = a as? EMMessage {
                self.processEmMessage(message)
            }
        }

    }
}
