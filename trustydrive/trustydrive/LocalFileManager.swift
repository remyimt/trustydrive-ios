
import Foundation

class LocalFileManager: NSObject {
    
    static let sharedInstance = LocalFileManager()
    
    var localFiles = [LocalFile]()
    
}
