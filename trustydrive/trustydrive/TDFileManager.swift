import Gloss

class TDFileManager: NSObject {
    
    static let sharedInstance = TDFileManager()
    
    var files: [File]?
    
    private override init() {
        super.init()
    }
    
    func initFiles() {
        self.files = [File]()
    }
    
    func getFile(at absolutePath: String)->File? {
        var path = absolutePath.components(separatedBy: "/")
        path.removeFirst()
        
        let currentPath = path[0]
        
        let index = self.files?.index { file in file.name == currentPath}
        
        if let index = index {
            if path.count == 1 {
                return self.files?[index]
            }
            path.removeFirst()
            return self.files?[index].getFile(at: path)
            
        }
        
        return nil
        
    }
    
    func remove(absolutePath: String)-> File? {
        var path = absolutePath.components(separatedBy: "/")
        path.removeFirst()
        
        let currentPath = path[0]
        
        //Get the matching current directory
        let index = self.files?.index { file in file.name == currentPath }
        
        if let index = index {
            if path.count == 1 {
                return self.files?.remove(at: index)
            } else {
                path.removeFirst()
                return self.files?[index].removeFile(absolutePath: path)
            }
        } else {
            return nil
        }
    }
    
    func mkdir(name: String, absolutePath: String)->File? {
        var path = absolutePath.components(separatedBy: "/")
        path.removeFirst()
        
        let currentPath = path[0]
        
        if path.count == 1 {
            let file = File(name: name, type: .directory, chunks: nil, absolutePath: absolutePath, uploadDate: Date().timeIntervalSince1970*1000, size: nil, files: [])
            self.files?.append(file)
            return file
        } else {
            let index = self.files?.index { file in file.name == currentPath }
            
            if let index = index {
                path.removeFirst()
                return self.files?[index].mkdir(name: name, pathArray: path, absolutePath: absolutePath)
            } else {
                return nil
            }
        }
        
    }
    
    func rename(newName: String, absolutePath: String)->Array<File>.Index? {
        var path = absolutePath.components(separatedBy: "/")
        path.removeFirst()
        
        let currentPath = path[0]
        
        let index = self.files?.index { file in file.name == currentPath}
        
        if let index = index {
            
            if path.count == 1 && self.files?[index].name == path[0]{
                self.files?[index].name = newName
                return index
            } else {
                path.removeFirst()
                return self.files![index].rename(newName: newName, pathArray: path)
            }
        } else {
            return nil
        }
        
    }
    
    func addFile(file: File, absolutePath: String)->Bool {
        var path = absolutePath.components(separatedBy: "/")
        
        if path.count == 1 {
            self.files!.append(file)
            return true
        }
        
        path.removeFirst()
        
        let index = self.files?.index { file in
            return file.name == path[0]
        }
        
        if let index = index {
            return self.files![index].addFile(file: file, pathArray: path)
        } else {
            return false
        }
        
    }
    
    func move(file: File, previousPath: String, newPath: String)->Bool {
        self.updateLocalFileNames(file: file, previousPath: previousPath, newPath: newPath)
        return (self.remove(absolutePath: previousPath) != nil) && self.addFile(file: file, absolutePath: newPath)
    }
    
    func updateLocalFileNames(file: File, previousPath: String, newPath: String) {
        
        if(file.localName != nil) {
            LocalFileManager.sharedInstance.update(previousPath: "\(previousPath)", newPath: "\(newPath)/\(file.name)")
        }
        
        file.files?.forEach { currentFile in
            self.updateLocalFileNames(file: currentFile, previousPath: "\(previousPath)/\(currentFile.name)", newPath: "\(newPath)/\(file.name)")
        }
        
    }
    
    func setLocalName(localName: String?, absolutePath: String)-> Array<File>.Index? {
        var path = absolutePath.components(separatedBy: "/")
        path.removeFirst()
        
        let currentPath = path[0]
        
        let index = self.files?.index { file in file.name == currentPath}
        
        if let index = index {
            
            if path.count == 1 && self.files?[index].name == path[0] {
                self.files?[index].localName = localName
                return index
            } else {
                path.removeFirst()
                return self.files![index].setLocalName(localName: localName, pathArray: path)
            }
        } else {
            return nil
        }
        
        
    }
}
