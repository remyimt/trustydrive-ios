//
//  AddAccountVC.swift
//  modal-experiment
//
//  Created by Sebastian on 08/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit
import SwiftyDropbox

class AddAccountVC: UIViewController {
    
    @IBAction func withDropbox() {
        DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                      controller: self,
                                                      openURL: { (url: URL) -> Void in
                                                        UIApplication.shared.open(url, options: [:], completionHandler: {_ in
                                                            _ = self.navigationController?.popViewController(animated: true)
                                                        })
        })
    }
    
}
