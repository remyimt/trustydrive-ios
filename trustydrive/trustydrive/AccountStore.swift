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

struct Account: Glossy, Equatable {
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
    
    static func ==(lhs: Account, rhs: Account)-> Bool {
        return lhs.token == rhs.token && lhs.provider == rhs.provider
    }
}

class AccountStore: NSObject {
    
    static let singleton = AccountStore()
    
    var accounts = [Account]()
    var dropboxClients = [String:DropboxClient]()
    var accountStoreDelegate: AccountStoreDelgate?
    var loginDelegate: LoginDelegate?
    
    
    func login(password: String) {
        
        //Single account implemntation
        self.loginDelegate?.willStart()
        let account = accounts[0]
        //let metadataName = "metadata"
        //let metadataName = (account.provider.rawValue+account.email+password).sha1
        let client = self.dropboxClients[account.token]
        
        client!.files.listFolder(path: "")
            .response{ response, error in
                if let response = response {
                    if response.entries.count == 0 {
                        self.createMetadata(password: "")
                    } else {
                        self.fetchMetadata()
                    }
                } else if let error = error {
                    print(error)
                }
        }
        
    }
    
    //TODO Distributed implementation
    func createMetadata(password: String) {
        FileStore.data.initFiles()
        //Single account implementation
        let account = accounts[0]
        let metadataName = "/metadata.txt"
        //let metadataName = (account.provider.rawValue+account.email+password).sha1
        let client = self.dropboxClients[account.token]!
        
        
        let data = try! JSONSerialization.data(withJSONObject: Root(files: FileStore.data.files!).toJSON()!, options: [])
        
        // TODO : replace with mine
        client.files.upload(path: metadataName, input: data)
            .response {response, error in
                if (response != nil) {
                    self.loginDelegate?.success(result: true)
                } else if let error = error {
                    print(error)
                }
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
