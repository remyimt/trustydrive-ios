//
//  TokenStore.swift
//  modal-experiment
//
//  Created by Sebastian on 08/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import Gloss
import SwiftyDropbox
import CryptoSwift

protocol AccountStoreDelgate {
    func willFetch()
    func didChange(accounts: [Account])
}

protocol LoginDelegate {
    func willStart()
    func success(result: Bool)
}

class AccountManager: NSObject {
    
    static let sharedInstance = AccountManager()
    
    var accounts = [Account]()
    var dropboxClients = [String:DropboxClient]()
    var accountStoreDelegate: AccountStoreDelgate?
    var loginDelegate: LoginDelegate?
    
    
    func login(password: String) {
        self.loginDelegate?.willStart()
        
        let queue = DispatchQueue(label: "download.chunks.queue", qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()
        
        var trustyDriveAccountIsBrandNew = true
        for account in accounts {
            group.enter()
            dropboxClients[account.provider.rawValue+account.email]?.files.listFolder(path: "")
                .response { response, error in
                    if let response = response {
                        if response.entries.count > 0 {
                            trustyDriveAccountIsBrandNew = false
                        }
                    }
                    else if let error = error {
                        print(error)
                    }
                    group.leave()
            }
        }
        
        group.notify(queue: queue) {
            for i in 0...self.accounts.count - 1 {
                self.accounts[i].metadataName = (self.accounts[i].provider.rawValue+self.accounts[i].email+password).sha1()
            }
            
            if trustyDriveAccountIsBrandNew {
                self.createMetadata()
            }
            else {
                self.fetchMetadata()
            }
        }
    }
    
    func createMetadata() {
        TDFileManager.sharedInstance.initFiles()
        self.uploadMetadata() {
            self.loginDelegate?.success(result: true)
        }
    }
    
    func uploadMetadata(completionHandler: @escaping ()->Void) {
        
        let queue = DispatchQueue(label: "download.chunks.queue", qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()
        
        let data = try! JSONSerialization.data(withJSONObject: Root(files: TDFileManager.sharedInstance.files!).toJSON()!, options: [])
        let metadataArray = [UInt8](data)
        
        // Initialize one buffer per provider
        var buffers = [[UInt8]]()
        for _ in accounts {
            buffers.append([UInt8]())
        }
        
        // Distribute the bytes within the buffers
        for i in 0...metadataArray.count - 1 {
            buffers[i % accounts.count].append(metadataArray[i])
        }
        
        // Turn the buffers into files and upload them to the Dropbox accounts
        for buffer in buffers {
            group.enter()
            let bufferIndex = buffers.index(where: { (Buffer) -> Bool in
                Buffer == buffer
            })!
            let chunk = Data(bytes: buffer)
            let dropboxKey = self.accounts[bufferIndex].provider.rawValue + self.accounts[bufferIndex].email
            dropboxClients[dropboxKey]?.files.upload(path: "/" + self.accounts[bufferIndex].metadataName!, mode: .overwrite, clientModified: Date(timeIntervalSinceNow: -Double(arc4random_uniform(UInt32(3.154e+7)))), input: chunk)
                .response { response, error in
                    if let response = response {
                        print(response)
                    } else if let error = error {
                        print(error)
                    }
            }
            
            group.leave()
        }
        
        group.notify(queue: queue) {
            
            DispatchQueue.main.async {
                completionHandler()
            }
        }
        
    }
    
    func fetchMetadata() {
        
        let queue = DispatchQueue(label: "download.chunks.queue", qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()
        
        // Download the chunks composing the metadata (one chunk per provider)
        var chunks = [[UInt8]](repeating: [UInt8](), count: self.accounts.count)
        for account in self.accounts {
            group.enter()
            let accountIndex = self.accounts.index(where: { (Account) -> Bool in
                Account.token == account.token
            })!
            let dropboxKey = account.provider.rawValue + account.email
            dropboxClients[dropboxKey]?.files.download(path: "/" + account.metadataName!)
                .response(queue: queue) { response, error in
                    if let (_, data) = response {
                        chunks[accountIndex] = [UInt8](data)
                    }
                    else if let error = error {
                        print(error)
                    }
                    group.leave()
            }
            
        }
        
        group.notify(queue: queue) {
            // Compute the total size of the metadata file
            var metadataSize = 0
            for chunk in chunks {
                metadataSize += chunk.count
            }
            
            // Rebuild the metadata off the chunks
            var metadata = [UInt8](repeating: 0, count: metadataSize)
            for i in 0...metadataSize - 1 {
                metadata[i] = chunks[i % self.accounts.count][(i - (i % self.accounts.count))/self.accounts.count]
            }
            
            guard let root: Root = Root(data: Data(metadata)) else {
                print("Unable to parse metadata")
                return
            }
            TDFileManager.sharedInstance.files = root.files
            
            // Check for local files on the device and assign their path to the corresponding File object
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filesOnDevice: [String] = try! FileManager.default.contentsOfDirectory(atPath: documentsDirectory)
            for fileName in filesOnDevice {
                let fileIndex = TDFileManager.sharedInstance.files?.index(where: { (File) -> Bool in
                    File.name == fileName
                })
                if let fileIndex = fileIndex {
                    TDFileManager.sharedInstance.files![fileIndex].localURL = URL(string: documentsDirectory.appending("/" + fileName))
                }
            }
            
            self.loginDelegate?.success(result: true)
        }
        
    }
    
    func saveDropboxToken(token: DropboxAccessToken) {
        
        let client = DropboxClient(accessToken: token.accessToken)
        self.accountStoreDelegate?.willFetch()
        
        client.users.getCurrentAccount()
            .response { user, error in
                guard let user = user else {
                    print("ERROR: Unable to obtain user email address")
                    print(error!)
                    return
                }
                
                let token = Account(token: token.accessToken, provider: .dropbox, email: user.email)
                self.accounts.append(token)
                
                let accountsData = try! JSONSerialization.data(withJSONObject: AccountManager.sharedInstance.accounts.toJSONArray()!, options: [])
                
                self.dropboxClients[Provider.dropbox.rawValue+user.email] = client
                
                UserDefaults.standard.set(accountsData, forKey: "accounts")
                UserDefaults.standard.synchronize()
                
                if let delegate = self.accountStoreDelegate {
                    delegate.didChange(accounts: self.accounts)
                }
        }
    
    }
    
}
