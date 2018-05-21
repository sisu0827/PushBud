//
//  LoginViewController.swift
//  PushBud
//
//  Created by Daria.R on 08/04/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    fileprivate var activeFieldTag: Int?

    @IBOutlet var scrollWidth: [NSLayoutConstraint]!
    @IBOutlet var scrollView: [UIScrollView]!

    @IBOutlet weak var txtLoginUsername : UITextField!
    @IBOutlet weak var txtLoginPassword : UITextField!
    
    @IBOutlet weak var txtSignupUsername : UITextField!
    @IBOutlet weak var txtSignupPassword : UITextField!
    @IBOutlet weak var txtSignupRepeatPassword : UITextField!
    
    @IBOutlet var btnFb: UIButton!
    @IBOutlet var btnGo: UIButton!
    
    @IBOutlet var lblSocialSeparator: LabelInset!
    
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var btnRegister: UIButton!
    
    @IBOutlet weak var lblLogin : UILabel!
    @IBOutlet weak var lblSignup : UILabel!
    
    @IBOutlet var pagerView: UIView!

    fileprivate var pagerBorder = CALayer()
    fileprivate var pagerIndicator: UIView!
    fileprivate var tabIndex: Int! {
        didSet {
            self.lblSocialSeparator.text = LocStr(self.tabIndex == 0 ? "Authentication.LoginSeparatorTip" : "Authentication.SignupSeparatorTip")
        }
    }

    // MARK: - Life Style
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

       /* if (Config.IsDevelopmentMode) {
            self.txtLoginUsername.text = "daria"
            self.txtLoginPassword.text = "daria"
        }*/
        
        let bgView = UIImageView(image: UIImage(named: "BlurBackground"))
        bgView.frame = CGRect(origin: .zero, size: Constants.screenSize)
        bgView.contentMode = .scaleToFill
        self.view.insertSubview(bgView, at: 0)
        
        [btnFb, btnGo, btnLogin, btnRegister].forEach {
            $0!.layer.cornerRadius = 3
        }
        
//        let socialView = self.lblSocialSeparator.superview!,
//            socialSeparator = CALayer()
//        socialSeparator.frame = CGRect(x: 0, y: self.lblSocialSeparator.frame.origin.y + 8, width: socialView.frame.width, height: 1.0)
//        socialSeparator.backgroundColor = Theme.Light.separator
//        socialView.layer.addSublayer(socialSeparator)

        self.setupTextFields(fields: [txtLoginUsername, txtLoginPassword, txtSignupUsername, txtSignupPassword, txtSignupRepeatPassword])

        if let img = UIImage(named: "user") {
            txtLoginUsername.leftView = self.inputImageView(img)
            txtSignupUsername.leftView = self.inputImageView(img)
        }
        if let img = UIImage(named: "lock") {
            txtLoginPassword.leftView = self.inputImageView(img)
            txtSignupPassword.leftView = self.inputImageView(img)
            txtSignupRepeatPassword.leftView = self.inputImageView(img)
        }

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.KeyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.KeyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        for lbl in self.pagerView.subviews {
            lbl.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.pagerTabSelect(_:))))
        }
        
        self.pagerBorder.backgroundColor = Theme.Splash.lightColor.cgColor
        self.pagerView.layer.addSublayer(pagerBorder)
        self.pagerView.backgroundColor = Theme.Splash.darkColor
        
        let _colorOverlay = UIView()
        _colorOverlay.alpha = 0.85
        _colorOverlay.backgroundColor = self.pagerView.backgroundColor
        _colorOverlay.isOpaque = false
        _colorOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.pagerView.insertSubview(_colorOverlay, at: 0)
        Helper.addConstraints(["H:|-0-[v]-0-|", "V:|-0-[v]-0-|"], source: pagerView, views: ["v":_colorOverlay])
        
        let _whiteOverlay = UIView()
        _whiteOverlay.backgroundColor = UIColor(white: 0.97, alpha: 0.5)
        _whiteOverlay.isOpaque = false
        _whiteOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.pagerView.insertSubview(_whiteOverlay, at: 0)
        Helper.addConstraints(["H:|-0-[v]-0-|", "V:|-0-[v]-0-|"], source: pagerView, views: ["v":_whiteOverlay])
        
        let tabFrame = self.lblLogin.frame,
            separator = CALayer()
        separator.frame = CGRect(x: UIScreen.main.bounds.width / 2, y: tabFrame.origin.y + 12, width: 1.0, height: tabFrame.height - 24)
        separator.backgroundColor = Theme.Splash.lightColor.cgColor
        self.pagerView.layer.addSublayer(separator)
        
        self.pagerIndicator = UIView()
        self.pagerIndicator.backgroundColor = Theme.Splash.lightColor
        self.pagerView.addSubview(self.pagerIndicator)
        
        self.scrollWidth[1].constant = 0
        self.tabIndex = 0
        
        // Localization
        self.updateLocalizedText()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        self.updateLayout()
    }
    
    // MARK:- Private
    private func setupTextFields(fields: [UITextField]) {
        let bgColor = Theme.Splash.lighterColor.withAlphaComponent(0.5)
        let borderColor = Theme.Splash.darkColor.cgColor
        fields.forEach { field in
            field.delegate = self
            field.backgroundColor = bgColor
            field.leftViewMode = .always
            field.layer.borderWidth = 1
            field.layer.cornerRadius = 3
            field.layer.borderColor = borderColor
        }
    }
    
    private func updateLocalizedText() {
        self.tabIndex = self.tabIndex == nil ? 0 : self.tabIndex

        lblLogin.text = LocStr("Authentication.LoginTitle")
        lblSignup.text = LocStr("Authentication.SignupTitle")
        
        btnLogin.setTitle(LocStr("Authentication.LoginButton"), for: .normal)
        btnRegister.setTitle(LocStr("Authentication.SignupButton"), for: .normal)
        
        let attr = [NSForegroundColorAttributeName: UIColor.white.withAlphaComponent(0.4)]
        txtLoginUsername.attributedPlaceholder = NSAttributedString(string: LocStr("Authentication.Username"), attributes: attr)
        txtLoginPassword.attributedPlaceholder = NSAttributedString(string: LocStr("Authentication.Password"), attributes: attr)
        txtSignupUsername.attributedPlaceholder = NSAttributedString(string: LocStr("Authentication.Username"), attributes: attr)
        txtSignupPassword.attributedPlaceholder = NSAttributedString(string: LocStr("Authentication.Password"), attributes: attr)
        txtSignupRepeatPassword.attributedPlaceholder = NSAttributedString(string: LocStr("Authentication.RepeatPassword"), attributes: attr)
    }

    fileprivate func inputImageView(_ image: UIImage)->UIImageView {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 28, height: 30))
        imageView.image = image
        imageView.contentMode = .right

        return imageView
    }
    
    fileprivate func dismissKeyboard() {
        if self.txtLoginUsername.isFirstResponder {
            self.txtLoginUsername.resignFirstResponder()
        } else if self.txtLoginPassword.isFirstResponder {
            self.txtLoginPassword.resignFirstResponder()
        } else if self.txtSignupUsername.isFirstResponder {
            self.txtSignupUsername.resignFirstResponder()
        } else if self.txtSignupPassword.isFirstResponder {
            self.txtSignupPassword.resignFirstResponder()
        } else if self.txtSignupRepeatPassword.isFirstResponder {
            self.txtSignupRepeatPassword.resignFirstResponder()
        }
    }
    
    fileprivate func updateLayout() {
        let pagerHeight = self.pagerView.frame.size.height
        
        let w = self.view.frame.size.width / 2
        self.pagerIndicator.frame = CGRect(x: self.tabIndex > 0 ? w : 0, y: pagerHeight - 4, width: w, height: 4)
        self.pagerBorder.frame = CGRect(x: 0, y: pagerHeight - 1, width: self.view.bounds.width, height: 1)
    }

    fileprivate func validateUsername(_ username: String?) -> String? {
        guard let trimmed = username?.trim() else {
            UserMessage.shared.show(LocStr("Error.UsernameEmpty"))
            return nil
        }

        if (trimmed.characters.count < 4) {
            UserMessage.shared.show(LocStr("Error.UsernameInvalid"), body: LocStr("Error.UsernameTooShort"))
            return nil
        }

        if (!NSPredicate(format:"SELF MATCHES %@", "[a-z0-9._-]*").evaluate(with: trimmed.lowercased())) {
            UserMessage.shared.show(LocStr("Error.UsernameInvalid"), body: LocStr("Error.UsernameInvalidCharacter"))
            return nil
        }

        return trimmed
    }

    fileprivate func validatePassword(_ password: String?) -> String? {
        guard let trimmed = password?.trim() else {
            UserMessage.shared.show(LocStr("Error.PasswordEmpty"))
            return nil
        }
        
        if (trimmed.characters.count < 4) {
            UserMessage.shared.show(LocStr("Error.PasswordTooShort"))
            return nil
        }

        if (txtSignupRepeatPassword.text ?? "" != trimmed) {
            UserMessage.shared.show(LocStr("Error.PasswordMismatch"))
            return nil
        }

        return trimmed
    }
    
    // MARK:- Public
    @IBAction func loginAction() {
        guard let username = txtLoginUsername.text?.trim() else {
            UserMessage.shared.show(LocStr("Error.UsernameEmpty"))
            return
        }
        
        guard let password = txtLoginPassword.text?.trim() else {
            UserMessage.shared.show(LocStr("Error.PasswordEmpty"))
            return
        }

        self.dismissKeyboard()
        
        LoaderOverlay.shared.show()
        
        UserManager.authenticate(action: "login", username: username, password: password) { [weak self] result in
            switch (result) {
            case .Success(_):
                self?.onAuthReady()
            case .Failure(_):
                LoaderOverlay.shared.hide()
                UserMessage.shared.show(LocStr("Error.LoginFailedTitle"), body: LocStr("Error.LoginFailedTip"))
            }
        }
        
    }
    
    @IBAction func registerAction() {

        guard let username = self.validateUsername(txtSignupUsername.text) else {
            self.txtSignupUsername.becomeFirstResponder()
            return
        }

        guard let password = self.validatePassword(txtSignupPassword.text) else {
            self.txtSignupPassword.becomeFirstResponder()
            return
        }

        self.dismissKeyboard()

        LoaderOverlay.shared.show()

        UserManager.authenticate(action: "register", username: username, password: password) { [weak self] result in
            switch (result) {
            case .Success(_):
                self?.onAuthReady()
            case .Failure(let error):
                LoaderOverlay.shared.hide()
                UserMessage.shared.show(LocStr("Error.SignupFailedTitle"), body: error ?? LocStr("Error.SignupFailedTip"))
            }
        }
    }

    private func onAuthReady() {
        let navVC = self.navigationController!
        LoaderOverlay.shared.tick() { [unowned navVC] in
            navVC.setNavigationBarHidden(false, animated: false)
            navVC.pushViewController(MapViewController(), animated: true)
        }
    }
    
    func pagerTabSelect(_ tap: UITapGestureRecognizer) {
        guard let lbl = tap.view as? UILabel, lbl.tag != self.tabIndex else { return }
        
        if self.activeFieldTag != nil {
            self.view.endEditing(true)
            self.activeFieldTag = nil
        }

        let pagerHeight = self.pagerView.frame.size.height - 4, frame = lbl.frame

        self.scrollWidth[tabIndex].constant = 0
        self.scrollWidth[lbl.tag].constant = 300
        self.scrollView[lbl.tag].setNeedsUpdateConstraints()
        self.tabIndex = lbl.tag

        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let sself = self else { return }
            
            lbl.alpha = 1
            (lbl.tag == 0 ? sself.lblSignup : sself.lblLogin).alpha = 0.3
            
            sself.scrollView[sself.tabIndex].layoutIfNeeded()
            sself.pagerIndicator.frame = CGRect (
                x: frame.origin.x,
                y: pagerHeight,
                width: frame.size.width,
                height: 4)
            })
    }
    
    func KeyboardDidShow(_ notification: Notification) {
        guard let tag = self.activeFieldTag, let height = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height else { return }
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: height, right: 0)
        let scrollView = self.scrollView[self.tabIndex]
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        var aRect = self.view.frame
        aRect.size.height -= height
        
        var field: UIView
        switch (tag) {
        case 1:
            field = self.txtLoginPassword
            break
        case 2:
            field = self.txtSignupUsername
            break
        case 3:
            field = self.txtSignupPassword
            break
        case 4:
            field = self.txtSignupRepeatPassword
            break
        default:
            field = self.txtLoginUsername
        }
        
        if (!aRect.contains(field.frame.origin)) {
            scrollView.scrollRectToVisible(field.frame, animated: true)
        }
    }
    
    func KeyboardWillHide(_ notification: Notification) {
        let contentInsets = UIEdgeInsets.zero
        self.scrollView[tabIndex].contentInset = contentInsets
        self.scrollView[tabIndex].scrollIndicatorInsets = contentInsets
    }
    
}

extension LoginViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch (textField.tag) {
        case 0:
            (self.txtLoginPassword as UIResponder).becomeFirstResponder()
            return false
        case 1:
            self.loginAction()
            textField.resignFirstResponder()
            return true
        case 2:
            (self.txtSignupPassword as UIResponder).becomeFirstResponder()
            return false
        case 3:
            (self.txtSignupRepeatPassword as UIResponder).becomeFirstResponder()
            return false
        case 4:
            self.registerAction()
        default: break
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeFieldTag = nil
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeFieldTag = textField.tag
    }
    
}
