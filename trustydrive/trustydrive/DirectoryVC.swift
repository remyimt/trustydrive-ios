//
//  DirectoryVC.swift
//  modal-experiment
//
//  Created by Sebastian on 07/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit

class DirectoryVC: UIViewController, UITableViewDelegate {
    
    var file: File!
    var files: [File]!
    var fileTableDataSource: FileTableDS!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = file.name
        
        self.fileTableDataSource = FileTableDS(files: files!)
        tableView!.dataSource = self.fileTableDataSource
        tableView!.delegate = self
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let file = files![indexPath.row]
        
        switch file.type {
        case .file:
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "FileVC") as! FileVC
            vc.file = file
            self.navigationController!.pushViewController(vc, animated: true)
        case .directory:
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "DirectoryVC") as! DirectoryVC
            vc.file = file
            vc.files = file.files!
            self.navigationController!.pushViewController(vc, animated: true)
        case .image:
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "FileVC") as! FileVC
            vc.file = file
            self.navigationController!.pushViewController(vc, animated: true)
        }
    }
    
    
}
