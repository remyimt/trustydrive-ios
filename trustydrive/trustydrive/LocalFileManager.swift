import Foundation

class LocalFileManager: NSObject {
    
    static let sharedInstance = LocalFileManager()
    
    var localFiles = [LocalFile]()
    
    func update(previousPath: String, newPath: String) {
        
        let index = localFiles.index { localFile in localFile.absolutePath == previousPath }
        if let index = index {
            localFiles[index].absolutePath = newPath
        }
        
        self.saveToUserDefaults()
    }
    
    func remove(absolutePath: String) {
        let index = localFiles.index { localFile in localFile.absolutePath == absolutePath }
        if let index = index {
            let localFile = localFiles.remove(at: index)
            self.deleteFromDevice(lastPathComponent: localFile.lastPathComponent)
            self.saveToUserDefaults()
        }
        
    }
    
    func runtimeDocumentsURL(for lastPathComponent: String)->URL {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let localNameComponents = lastPathComponent.components(separatedBy: ".")
        return URL(fileURLWithPath: documentsDirectory, isDirectory: true).appendingPathComponent(localNameComponents[0]).appendingPathExtension(localNameComponents[1])
    }
    
    func saveToUserDefaults() {
        DispatchQueue.global(qos: .background).async {
            let data = try! JSONSerialization.data(withJSONObject: self.localFiles.toJSONArray()!, options: [])
            UserDefaults.standard.set(data, forKey: "localFiles")
        }
    }
    
    func deleteFromDevice(lastPathComponent: String) {
        try? FileManager.default.removeItem(at: runtimeDocumentsURL(for: lastPathComponent))
    }
    
}
