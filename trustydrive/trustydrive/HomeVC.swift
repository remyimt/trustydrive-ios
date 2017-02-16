//
//  HomeVV.swift
//  modal-experiment
//
//  Created by Sebastian on 07/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit
import QuickLook
import Photos

class HomeVC: UIViewController, FolderRenderer {
    
    var imagePickerHelper: ImagePickerHelper?
    //var qlFileHelper: QLFileHelper?
    var file: File?
    var files: [File]!
    var fileTableDataSource: FileTableDS!
    var urls = [NSURL]()
    @IBOutlet weak var tableView: UITableView!
    //let quickLookController = QLPreviewController()
    //var tableViewDelgate: UITableViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "FileCell", bundle: nil), forCellReuseIdentifier: "FileCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard (FileStore.data.files != nil) else {
            performSegue(withIdentifier: "showLogin", sender: self)
            return
        }
        if let files = FileStore.data.files {
            self.files = files
            
            self.fileTableDataSource = FileTableDS(files: self.files!)
            self.fileTableDataSource.delegate = self
            
            tableView!.dataSource = self.fileTableDataSource
            tableView!.delegate = self.fileTableDataSource
            tableView!.reloadData()
        }
        self.imagePickerHelper = ImagePickerHelper()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case .some("showMove"):
            let destinationNavigationController = segue.destination as! UINavigationController
            let targetController = destinationNavigationController.topViewController as! MoveVC
            let fileToMove = sender as! File
            targetController.previousAbsolutePath = self.getCurrentPath()
            targetController.files = self.files.filter{ file in file.type == .directory && file != fileToMove }
            targetController.file = fileToMove
            targetController.delegate = self
        default:
            break
        }
    }
    
    
    @IBAction func addButtonClicked() {
        self.displayActionSheet()
    }
    
    
    
    //QLPreviewControllerDataSource protocol
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.urls.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.urls[index]
    }
    
    
}


