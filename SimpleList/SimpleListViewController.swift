//
//  SimpleListViewController.swift
//  SimpleList
//
//  Created by 能登 要 on 2018/07/28.
//  Copyright © 2018年 Kaname Noto. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

typealias ListItem = [String:Any]

enum ListStatus
{
    case none
    case updated
}

class SimpleListViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    
    private let firestore = Firestore.firestore()
    
    private var handle: AuthStateDidChangeListenerHandle?
    private var listener: ListenerRegistration?
    
    private var lists = [ListItem]()
    private var documentIDs = [String]()
    private var listStatus:ListStatus = .none
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = editButtonItem
        
        
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            guard let user = user  else {
                return
            }
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.navigationItem.leftBarButtonItem?.isEnabled = true
            
            self.listener?.remove()
            self.listener = self.firestore.collection("user").document(user.uid).collection("list").order(by: "timestamp").addSnapshotListener({ (snapshot, error) in
                if let error = error {
                    print("error getting collection: \(error.localizedDescription)")
                    return
                }
                
                guard let collectionSnapshot = snapshot else { return }
                
                switch self.listStatus {
                case .none:
                    for snapshot in collectionSnapshot.documents {
                        self.lists.append(snapshot.data())
                        self.documentIDs.append(snapshot.documentID)
                    }
                    self.listStatus = .updated
                    self.tableView.reloadData()
                case .updated:
                    var insertRows = [IndexPath]()
                    var updateRows = [IndexPath]()
                    for documentChange in collectionSnapshot.documentChanges {
                        switch documentChange.type {
                        case .added:
                            self.lists.insert(documentChange.document.data(), at: Int(documentChange.newIndex))
                            self.documentIDs.insert(documentChange.document.documentID, at: Int(documentChange.newIndex))
                            
                            let indexPath = IndexPath(row: Int(documentChange.newIndex), section: 0)
                            insertRows.append(indexPath)
                            break
                        case .modified:
                            self.lists[Int(documentChange.newIndex)] = documentChange.document.data()
                            let indexPath = IndexPath(row: Int(documentChange.newIndex), section: 0)
                            updateRows.append(indexPath)
                            break
                        case .removed:
                            break
                        }
                    }
                    
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: insertRows, with: .fade)
                    self.tableView.reloadRows(at: updateRows, with: .fade)
                    self.tableView.endUpdates()
                }
            })
        }
    }
    
    deinit {
        listener?.remove()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        tableView.setEditing(editing, animated: animated)
    }
    
    @IBAction func addAction(_ sender: UIBarButtonItem) {
        guard let user = Auth.auth().currentUser else { return }
        
        let document = firestore.collection("user").document(user.uid).collection("list").document()
        
        let now = Date()
        
        var listItem = ListItem()
        listItem["timestamp"] = Timestamp(date: now)
        listItem["text"] = "新しいテキスト"
        
        document.setData(listItem)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "editSegue":
            if let indexPath = tableView.indexPathForSelectedRow,let evc = segue.destination as? EditViewController {
                evc.documentID = documentIDs[indexPath.row]
            }
        default:
            break
        }
    }
    
}

extension SimpleListViewController : UITableViewDelegate,UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let listItem = lists[indexPath.row]
        if let timestamp = listItem["timestamp"] as? Date,let text = listItem["text"] as? String {
            cell.textLabel?.text = text
            cell.detailTextLabel?.text = timestamp.description
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        switch editingStyle {
        case .delete:
            let documentID = documentIDs[indexPath.row]
            lists.remove(at: indexPath.row)
            documentIDs.remove(at: indexPath.row)
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
            
            guard let user = Auth.auth().currentUser else { return }
            let listItem = firestore.collection("user").document(user.uid).collection("list").document(documentID)
            listItem.delete()
        default:
            break
        }
    }
    
}
