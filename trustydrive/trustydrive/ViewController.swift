//
//  ViewController.swift
//  modal-experiment
//
//  Created by Sebastian on 05/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var logged = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !logged {
            self.performSegue(withIdentifier: "showLogin", sender: self)
            logged = true
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

