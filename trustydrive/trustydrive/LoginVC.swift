//
//  LoginVC.swift
//  modal-experiment
//
//  Created by Sebastian on 05/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit
import SwiftyDropbox

class LoginVC: UIViewController, UITableViewDataSource, UITextFieldDelegate, AccountStoreDelgate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var loadingEmail: UIActivityIndicatorView!
    @IBOutlet weak var verifyingUserView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var loadingSignIn: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        passwordTxt.delegate = self
        AccountStore.singleton.delegate = self
        loadingEmail.hidesWhenStopped = true
        loadingSignIn.hidesWhenStopped = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismiss() {
        AccountStore.singleton.login(password: passwordTxt.text!)
    }
    
    
    //TokenStoreDelegate
    
    func accountWillFetch() {
        self.loadingEmail.startAnimating()
    }
    
    func accountsDidChange(accounts: [Account]) {
        self.tableView.reloadData()
        self.loadingEmail.stopAnimating()
        checkButtonState(string: self.passwordTxt.text!)
    }
    
    func loginWillStart() {
        self.contentView.isHidden = true
        self.verifyingUserView.isHidden = false
        self.loadingSignIn.startAnimating()
    }
    
    func loginSuccess(result: Bool) {
        if result {
            super.dismiss(animated: true, completion: nil)
        }
    }
    
    //UITableViewDataSource Protocol
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AccountStore.singleton.accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let token = AccountStore.singleton.accounts[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProviderCell")!
        cell.textLabel?.text = token.email
        
        
        return cell
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        checkButtonState(string: textField.text! + string)
        return true
    }
    
    private func checkButtonState(string: String) {
        if string.characters.count > 0 && AccountStore.singleton.accounts.count > 0{
            self.loginBtn.isEnabled = true
            self.loginBtn.alpha = 1
            
        } else {
            self.loginBtn.isEnabled = false
            self.loginBtn.alpha = 0.5
            
        }
    }
    

}
