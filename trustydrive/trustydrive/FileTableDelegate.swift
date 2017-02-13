//
//  FileTableDS.swift
//  modal-experiment
//
//  Created by Sebastian on 07/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit

class FileTableDS: NSObject, UITableViewDataSource {
    
    let files: [File]
    
    init(files: [File]) {
        self.files = files
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let file = self.files[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell")!
        cell.textLabel?.text = file.name
        
    
        return cell
        
    }
    
}
