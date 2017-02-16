//
//  FolderRenderer.swift
//  trustydrive
//
//  Created by Sebastian on 14/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit
import Photos
import QuickLook

protocol FolderRenderer: UITableViewDelegate {
    //var urls: [NSURL] {get set}
    var file: File? {get set}
    var files: [File]! {get set}
    //var quickLookController: QLPreviewController {get}
    var imagePickerHelper: ImagePickerHelper? {get set}
    weak var tableView: UITableView! {get set}
    var fileTableDataSource: FileTableDS! {get set}
    //var qlFileHelper: QLFileHelper? {get set}
    func displayActionSheet()
    func displayImportFileActionSheet()
    func displayMore(file: File)
    func preview(file: File)
    func openDirectory(file: File)
    func displayLoadingAction(message: String)
    func getCurrentPath() -> String
    func dismissLoadingAction()
    func didChoosePhoto(fileData: Data, fileName: String)
    //var tableViewDelgate: UITableViewDelegate? {get set}
}

extension FolderRenderer where Self: UIViewController {
    
    func preview(file: File) {
        displayLoadingAction(message: "Downloading file from TrustyDrive...")
        FileStore.data.download(file: file) { url in
            let urls = [url as NSURL]
            let qlFileHelper = QLFileHelper()
            qlFileHelper.urls = urls
            let quickLookController = QLPreviewController()
            quickLookController.dataSource = qlFileHelper
            quickLookController.reloadData()
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.pushViewController(quickLookController, animated: true)
        }
    }
    
    func displayLoadingAction(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alert.view.tintColor = UIColor.black
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50)) as UIActivityIndicatorView
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    func openDirectory(file: File) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "DirectoryVC") as! DirectoryVC
        vc.file = file
        vc.files = file.files!
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    func displayActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let addFileAction = UIAlertAction(title: "Import file", style: .default) { action in
            self.displayImportFileActionSheet()
        }
        
        alertController.addAction(addFileAction)
        
        let addFolderAction = UIAlertAction(title: "Create folder", style: .default) { action in
            self.displayCreateFolderAlert()
        }
        
        alertController.addAction(addFolderAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func displayImportFileActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let fromCameraRollAction = UIAlertAction(title: "From camera roll", style: .default) { action in
            self.imagePickerHelper = ImagePickerHelper()
            self.imagePickerHelper!.delegate = self
            
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self.imagePickerHelper
            
            self.present(imagePickerController, animated: true, completion: nil)
        }
        
        alertController.addAction(fromCameraRollAction)
        
        let fromCameraAction = UIAlertAction(title: "From camera", style: .default) { action in
            print("create folder")
        }
        
        alertController.addAction(fromCameraAction)
        
        let importAction = UIAlertAction(title: "Import ...", style: .default) { action in
            print("create folder")
        }
        
        alertController.addAction(importAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func displayCreateFolderAlert() {
        let alertController = UIAlertController(title: "Create Folder", message: "Please enter the new folder name:", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                
                let path = self.getCurrentPath()
                
                let name = field.text!
                let absolutePath = "\(path)/\(name)"
                
                if let file = FileStore.data.mkdir(name: name, absolutePath: absolutePath) {
                    self.displayLoadingAction(message: "Creating Folder...")
                    AccountStore.singleton.uploadMetadata {
                        self.files.append(file)
                        self.fileTableDataSource.files.append(file)
                        self.tableView.beginUpdates()
                        self.tableView.insertRows(at: [IndexPath(row: self.files.count-1, section: 0)], with: .automatic)
                        self.tableView.endUpdates()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Folder Name"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func displayMore(file: File) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let renameAction = UIAlertAction(title: "Rename", style: .default) { action in
            
        }
        alertController.addAction(renameAction)
        
        let moveAction = UIAlertAction(title: "Move", style: .default) { action in
            print(self)
            self.performSegue(withIdentifier: "showMove", sender: file)
        }
        alertController.addAction(moveAction)
        
        let infoAction = UIAlertAction(title: "View info", style: .default) { action in
            
        }
        alertController.addAction(infoAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
    func getCurrentPath() -> String {
        let stack = self.navigationController!.viewControllers.map { controller in controller.navigationItem.title! }
        return stack.joined(separator: "/")
    }
    
    func dismissLoadingAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func didChoosePhoto(fileData: Data, fileName: String) {
        self.displayLoadingAction(message: "Uploading photo to TrustyDrive..")
        FileStore.data.upload(fileData: fileData, fileName: fileName) {file in
            if FileStore.data.addFile(file: file, absolutePath: self.getCurrentPath()) {
                AccountStore.singleton.uploadMetadata {
                    self.dismissLoadingAction()
                    self.files.append(file)
                    self.fileTableDataSource.files.append(file)
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: [IndexPath(row: self.files.count-1, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                    self.dismissLoadingAction()
                }
            }
        }

    }

    
}
