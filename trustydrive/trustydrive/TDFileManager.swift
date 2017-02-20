
import Gloss

struct NetworkError {
    let message: String
}

class TDFileManager: NSObject, TrustyDriveFileManager {
    
    static let sharedInstance = TDFileManager()
    
    var files: [File]?
    
    private override init() {
        super.init()
    }
    
    func initFiles() {
        self.files = [File]()
    }
    
    func download(file: File, directory: String, completionHandler: @escaping (URL?, NetworkError?) -> Void) {
        let numberOfProviders = AccountManager.sharedInstance.accounts.count
        let chunksData = file.chunks!
        
        let queue = DispatchQueue(label: "download.chunks.queue", qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()
        
        // Download the chunks composing the file from the cloud providers (only Dropbox so far)
        var chunks = [[UInt8]](repeating: [UInt8](), count: chunksData.count)
        var noError = true
        for chunk in chunksData {
            group.enter()
            let dropboxKey = chunk.account.provider.rawValue + chunk.account.email
            let client = AccountManager.sharedInstance.dropboxClients[dropboxKey]!
            client.files.download(path: "/" + chunk.name).response(queue: queue) { response, error in
                if let (_, data) = response {
                    chunks[chunksData.index(where: { (Chunk) -> Bool in
                        Chunk.name == chunk.name
                    })!] = [UInt8](data)
                }
                else if let error = error {
                    print(error)
                    noError = false
                }
                group.leave()
            }
        }
        
        group.notify(queue: queue) {
            
            guard noError else {
                completionHandler(nil, NetworkError(message: "Unable to download all of the chunks"))
                return
            }
            
            let blockSize = chunks[0].count
            let downloadDestination = URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent(file.name.components(separatedBy: ".")[0]).appendingPathExtension(file.name.components(separatedBy: ".")[1])
            let fileToDownload = OutputStream(url: downloadDestination, append: false)
            fileToDownload?.open()
            
            // Distribute the bytes, to generate the file out of the chunks
            var tempB = [UInt8](repeating: 0, count: 1) // Initialize the temporary buffer
            for i in stride(from: 0, to: chunks.count - numberOfProviders, by: numberOfProviders) {
                for j in 0...(blockSize*numberOfProviders - 1) {
                    tempB[0] = chunks[i + j % numberOfProviders][(j - (j % numberOfProviders))/numberOfProviders]
                    fileToDownload?.write(&tempB, maxLength: 1)
                }
            }
            let remainingBytes = file.size! - blockSize*(chunks.count-numberOfProviders)
            for j in 0...remainingBytes - 1 { // Distribute the bytes contained in the incomplete chunks
                tempB[0] = chunks[chunks.count-numberOfProviders + j % numberOfProviders][(j - (j % numberOfProviders))/numberOfProviders]
                fileToDownload?.write(&tempB, maxLength: 1)
            }
            
            fileToDownload?.close()
            
            DispatchQueue.main.async {
                completionHandler(downloadDestination, nil)
            }
            
        }
        
    }
    
    func upload(fileData: Data, fileName: String, completionHandler: @escaping (File)->Void) {
        let blockSize = 500000 // 500kb blocks to chop the files
        let numberOfProviders = AccountManager.sharedInstance.accounts.count
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileToUpload = InputStream(data: fileData)
            fileToUpload.open()
            
            // Initialize one buffer per provider
            var buffers = [[UInt8]]()
            for _ in 0...numberOfProviders - 1 {
                buffers.append([UInt8](repeating: 0, count: blockSize))
            }
            
            var uploadedFile: File = File(name: fileName, type: .file, chunks: [], absolutePath: "", uploadDate: Date().timeIntervalSince1970, size: fileData.count, files: nil)
            
            // Fill up the buffers reading the file byte per byte and sending them to Dropbox when the size reaches blockSize. Incomplete buffers will be filled with 0 to reach blockSize
            var tempB = [UInt8](repeating: 0, count: 1)
            while fileToUpload.hasBytesAvailable {
                for i in 0...(blockSize*numberOfProviders - 1) { // Fill up the numberOfProviders buffers
                    fileToUpload.read(&tempB, maxLength: 1)
                    buffers[i%numberOfProviders][(i - (i % numberOfProviders))/numberOfProviders] = tempB[0]
                }
                for i in 0...numberOfProviders - 1 { // Turn the buffers into blocks and upload them now that they have reached the blockSize
                    let bufferData = Data(bytes: buffers[i%numberOfProviders])
                    let chunkName = self.generateRandomHash(length: 40)
                    let dropboxClientKey = AccountManager.sharedInstance.accounts[i%numberOfProviders].provider.rawValue +
                        AccountManager.sharedInstance.accounts[i%numberOfProviders].email
                    let client = AccountManager.sharedInstance.dropboxClients[dropboxClientKey]!
                    let randomDate = Date(timeIntervalSinceNow: -Double(arc4random_uniform(UInt32(3.154e+7))))
                    client.files.upload(path: "/" + chunkName, clientModified: randomDate, input: bufferData)
                    uploadedFile.chunks?.append(Chunk(account: AccountManager.sharedInstance.accounts[i%numberOfProviders], name: chunkName))
                }
            }
            
            fileToUpload.close()
            
            DispatchQueue.main.async {
                completionHandler(uploadedFile)
            }
        }
        
    }
    
    func delete(file: File, completionHandler: @escaping (Bool)->Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let innerFiles = file.files {
                for file in innerFiles {
                    self.delete(file: file) { _ in
                        completionHandler(true)
                    }
                }
            }
            else {
                for chunk in file.chunks! {
                    let client = AccountManager.sharedInstance.dropboxClients[chunk.account.provider.rawValue+chunk.account.email]
                    client?.files.delete(path: "/" + chunk.name)
                }
            }
            
            DispatchQueue.main.async {
                if let localUrl = file.localURL {
                    self.deleteFromDevice(url: localUrl)
                }
                completionHandler(true)
            }
            
        }
        
    }
    
    func deleteFromDevice(url: URL) {
        try! FileManager.default.removeItem(at: url)
    }
    
    func generateRandomHash(length:Int) -> String {
        var randomHash:String = ""
        for _ in 0...length-1 {
            randomHash += String(format: "%x", arc4random_uniform(16))
        }
        return randomHash
    }
    
    func remove(absolutePath: String)-> File? {
        var path = absolutePath.components(separatedBy: "/")
        path.removeFirst()
        
        let currentPath = path[0]
        
        //Get the matching current directory
        let index = self.files?.index { file in
            print("File Name: "+file.name)
            print("Current Path: "+currentPath)
            return file.name == currentPath
        }
        
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
            let index = self.files?.index { file in
                print("File Name: "+file.name)
                print("Current Path: "+currentPath)
                return file.name == currentPath
            }
            
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
        return (self.remove(absolutePath: previousPath) != nil) && self.addFile(file: file, absolutePath: newPath)
    }
    
    func setLocalURL(url: URL, absolutePath: String)-> Bool {
        var path = absolutePath.components(separatedBy: "/")
        path.removeFirst()
        
        let currentPath = path[0]
        
        let index = self.files?.index { file in file.name == currentPath}
        
        if let index = index {
            
            if path.count == 1 && self.files?[index].name == path[0] {
                self.files?[index].localURL = url
                return true
            } else {
                path.removeFirst()
                return self.files![index].setLocalUrl(url: url, pathArray: path)
            }
        } else {
            return false
        }

        
    }
}

protocol TrustyDriveFileManager {
    func download(file: File, directory: String, completionHandler: @escaping (URL?, NetworkError?) -> Void)
    func upload(fileData: Data, fileName: String, completionHandler: @escaping (File)->Void)
    func delete(file: File, completionHandler: @escaping (Bool)->Void)
}
