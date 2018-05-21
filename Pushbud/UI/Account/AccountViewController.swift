//
//  AccountViewController.swift
//  PushBud
//
//  Created by Daria.R on 18/08/16.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {

    fileprivate enum AlertAction: Int {
        case cancelSignin = 1, retrySignin, retryUpload
    }
    
    fileprivate enum ProfileInput: Int {
        case name = 18
        case email = 19
    }
    
    @IBOutlet var profileView: UIView!
    @IBOutlet var imgUser: AvatarImageView!
    @IBOutlet var imgUserWidth: NSLayoutConstraint!
    @IBOutlet var txtName: UITextField!

    private var isUploading = false
    fileprivate var imageData: Data?
    fileprivate var imageUrl: URL?
    private var imageKey: String!
    
    private var newName: String?
    private var newEmail: String?
    private var newPassword: String?

    private var isSavingProfile = false {
        didSet {
            self.view.isUserInteractionEnabled = !isSavingProfile
        }
    }
    
    fileprivate var displayName: String {
        return self.profile.name ?? self.profile.username
    }
    
    var profile: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // MARK:- Actions
    func closeAction() {
        if (!self.isSavingProfile) {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func photoAction() {
        self.txtName.resignFirstResponder()

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        alert.view.tintColor = Theme.Dark.textColor

        alert.addAction(UIAlertAction(title: LocStr("Profile.CameraPhoto"), style: .default, handler: {finished in
            self.importImage(.camera)
        }))
        alert.addAction(UIAlertAction(title: LocStr("Profile.LibraryPhoto"), style: .default, handler: {finished in
            self.importImage(.savedPhotosAlbum)
        }))

        if (self.profile.picture != nil) {
            alert.addAction(UIAlertAction(title: LocStr("Profile.RemovePhoto"), style: .destructive, handler: {finished in
                self.deletePhoto()
            }))
        }

        alert.addAction(UIAlertAction(title: LocStr("Cancel"), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func dismissAction(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func passwordAction(_ sender: AnyObject) {
        let viewController = ChangePasswordViewController()
        self.present(viewController, animated: true)
//        self.passwordDialog()
    }

    func deletePhoto() {
        self.updatePhoto()
    }
    
    // Mark:- Private
    fileprivate func requestSignin() {
        ImageClient.shared.requestKey(ofType: "profile_picture") { [weak self] result in
            
            guard let myself = self else { return }
            
            switch result {
            case .Success(let data):
                myself.imageUrl = data.0
                myself.imageKey = data.1
                myself.uploadImage()
            case .Failure(let error):
                if (error?.isNetworkError == true) {
                    Helper.alertNoNetRetry(myself, retryCase: AlertAction.retrySignin.rawValue, cancelCase: AlertAction.cancelSignin.rawValue)
                } else {
                    error?.record()
                }
            }
        }
    }
    
    fileprivate func uploadImage() {
        guard (!self.isUploading) else { return }
        
        guard let url = self.imageUrl else {
            self.requestSignin()
            return
        }
        
        print(ImageClient.shared.getUrl + self.imageKey)
        self.isUploading = true
        
        let uploader = ImageClient.shared.uploader(url, imageData: self.imageData!)
        
        uploader.progress = { progress in
            DispatchQueue.main.async {
                LoaderOverlay.shared.progress?.animate(toAngle: Double(progress) * 360.0)
            }
        }
        
        LoaderOverlay.shared.showProgress()
        self.isSavingProfile = true
        
        uploader.start { [weak self] response in
            
            guard let myself = self else { return }
            
            myself.isUploading = false
            
            guard (response.statusCode == 200) else {
                if (response.error?.isNetworkError == true) {
                    Helper.alertNoNetRetry(myself, retryCase: AlertAction.retryUpload.rawValue)
                } else {
                    UserMessage.shared.show(LocStr("Failure"), body: LocStr("Error.PhotoUploadFailed"))
                    response.error?.record()
                }
                myself.isSavingProfile = false
                LoaderOverlay.shared.hideProgress()
                return
            }
            
            myself.imageUrl = nil
            myself.imageData = nil
            myself.updatePhoto(with: myself.imageKey, showActivityIndicator: false)
        }
    }
    
    fileprivate func newProfileData(email: String? = nil, displayName: String? = nil, picture: String? = nil) -> User {
        let profile = User(
            id: self.profile.id,
            name: displayName ?? self.profile.name,
            username: self.profile.username,
            email: email ?? self.profile.email,
            picture: picture ?? self.profile.picture
        )
        return profile
    }
    
    private func updatePhoto(with key: String? = nil, showActivityIndicator: Bool = true) {
        self.imgUser.setupAvatar(imageKey, text: self.displayName, textColor: UIColor(white: 1.0, alpha: 0.4), animated: true)
        self.updataProfile(self.newProfileData(picture: imageKey), needUpdatePicture: true, showActivityIndicator: showActivityIndicator)
    }
    
    fileprivate func updataProfile(_ newProfile: User, needUpdatePicture: Bool = false, showActivityIndicator: Bool = true) {
        var params: [String: Any?] = [:]
        if (newProfile.name != self.profile.name) {
            if (newProfile.name == nil) {
                params["name"] = ""
                params.updateValue(newProfile.name, forKey: "name")
            } else {
                params["name"] = newProfile.name
            }
        }
        if (newProfile.email != self.profile.email) {
            if (newProfile.email == nil) {
                params["email"] = ""
                params.updateValue(newProfile.email, forKey: "email")
            } else {
                params["email"] = newProfile.email
            }
            params["email"] = newProfile.email
        }
        if (needUpdatePicture) {
            if (newProfile.picture == nil) {
                params["profile_picture"] = ""
                params.updateValue(newProfile.picture, forKey: "profile_picture")
            } else {
                params["profile_picture"] = newProfile.picture
            }
        }
        
        guard (params.count > 0) else { return }

        if (showActivityIndicator) {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.isSavingProfile = true
        }
        
        UserManager.saveProfile(params) { [weak self] result in

            guard let myself = self else { return }
            
            defer {
                myself.isSavingProfile = false
            }
            
            switch (result) {
            case .Success(_):

                UserManager.storeProfile(newProfile)
                myself.profile = newProfile

                if (!showActivityIndicator) {
                    LoaderOverlay.shared.tick()
                } else {
                    LoaderOverlay.shared.hide()
                }
                
                if (needUpdatePicture) {
                    let picture = newProfile.picture
                    if (picture == nil) {
                        myself.imgUser.image = nil
                    }
                    myself.imgUser.setupAvatar(picture, text: myself.displayName, textColor: UIColor(white: 1.0, alpha: 0.4), animated: true)
                }
                
            case .Failure(let error):
                LoaderOverlay.shared.hideProgress()
                UserMessage.shared.show(LocStr("Failure"), body: error)
            }
        }
    }
    
    private func savePassword(_ password: String) {

        LoaderOverlay.shared.show()
        self.isSavingProfile = true
        
        UserManager.saveProfile(["password": password]) { [weak self] result in
            
            LoaderOverlay.shared.hide()
            self?.isSavingProfile = false
            
            switch (result) {
            case .Success(_):
                break;
            case .Failure(let error):
                LoaderOverlay.shared.hide()
                UserMessage.shared.show(LocStr("Failure"), body: error)
            }
        }
    }
    
    fileprivate func importImage(_ source: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = source

        self.present(imagePicker, animated: true, completion: nil)
    }

    private func setupUI() {
        self.view.backgroundColor = Theme.Splash.lightColor
        self.edgesForExtendedLayout = UIRectEdge()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(closeAction))
        
        self.title = LocStr("Sidebar.EditProfile")
        
        let imageSize = min(Constants.screenSize.width * 0.56, 400.0)
        self.imgUserWidth.constant = imageSize
        self.imgUser.targetSize = imageSize
        self.imgUser.addTarget(target: self, action: #selector(photoAction))
        self.imgUser.isUserInteractionEnabled = true
        self.imgUser.setupAvatar(self.profile.picture, text: self.displayName, textColor: UIColor(white: 1.0, alpha: 0.4), animated: true)

        self.txtName.layer.cornerRadius = 8
        self.txtName.text = self.profile.name
        self.txtName.tag = ProfileInput.name.rawValue
        self.txtName.placeholder = LocStr("Profile.NamePlaceholder")
        self.txtName.isUserInteractionEnabled = true
        self.txtName.delegate = self
        
        let txtEmail = UITextField()
        txtEmail.text = self.profile.email
        txtEmail.delegate = self
        txtEmail.keyboardType = .emailAddress
        txtEmail.autocapitalizationType = .none
        txtEmail.tag = ProfileInput.email.rawValue
        txtEmail.textAlignment = .center
        txtEmail.placeholder = LocStr("Profile.EmailPlaceholder")
        txtEmail.font = self.txtName.font
        txtEmail.backgroundColor = self.txtName.backgroundColor
        txtEmail.layer.cornerRadius = txtName.layer.cornerRadius
        txtEmail.translatesAutoresizingMaskIntoConstraints = false
        self.profileView.addSubview(txtEmail)
        Helper.addConstraints(["H:|-0-[Input]-0-|", "V:[Input(30)]"], source: profileView, views: ["Input" : txtEmail])
        
        let btnPhoto = UIButton()
        btnPhoto.addTarget(self, action: #selector(photoAction), for: .touchUpInside)
        btnPhoto.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        btnPhoto.setImage(UIImage(named: "map_camera"), for: .normal)
        btnPhoto.backgroundColor = Theme.Splash.lighterColor
        btnPhoto.translatesAutoresizingMaskIntoConstraints = false
        btnPhoto.sizeToFit()
        btnPhoto.layer.cornerRadius = btnPhoto.frame.width / 2
        self.profileView.addSubview(btnPhoto)
        self.profileView.addConstraints([
            NSLayoutConstraint(item: txtEmail, attribute: .top, relatedBy: .equal, toItem: txtName, attribute: .bottom, multiplier: 1.0, constant: 12),
            NSLayoutConstraint(item: imgUser, attribute: .top, relatedBy: .equal, toItem: txtEmail, attribute: .bottom, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: btnPhoto, attribute: .top, relatedBy: .equal, toItem: imgUser, attribute: .bottom, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: btnPhoto, attribute: .bottom, relatedBy: .equal, toItem: profileView, attribute: .bottom, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: btnPhoto, attribute: .centerX, relatedBy: .equal, toItem: profileView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: btnPhoto, attribute: .height, relatedBy: .equal, toItem: btnPhoto, attribute: .width, multiplier: 1.0, constant: 0)
            ])
        
        [txtEmail, txtName].forEach {
            if let textField = $0 {
                let imgView = UIImageView(frame: CGRect(x: 0, y: 0, width: 28, height: 22))
                imgView.image = UIImage(named: "editable")
                imgView.contentMode = .right
                textField.leftView = imgView
                textField.leftViewMode = .always
            }
        }
    }

}

// MARK:- Image Picker and Viewer Delegates
extension AccountViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)

        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage, let data = UIImageJPEGRepresentation(image, 1.0) else { return }
        
        // let oriented = image.cgImage?.convert(to: image.imageOrientation, size: image.size)
        // let bytes = 1536000 // 1.5mb
        // let resized = oriented?.resize(toBytes: bytes) ?? image.resize(toBytes: bytes)
        // self.imageData = resized ?? UIImageJPEGRepresentation(oriented ?? image, 1.0)!
        
        self.imageData = data
        self.imgUser.image = image
        self.imgUser.removePlaceholder()
        self.uploadImage()
    }
}

extension AccountViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let input = ProfileInput(rawValue: textField.tag) else { return }
        
        let newValue = textField.text?.trim()
        var newProfile: User?
        
        switch input {
        case .name:
            if (self.profile.name != newValue) {
                newProfile = self.newProfileData(displayName: newValue)
            }
        case .email:
            guard (self.profile.email != newValue) else { return }
            
            if let email = newValue, !Helper.isValidEmail(email) {
                textField.errorShake()
                return
            }
            
            newProfile = self.newProfileData(email: newValue)
        }
        
        if (newProfile != nil) {
            self.updataProfile(newProfile!)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}

extension AccountViewController: AlertViewControllerDelegate {
    
    func alertAction(_ actionCase: Int) {
        guard let m = AlertAction(rawValue: actionCase) else { return }
        
        switch m {
        case .cancelSignin:
            self.imageData = nil
            self.imgUser.setupAvatar(self.profile.picture, text: self.displayName, textColor: UIColor(white: 1.0, alpha: 0.4), animated: false)
        case .retrySignin:
            if (self.imageUrl == nil) {
                self.requestSignin()
            }
        case .retryUpload:
            self.uploadImage()
        }
    }
    
}
