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
    weak var delegate: DirectoryUI!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "FileCell", bundle: nil), forCellReuseIdentifier: "FileCell")
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done() {
        let newPath = self.navigationController!.viewControllers.map { controller in controller.navigationItem.title! }.joined(separator: "/")
        print("The file to move: \(self.file)")
        print("With absolute path: \(newPath)")
        
        let loadingController = self.displayLoadingAction(message: "Moving file")
        if TDFileManager.sharedInstance.move(file: self.file, previousPath: "\(self.previousAbsolutePath!)/\(self.file.name)", newPath: newPath) {
            AccountManager.sharedInstance.uploadMetadata {
                loadingController.dismiss(animated: true) {
                    self.dismiss(animated: true) {
                        self.delegate.doneMovingFile()
                    }
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
        vc.delegate = self.delegate
        
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
