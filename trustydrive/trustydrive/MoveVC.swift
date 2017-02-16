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
        let path = self.navigationController!.viewControllers.map { controller in controller.navigationItem.title! }
        print("The file to move: \(self.file)")
        print("With absolute path: \(path)")
        self.dismiss(animated: true, completion: nil)
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
        vc.navigationItem.title = file.name
        
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
}
