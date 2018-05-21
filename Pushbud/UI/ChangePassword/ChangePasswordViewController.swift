//
//  ChangePasswordViewController.swift
//  PushBud
//
//  Created by Daria.R on 03/05/17.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

class ChangePasswordViewController: UIViewController {

    @IBOutlet var btnTogglePassword: UIButton!
    
    @IBOutlet var lblCurrentPassword: UILabel!
    @IBOutlet var txtCurrentPassword: UITextField!
    
    @IBOutlet var lblNewPassword: UILabel!
    @IBOutlet var txtNewPassword: UITextField!
    
    @IBOutlet var lblRepeatPassword: UILabel!
    @IBOutlet var txtRepeatPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: LocStr("Save"), style: .plain, target: self, action: #selector(saveAction))

        [txtCurrentPassword, txtNewPassword, txtRepeatPassword].forEach {
            if let textField = $0 {
                textField.layer.backgroundColor = UIColor.white.cgColor
                textField.layer.masksToBounds = false
                textField.layer.shadowColor = UIColor.lightGray.cgColor
                textField.layer.shadowOffset = CGSize(width: 0.0, height: 1)
                textField.layer.shadowOpacity = 1.0
                textField.layer.shadowRadius = 0.0
            }
        }

        // Localization
        self.title = LocStr("ChangePassword.Title")
        self.btnTogglePassword.setTitle(LocStr("ChangePassword.ShowPassword"), for: UIControlState())
        self.lblCurrentPassword.text = LocStr("ChangePassword.CurrentPasswordTitle")
        self.lblNewPassword.text = LocStr("ChangePassword.NewPasswordTitle")
        self.lblRepeatPassword.text = LocStr("ChangePassword.RepeatPasswordTitle")
    }
    
    @IBAction func togglePasswords(_ sender: UIButton) {
        let newValue = !self.txtCurrentPassword.isSecureTextEntry

        for txtField in [txtCurrentPassword, txtNewPassword, txtRepeatPassword] {
            txtField!.isSecureTextEntry = newValue
        }
        
        sender.setTitle(LocStr(newValue ? "ChangePassword.ShowPassword" : "ChangePassword.HidePassword"), for: UIControlState())
    }
    
    
    func saveAction() {
        guard let password = self.txtCurrentPassword.text?.trim() else {
            self.txtCurrentPassword.becomeFirstResponder()
            self.txtCurrentPassword.errorShake()
            return
        }
        
        guard let newPassword = self.txtNewPassword.text?.trim() else {
            self.txtNewPassword.becomeFirstResponder()
            self.txtNewPassword.errorShake()
            return
        }
        
        guard (newPassword.characters.count > 3) else {
            self.txtNewPassword.becomeFirstResponder()
            UserMessage.shared.show(LocStr("Error.PasswordTooShort"))
            return
        }
        
        guard self.txtRepeatPassword.text == newPassword else {
            self.txtRepeatPassword.becomeFirstResponder()
            UserMessage.shared.show(LocStr("Error.PasswordMismatch"))
            return
        }
        
        LoaderOverlay.shared.show()
        self.view.isUserInteractionEnabled = false

        UserManager.savePassword(password: password, newPassword: newPassword) { [weak self] result in
            self?.view.isUserInteractionEnabled = true
            switch result {
            case .Success(_):
                if (self != nil) {
                    LoaderOverlay.shared.tick() {
                        self?.navigationController?.popViewController(animated: true)
                    }
                } else {
                    LoaderOverlay.shared.hide()
                }
                break
            case .Failure(let error):
                LoaderOverlay.shared.hide()
                UserMessage.shared.show(LocStr("Failure"), body: error)
            }
        }
    }
    
}
