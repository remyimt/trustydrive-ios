import Foundation

class TDProviderAPIManager: NSObject {
    
    static let sharedInstance = TDProviderAPIManager()
    
    private override init() {
        super.init()
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
    
    func upload(fileData: Data, fileName: String, completionHandler: @escaping (File?, NetworkError?)->Void) {
        let blockSize = 500000 // 500kb blocks to chop the files
        let numberOfProviders = AccountManager.sharedInstance.accounts.count
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileToUpload = InputStream(data: fileData)
            fileToUpload.open()
            
            let queue = DispatchQueue(label: "upload.chunks.queue", qos: .userInitiated, attributes: .concurrent)
            let group = DispatchGroup()
            
            // Initialize one buffer per provider
            var buffers = [[UInt8]]()
            for _ in 0...numberOfProviders - 1 {
                buffers.append([UInt8](repeating: 0, count: blockSize))
            }
            
            var uploadedFile: File = File(name: fileName, type: .file, chunks: [], absolutePath: "", uploadDate: Date().timeIntervalSince1970, size: fileData.count, files: nil)
            
            // Fill up the buffers reading the file byte per byte and sending them to Dropbox when the size reaches blockSize. Incomplete buffers will be filled with 0 to reach blockSize
            var tempB = [UInt8](repeating: 0, count: 1)
            var noError = true
            while fileToUpload.hasBytesAvailable {
                for i in 0...(blockSize*numberOfProviders - 1) { // Fill up the numberOfProviders buffers
                    fileToUpload.read(&tempB, maxLength: 1)
                    buffers[i%numberOfProviders][(i - (i % numberOfProviders))/numberOfProviders] = tempB[0]
                }
                
                for i in 0...numberOfProviders - 1 { // Turn the buffers into blocks and upload them now that they have reached the blockSize
                    let bufferData = Data(bytes: buffers[i%numberOfProviders])
                    let chunkName = CommonManager.sharedInstance.generateRandomHash(length: 40)
                    let dropboxClientKey = AccountManager.sharedInstance.accounts[i%numberOfProviders].provider.rawValue +
                        AccountManager.sharedInstance.accounts[i%numberOfProviders].email
                    let client = AccountManager.sharedInstance.dropboxClients[dropboxClientKey]!
                    let randomDate = Date(timeIntervalSinceNow: -Double(arc4random_uniform(UInt32(3.154e+7))))
                    group.enter()
                    client.files.upload(path: "/" + chunkName, clientModified: randomDate, input: bufferData).response {_, error in
                        if let error = error {
                            print(error)
                            noError = false
                        }
                        group.leave()
                    }
                    uploadedFile.chunks?.append(Chunk(account: AccountManager.sharedInstance.accounts[i%numberOfProviders], name: chunkName))
                }
            }
            
            fileToUpload.close()
            
            group.notify(queue: queue) {
                
                guard noError else {
                    completionHandler(nil, NetworkError(message: "Unable to upload all of the chunks"))
                    return
                }
                
                DispatchQueue.main.async {
                    completionHandler(uploadedFile, nil)
                }
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
                completionHandler(true)
            }
            
        }
        
    }

}

struct NetworkError {
    let message: String
}
