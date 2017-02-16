//
//  MoveVC.swift
//  trustydrive
//
//  Created by Sebastian on 15/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit

class MoveVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    var file: File!
    var files: [File]!
    var previousAbsolutePath: String!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "FileCell", bundle: nil), forCellReuseIdentifier: "FileCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.reloadData()
    }
    
    @IBAction func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done() {
        let newPath = self.navigationController!.viewControllers.map { controller in controller.navigationItem.title! }.joined(separator: "/")
        print("The file to move: \(self.file)")
        print("With absolute path: \(newPath)")
        
        //TODO Call Move, update meta and dismiss on callback
        let loadingController = self.displayLoadingAction(message: "Moving file")
        if FileStore.data.move(file: self.file, previousPath: "\(self.previousAbsolutePath!)/\(self.file.name)", newPath: newPath) {
            AccountStore.singleton.uploadMetadata {
                loadingController.dismiss(animated: true) {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let file = self.files[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell") as! FileCell
        cell.name.text = file.name
        cell.icon.image = UIImage(named: "directory")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = files[indexPath.row]
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MoveVC") as! MoveVC
        vc.file = self.file
        vc.files = file.files!.filter {file in file.type == .directory && self.file != file}
        vc.previousAbsolutePath = self.previousAbsolutePath
        vc.navigationItem.title = file.name
        
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    func displayLoadingAction(message: String)-> UIAlertController {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alert.view.tintColor = UIColor.black
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50)) as UIActivityIndicatorView
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
        return alert
    }
    
}
