import UIKit

class FileVC: UIViewController {
    
    var file: File!
    @IBOutlet weak var name: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = file.name
    }
    
}
