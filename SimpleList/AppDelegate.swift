//
//  AppDelegate.swift
//  SimpleList
//
//  Created by 能登 要 on 2018/07/28.
//  Copyright © 2018年 Kaname Noto. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        return true
    }

}

