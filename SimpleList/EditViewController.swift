//
//  EditViewController.swift
//  SimpleList
//
//  Created by 能登 要 on 2018/07/28.
//  Copyright © 2018年 Kaname Noto. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class EditViewController: UIViewController {

    public var documentID:String = ""
    @IBOutlet private weak var textView: UITextView!
    
    private let firestore = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private var lastUpdateText:String?

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.isEditable = false
        
        if let user = Auth.auth().currentUser {
            listener = firestore.collection("user").document(user.uid).collection("list").document(documentID).addSnapshotListener({ [unowned self] (snapshot, error) in
                if let error = error {
                    print("error getting document: \(error.localizedDescription)")
                    return
                }

                if let listItem:ListItem = snapshot?.data() {
                    self.textView.text = listItem["text"] as? String
                    self.textView.isEditable = true
                    self.textView.becomeFirstResponder()
                }
                
                self.listener?.remove()
                self.listener = nil
            })
        }
    }

    override func didMove(toParentViewController parent: UIViewController?) {
        if !(self.parent?.isEqual(parent) ?? false) {
            updateText()
        }
    }
    
    
    deinit {
        listener?.remove()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
}

extension EditViewController : UITextViewDelegate
{
    @objc func updateText(){
        if let user = Auth.auth().currentUser,let lastUpdateText = lastUpdateText {
            firestore.collection("user").document(user.uid).collection("list").document(documentID).updateData(["text" : lastUpdateText])
            self.lastUpdateText = nil
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        lastUpdateText = textView.text
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateText), object: nil)
        self.perform(#selector(updateText), with: nil, afterDelay: 3.0)
    }
}
