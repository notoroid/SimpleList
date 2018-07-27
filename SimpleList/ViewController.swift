//
//  ViewController.swift
//  SimpleList
//
//  Created by 能登 要 on 2018/07/28.
//  Copyright © 2018年 Kaname Noto. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth

class ViewController: UIViewController {

    private var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        handle = Auth.auth().addStateDidChangeListener { [unowned self] (auth, user) in
            if user != nil {
                self.performSegue(withIdentifier: "showSimpleListSegue", sender: nil)
                return
            }
        }
        
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { (result, error) in
                if let error = error as NSError? {
                    fatalError("error=\(error.localizedDescription)")
                }
            }
        }
        
    }
    
    deinit {
        Auth.auth().removeStateDidChangeListener(handle!)
    }

}

