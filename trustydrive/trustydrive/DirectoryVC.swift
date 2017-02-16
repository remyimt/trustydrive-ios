//
//  DirectoryVC.swift
//  modal-experiment
//
//  Created by Sebastian on 07/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit
import QuickLook

class DirectoryVC: UIViewController, FolderRenderer {
    
    //let quickLookController = QLPreviewController()
    var urls = [NSURL]()
    var imagePickerHelper: ImagePickerHelper?
    //var qlFileHelper: QLFileHelper?
    var file: File?
    var files: [File]!
    var fileTableDataSource: FileTableDS!
    @IBOutlet weak var tableView: UITableView!
    //var tableViewDelgate: UITableViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "FileCell", bundle: nil), forCellReuseIdentifier: "FileCell")
        
        self.navigationItem.title = file!.name
        
        self.fileTableDataSource = FileTableDS(files: files!)
        self.fileTableDataSource.delegate = self
        tableView!.dataSource = self.fileTableDataSource
        tableView!.delegate = self.fileTableDataSource
        self.imagePickerHelper = ImagePickerHelper()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "showMove":
            let destinationNavigationController = segue.destination as! UINavigationController
            let targetController = destinationNavigationController.topViewController as! MoveVC
            let fileToMove = sender as! File
            targetController.files = FileStore.data.files!.filter{ file in file.type == .directory && file != fileToMove }
            targetController.file = fileToMove
        default:
            break
        }
    }
    
    @IBAction func addButtonClicked() {
        self.displayActionSheet()
    }

    
}
