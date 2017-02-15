//
//  SettingsVC.swift
//  trustydrive
//
//  Created by Sebastian on 14/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit

class SettingsVC: UIViewController, UITableViewDataSource, AccountStoreDelgate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingEmail: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingEmail.hidesWhenStopped = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.dataSource = self
        AccountStore.singleton.accountStoreDelegate = self
        self.tableView.reloadData()
    }
    
    @IBAction func logout() {
        FileStore.data.files = nil
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func willFetch() {
        self.loadingEmail.startAnimating()
    }
    
    func didChange(accounts: [Account]) {
        self.tableView.reloadData()
        self.loadingEmail.stopAnimating()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AccountStore.singleton.accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let token = AccountStore.singleton.accounts[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProviderCell")!
        cell.textLabel?.text = token.email
        
        
        return cell
    }
    
}
