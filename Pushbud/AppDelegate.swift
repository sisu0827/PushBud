//
//  AppDelegate.swift
//  Pushbud
//
//  Created by Daria.R on 4/13/17.
//  Copyright © 2017 meQuire AS. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import GooglePlaces
import Sentry
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, EMChatManagerDelegate, EMClientDelegate, EMContactManagerDelegate {
    
    var window: UIWindow?
    var mapViewController: MapViewController? {
        let navVC = self.window!.rootViewController as? UINavigationController
        return navVC?.viewControllers.first as? MapViewController
    }
    
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Config.apiGmtFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        Config.apiGmtFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" // OLD  "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        Fabric.with([Crashlytics.self])
        GMSServices.provideAPIKey(Constants.mapKey)
        GMSPlacesClient.provideAPIKey(Constants.mapKey)
        
        if Config.shared.isChatEnable {
            EMClient.shared().add(self)
            EMClient.shared().chatManager.add(self)
            EMClient.shared().contactManager.add(self)
        }

        // Create a Sentry client and start crash handler
        do {
              Client.shared = try Client(dsn: "https://b81f62db66ba43f99f627cb78ae1c4cb:306627ca488b42d8a061796d1cac5e7f@sentry.io/160053")
            try Client.shared?.startCrashHandler()
        } catch let error {
            print("\(error)")
        }
       
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        var rootVC: UIViewController
        
        if UserManager.authenticateFromStorage() {
            rootVC = MapViewController()
        } else {
            rootVC = LoginViewController()
        }
        
        self.window!.rootViewController = CommonNavigationController(rootViewController: rootVC)
        self.window!.makeKeyAndVisible()
        
        Theme.setUpAppearance()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        self.storeUserLocation()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    private func storeUserLocation() {
        guard
            let navVC = self.window?.rootViewController as? UINavigationController,
            let mapVC = navVC.viewControllers.first as? MapViewController,
            let coord = mapVC.mapCamera?.target
        else {
            return
        }
        
        UserStorage.shared.store(object: "\(coord.latitude)|\(coord.longitude)|\(mapVC.mapCamera!.zoom)", forKey: StorageConstants.keyLastUserLocation)
    }
    
    /* Push notification methods */
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        
            
            let token = deviceToken.map{ String(format: "%02.2hhx", $0) }.joined()
            let device = Device(id: nil, apnToken: token)
            DeviceManager.register(device)
            self.tokenRefreshAction()
        
      
    }
    

    
    
    func tokenRefreshAction() {
    }
    
}


@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        
        print(userInfo)
        
//        if UIApplication.shared.state == .inactive || UIApplication.shared.state == .background {
//            // TODO : - action when in background
//        }
//        if let messageId = userInfo[gcmMessageIDKey], let aps = userInfo["aps"] as? [String : Any] {
//            let content = NotificationContent(userInfo: userInfo, aps: aps)
//            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3.0, repeats: false)
//            let request = UNNotificationRequest(identifier: "requestIdentifier\(messageId)", content: content, trigger: trigger)
//            UNUserNotificationCenter.current().add(request) { error in
//                guard (content.notificationCategory != nil && error == nil) else { return }
//            }
//        }
        
        completionHandler([.alert,.sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
}

