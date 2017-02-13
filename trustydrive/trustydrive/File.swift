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
    
    func download(file: File, completionHandler: @escaping (String) -> Void) {
        let account = AccountStore.singleton.accounts[0]
        let client = AccountStore.singleton.dropboxClients[account.token]
        
        client?.files.getTemporaryLink(path: file.absolutePath)
            .response { response, error in
                if let response = response {
                    print(response.link)
                    completionHandler(response.link) // The link to the file in disk, as NSURL
                } else if let error = error {
                    print(error)
                }
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
    func download(file: File, completionHandler: @escaping (String) -> Void)
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
}
