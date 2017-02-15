//
//  HomeVV.swift
//  modal-experiment
//
//  Created by Sebastian on 07/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit
import QuickLook

class HomeVC: UIViewController, UITableViewDelegate, QLPreviewControllerDataSource {
    
    
    var files: [File]!
    var fileTableDataSource: FileTableDS!
    var urls = [NSURL]()
    @IBOutlet weak var tableView: UITableView!
    let quickLookController = QLPreviewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            
            tableView!.dataSource = self.fileTableDataSource
            tableView!.delegate = self
            tableView!.reloadData()
        }
        
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let file = files![indexPath.row]
        
        switch file.type {
        case .file:
            //let vc = self.storyboard!.instantiateViewController(withIdentifier: "FileVC") as! FileVC
            //vc.file = file
            //self.navigationController!.pushViewController(vc, animated: true)
            self.preview(file: file)
        case.directory:
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "DirectoryVC") as! DirectoryVC
            vc.file = file
            vc.files = file.files!
            self.navigationController!.pushViewController(vc, animated: true)
        case.image:
            //let vc = self.storyboard!.instantiateViewController(withIdentifier: "FileVC") as! FileVC
            //vc.file = file
            //self.navigationController!.pushViewController(vc, animated: true)
            self.preview(file: file)
        }
        
    }
    
    func preview(file: File) {
        FileStore.data.download(file: file) { url in
            self.urls.append(url as NSURL)
            self.quickLookController.dataSource = self
            self.quickLookController.reloadData()
            self.navigationController?.pushViewController(self.quickLookController, animated: true)
        }
    }
    
    //QLPreviewControllerDataSource protocol
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.urls.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.urls[index]
    }
    
    
}


