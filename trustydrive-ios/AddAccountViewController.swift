//
//  AddAccountViewController.swift
//  trustydrive-ios
//
//  Created by Tim Rault on 2017-01-20.
//  Copyright © 2017 TrustyDrive. All rights reserved.
//

import UIKit
import SwiftyDropbox

class AddAccountViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dropboxButtonPressed(_ sender: Any) {
        DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self,
                                                      openURL: { (url: URL) -> Void in
                                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
