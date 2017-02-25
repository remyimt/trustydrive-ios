import UIKit
import QuickLook

class DirectoryVC: UIViewController, DirectoryUI {
    
    var urls = [NSURL]()
    var imagePickerHelper: ImagePickerUIHelper?
    var file: File?
    var files: [File]!
    var fileTableUIHelper: FileTableUIHelper!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "FileCell", bundle: nil), forCellReuseIdentifier: "FileCell")
        
        self.file = TDFileManager.sharedInstance.getFile(at: self.getCurrentPath())
        self.files = file!.files
        
        self.fileTableUIHelper = FileTableUIHelper()
        self.fileTableUIHelper.delegate = self
        tableView!.dataSource = self.fileTableUIHelper
        tableView!.delegate = self.fileTableUIHelper
        self.imagePickerHelper = ImagePickerUIHelper()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "showMove":
            let destinationNavigationController = segue.destination as! UINavigationController
            let targetController = destinationNavigationController.topViewController as! MoveVC
            let fileToMove = sender as! File
            targetController.previousAbsolutePath = self.getCurrentPath()
            targetController.files = TDFileManager.sharedInstance.files!.filter{ file in file.type == .directory && file != fileToMove }
            targetController.file = fileToMove
            targetController.delegate = self
        default:
            break
        }
    }
    
    @IBAction func addButtonClicked() {
        self.displayActionSheet()
    }

    
}
