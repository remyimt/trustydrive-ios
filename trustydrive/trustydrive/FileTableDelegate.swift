//
//  FileTableDS.swift
//  modal-experiment
//
//  Created by Sebastian on 07/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit

class FileTableDS: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    var files: [File]
    var delegate: FolderRenderer?
    
    init(files: [File]) {
        self.files = files
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let file = self.files[indexPath.row]
        
        let cell: FileCell = tableView.dequeueReusableCell(withIdentifier: "FileCell") as! FileCell
        
        cell.name.text = file.name
        
        
        switch(file.type) {
        case .directory:
            cell.icon.image = UIImage(named: "directory")
        default:
            cell.icon.image = UIImage(named: "file")
            
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let file = self.files[indexPath.row]
        
        let moreAction = UITableViewRowAction(style: .default, title: "More") { action, indexPath in
            self.delegate?.displayMore(file: file)
        }
        moreAction.backgroundColor = UIColor(red: 212.0/255.0, green: 212/255.0, blue: 212.0/255.0, alpha: 1)
        
        let downloadAction = UITableViewRowAction(style: .default, title: "Download") { action, indexPath in
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            print(documentsDirectory)
            FileStore.data.download(file: file, directory: documentsDirectory) { _ in
                print("done")
            }
        }
        
        downloadAction.backgroundColor = UIColor(red: 42.0/255.0, green: 147.0/255.0, blue: 233.0/255.0, alpha: 1)
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { action, indexPath in
            let file = self.files[indexPath.row]
            
            let path: String = self.delegate!.getCurrentPath()
            
            FileStore.data.delete(file: file) { _ in
                if let _ = FileStore.data.remove(absolutePath: "\(path)/\(file.name)") {
                    self.delegate!.displayLoadingAction(message: "Deleting file..")
                    AccountStore.singleton.uploadMetadata {
                        self.files.remove(at: indexPath.row)
                        self.delegate!.files.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        self.delegate!.dismissLoadingAction()
                    }
                }
            }
            
        }
        
        return [deleteAction, moreAction, downloadAction]
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let file = files[indexPath.row]
        
        switch file.type {
        case .file:
            //let vc = self.delegate?.instantiateViewController(withIdentifier: "FileVC") as! FileVC
            //vc.file = file
            //self.navigationController!.pushViewController(vc, animated: true)
            delegate?.preview(file: file)
        case.directory:
            //let vc = self.delegate?.instantiateViewController(withIdentifier: "DirectoryVC") as! DirectoryVC
            //vc.file = file
            //vc.files = file.files!
            //self.navigationController!.pushViewController(vc, animated: true)
            delegate?.openDirectory(file: file)
        case.image:
            //let vc = self.storyboard!.instantiateViewController(withIdentifier: "FileVC") as! FileVC
            //vc.file = file
            //self.navigationController!.pushViewController(vc, animated: true)
            delegate?.preview(file: file)
        }
        
    }
    
}
