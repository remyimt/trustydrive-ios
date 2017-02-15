//
//  File.swift
//  modal-experiment
//
//  Created by Sebastian on 07/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import Gloss

class FileStore: NSObject, FileManager {
    
    static let data = FileStore()
    
    var files: [File]?
    
    private override init() {
        super.init()
    }
    
    func initFiles() {
        self.files = [File]()
    }
    
    func download(file: File, completionHandler: @escaping (URL) -> Void) {
        let account = AccountStore.singleton.accounts[0]
        let client = AccountStore.singleton.dropboxClients[account.token]
        let numberOfProviders = AccountStore.singleton.accounts.count
        let chunksData = file.chunks!
        
        let queue = DispatchQueue(label: "download.chunks.queue", qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()
        
        // Download the chunks composing the file from the cloud providers (only Dropbox so far)
        var chunks = [[UInt8]](repeating: [UInt8](), count: chunksData.count)
        for chunk in chunksData {
            group.enter()
            client!.files.download(path: "/" + chunk.name).response(queue: queue) { response, error in
                if let (_, data) = response {
                    chunks[chunksData.index(where: { (Chunk) -> Bool in
                        Chunk.name == chunk.name
                    })!] = [UInt8](data)
                }
                else if let error = error {
                    print(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: queue) {
            let blockSize = chunks[0].count
            let downloadDestination = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(file.name.components(separatedBy: ".")[0]).appendingPathExtension(file.name.components(separatedBy: ".")[1])
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
                completionHandler(downloadDestination)
            }
            
        }
        
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
    
    func rename(newName: String, absolutePath: String, newAbsolutePath: String)->Bool {
        var path = absolutePath.components(separatedBy: "/")
        path.removeFirst()
        
        let currentPath = path[0]
        
        let index = self.files?.index { file in
            print("File Name: "+file.name)
            print("Current Path: "+currentPath)
            return file.name == currentPath
        }
        
        if let index = index {
            
            if path.count == 1 && self.files?[index].name == path[0]{
                self.files?[index].name = newName
                self.files?[index].absolutePath = newAbsolutePath
                return true
            } else {
                path.removeFirst()
                //return self.files?[index].rename(newName: newName, pathArray: path)
                return false
            }
        } else {
            return false
        }

    }
}

struct Root: Glossy {
    let files: [File]
    
    init(files: [File]) {
        self.files = files
    }
    
    init?(json: JSON) {
        guard let files: [File] = "files" <~~ json else {
            return nil
        }
        self.files = files
    }
    
    func toJSON() -> JSON? {
        return jsonify(["files" ~~> self.files])
    }
}



struct Chunk: Glossy {
    let account: Account
    let name: String
    
    init?(json: JSON) {
        guard let account: Account = "account" <~~ json,
            let name: String = "name" <~~ json else {
                return nil
        }
        
        self.account = account
        self.name = name
    }
    
    func toJSON() -> JSON? {
        return jsonify([
            "account" ~~> self.account,
            "name" ~~> self.name
            ])
    }
}

protocol FileManager {
    func download(file: File, completionHandler: @escaping (URL) -> Void)
    //func upload()
    //func delete()
}

struct File: Glossy {
    var name: String
    let type: FileType
    var chunks: [Chunk]?
    var absolutePath: String
    var uploadDate: Double
    var size: Int?
    var files: [File]?
    
    enum FileType: String {
        case file = "file"
        case directory = "directory"
        case image = "image"
    }
    
    init(name: String, type: FileType, chunks: [Chunk]?, absolutePath: String, uploadDate: Double, size: Int?, files: [File]?) {
        self.name = name
        self.type = type
        self.chunks = chunks
        self.absolutePath = absolutePath
        self.uploadDate = uploadDate
        self.size = size
        self.files = files
    }
    
    init?(json: JSON) {
        guard let name: String = "name" <~~ json,
            let type: String = "type" <~~ json,
            let absolutePath: String = "absolutePath" <~~ json,
            let uploadDate: Double = "uploadDate" <~~ json else {
                return nil
        }
        
        self.name = name
        self.type = File.FileType(rawValue: type)!
        self.absolutePath = absolutePath
        self.uploadDate = uploadDate
        
        if let size: Int = "size" <~~ json, let chunks: [Chunk] = "chunks" <~~ json {
            self.chunks = chunks
            self.size = size
        } else if let files: [File] = "files" <~~ json {
            self.files = files
        }
        
    }
    
    func toJSON() -> JSON? {
        return jsonify([
            "name" ~~> self.name,
            "type" ~~> self.type,
            "chunks" ~~> self.chunks,
            "absolutePath" ~~> self.absolutePath,
            "uploadDate" ~~> self.uploadDate,
            "size" ~~> self.size,
            "files" ~~> self.files,
            ])
    }
    
    mutating func removeFile(absolutePath: [String])-> File? {
        
        var path = absolutePath
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
    
    mutating func mkdir(name: String, pathArray: [String], absolutePath: String)-> File? {
        var pathArray = pathArray
        let currentPath = pathArray[0]
        
        if pathArray.count == 1 {
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
                pathArray.removeFirst()
                return self.files?[index].mkdir(name: name, pathArray: pathArray, absolutePath: absolutePath)
            } else {
                return nil
            }
        }

    }
    
    mutating func rename(newName: String, pathArray: [String])-> Bool {
        var path = pathArray
        let currentPath = path[0]
        
        let index = self.files?.index { file in
            print("File Name: "+file.name)
            print("Current Path: "+currentPath)
            return file.name == currentPath
        }
        
        if let index = index {
            
            if path.count == 1 && self.files?[index].name == path[0]{
                self.files?[index].name = newName
                self.files?[index].renameInAbsolutePath(oldName: path[0], newName: newName)
                return true
            } else {
                path.removeFirst()
                //return self.files?[index].rename(newName: newName, pathArray: path)
                return false
            }
        } else {
            return false
        }

    }
    
    mutating func renameInAbsolutePath(oldName: String, newName: String) {
        //self.absolutePath.replace
    }
    
}
