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

typealias JSON = Gloss.JSON

protocol AccountStoreDelgate {
    func willFetch()
    func didChange(accounts: [Account])
}

protocol LoginDelegate {
    func willStart()
    func success(result: Bool)
}

enum Provider: String {
    case dropbox = "Dropbox"
    case onedrive = "OneDrive"
    case drive = "Google Drive"
}

struct Account: Glossy {
    let token: String
    let provider: Provider
    let email: String
    var metadataName: String?
    
    init(token: String, provider: Provider, email: String) {
        self.token = token
        self.provider = provider
        self.email = email
    }
    
    init?(json: JSON) {
        
        guard let token: String = "token" <~~ json,
            let provider: String = "provider" <~~ json,
            let email: String = "email" <~~ json else {
                return nil
        }
        
        self.token = token
        self.provider = Provider(rawValue: provider)!
        self.email = email
    }
    
    func toJSON() -> JSON? {
        return jsonify([
            "email" ~~> self.email,
            "provider" ~~> self.provider,
            "token" ~~> self.token
            ])
    }
}

class AccountStore: NSObject {
    
    static let singleton = AccountStore()
    
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
            dropboxClients[account.token]?.files.listFolder(path: "")
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
            if trustyDriveAccountIsBrandNew {
                self.createMetadata(password: password)
            }
            else {
                self.fetchMetadata()
            }
        }
    }
    
    func createMetadata(password: String) {
        FileStore.data.initFiles()
        
        let queue = DispatchQueue(label: "download.chunks.queue", qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()
        
        let data = try! JSONSerialization.data(withJSONObject: Root(files: FileStore.data.files!).toJSON()!, options: [])
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
            let metadataName = (accounts[bufferIndex].provider.rawValue+accounts[bufferIndex].email+password).sha1()
            dropboxClients[accounts[bufferIndex].token]?.files.upload(path: "/" + metadataName, clientModified: Date(timeIntervalSinceNow: -Double(arc4random_uniform(UInt32(3.154e+7)))), input: chunk)
            group.leave()
        }
        
        group.notify(queue: queue) {
            self.loginDelegate?.success(result: true)
        }
        
    }
    
    func fetchMetadata() {
        
        //Single account implmentation
        let account = accounts[0]
        let metadataName = "/metadata.txt"
        //let metadataName = (account.provider.rawValue+account.email+password).sha1
        let client = self.dropboxClients[account.token]!
        
        // Replace with mine
        client.files.download(path: metadataName)
            .response { response, error in
                if let response = response {
                    
                    guard let root: Root = Root(data: response.1) else {
                        print("Unable to parse metadata")
                        return
                    }
                    
                    FileStore.data.files = root.files
                    
                    self.loginDelegate?.success(result: true)
                } else if let error = error {
                    print(error)
                }
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
                
                let accountsData = try! JSONSerialization.data(withJSONObject: AccountStore.singleton.accounts.toJSONArray()!, options: [])
                
                UserDefaults.standard.set(accountsData, forKey: "accounts")
                UserDefaults.standard.synchronize()
                
                if let delegate = self.accountStoreDelegate {
                    delegate.didChange(accounts: self.accounts)
                }
        }
        
        self.dropboxClients[token.accessToken] = client
    }
    
}
