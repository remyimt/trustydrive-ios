import UIKit

class SettingsVC: UIViewController, UITableViewDataSource, AccountStoreDelgate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingEmail: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingEmail.hidesWhenStopped = true
        tableView.dataSource = self
        AccountManager.sharedInstance.accountStoreDelegate = self
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func logout() {
        TDFileManager.sharedInstance.files = nil
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    //AccountStoreDelegate protocol
    
    func willFetch() {
        self.loadingEmail.startAnimating()
    }
    
    func didChange(accounts: [Account]) {
        self.tableView.reloadData()
        self.loadingEmail.stopAnimating()
    }
    
    //UITableViewDataSource protocol
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AccountManager.sharedInstance.accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let token = AccountManager.sharedInstance.accounts[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProviderCell")!
        cell.textLabel?.text = token.email
        cell.detailTextLabel?.text = token.provider.rawValue
        
        return cell
    }
    
}
