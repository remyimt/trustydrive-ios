import UIKit
import QuickLook
import Photos

class HomeVC: UIViewController, DirectoryUI {
    
    var imagePickerHelper: ImagePickerUIHelper?
    var file: File?
    var files: [File]!
    var fileTableUIHelper: FileTableUIHelper!
    var urls = [NSURL]()
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "FileCell", bundle: nil), forCellReuseIdentifier: "FileCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard (TDFileManager.sharedInstance.files != nil) else {
            performSegue(withIdentifier: "showLogin", sender: self)
            return
        }
        if let files = TDFileManager.sharedInstance.files {
            self.files = files
            
            self.fileTableUIHelper = FileTableUIHelper()
            self.fileTableUIHelper.delegate = self
            
            tableView!.dataSource = self.fileTableUIHelper
            tableView!.delegate = self.fileTableUIHelper
            tableView!.reloadData()
        }
        self.imagePickerHelper = ImagePickerUIHelper()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case .some("showMove"):
            let destinationNavigationController = segue.destination as! UINavigationController
            let targetController = destinationNavigationController.topViewController as! MoveVC
            let fileToMove = sender as! File
            targetController.previousAbsolutePath = self.getCurrentPath()
            targetController.files = self.files.filter{ file in file.type == .directory && file != fileToMove }
            targetController.file = fileToMove
            targetController.delegate = self
        default:
            break
        }
    }
    
    
    @IBAction func addButtonClicked() {
        self.displayActionSheet()
    }
    
    
    
    //QLPreviewControllerDataSource protocol
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.urls.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.urls[index]
    }
    
    
}


