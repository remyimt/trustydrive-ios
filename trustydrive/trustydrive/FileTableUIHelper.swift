//
//  FileTableDS.swift
//  modal-experiment
//
//  Created by Sebastian on 07/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit

class FileTableUIHelper: NSObject, UITableViewDataSource, UITableViewDelegate {

    var files: [File]
    var delegate: DirectoryUI!

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
            if file.localName != nil {
                cell.icon.image = UIImage(named: "savedFile")
            }
            else {
                cell.icon.image = UIImage(named: "file")
            }

        }
        return cell

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        var actions = [UITableViewRowAction]()

        let file = self.files[indexPath.row]

        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { action, indexPath in
            let file = self.files[indexPath.row]

            let path: String = self.delegate!.getCurrentPath()
            let absolutePath = "\(path)/\(file.name)"

            TDFileManager.sharedInstance.delete(file: file) { _ in
                if let file = TDFileManager.sharedInstance.remove(absolutePath: absolutePath) {
                    self.delegate!.displayLoadingAction(message: "Deleting file..")
                    
                    if file.localName != nil {
                        LocalFileManager.sharedInstance.remove(absolutePath: absolutePath)
                    }
                    
                    AccountManager.sharedInstance.uploadMetadata {
                        self.files.remove(at: indexPath.row)
                        self.delegate!.files.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        self.delegate!.dismissLoadingAction()
                    }
                }
            }

        }
        actions.append(deleteAction)

        let moreAction = UITableViewRowAction(style: .default, title: "More") { action, indexPath in
            self.delegate.displayMore(file: file)
            tableView.isEditing = false
        }
        moreAction.backgroundColor = UIColor(red: 212.0/255.0, green: 212/255.0, blue: 212.0/255.0, alpha: 1)
        actions.append(moreAction)

        if(file.type != .directory && file.localName == nil) {
            let downloadAction = UITableViewRowAction(style: .default, title: "Download") { action, indexPath in
                let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                print(documentsDirectory)
                self.delegate.displayLoadingAction(message: "Saving file from TrustryDrive...")
                TDFileManager.sharedInstance.download(file: file, directory: documentsDirectory) { url, error in
                    self.delegate.dismissLoadingAction()
                    if let url = url {
                        
                        let lastPathComponent = url.lastPathComponent

                        let absolutePath = "\(self.delegate!.getCurrentPath())/\(file.name)"

                        if(TDFileManager.sharedInstance.setLocalName(localName: lastPathComponent, absolutePath: absolutePath) != nil) {
                            LocalFileManager.sharedInstance.localFiles.append(LocalFile(absolutePath: absolutePath, lastPathComponent: lastPathComponent))
                            LocalFileManager.sharedInstance.saveToUserDefaults()
                            let cell = tableView.cellForRow(at: indexPath) as! FileCell
                            self.files[indexPath.row].localName = lastPathComponent
                            self.delegate.files[indexPath.row].localName = lastPathComponent
                            cell.icon.image = UIImage(named: "savedFile")
                        }
                    } else if let error = error {
                        self.delegate.displayAlertAction(message: error.message)
                    }
                }
                tableView.isEditing = false
            }

            downloadAction.backgroundColor = UIColor(red: 20.0/255.0, green: 128.0/255.0, blue: 225.0/255.0, alpha: 1)
            actions.append(downloadAction)

        }


        return actions
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
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
}
