import Gloss

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

enum Provider: String {
    case dropbox = "Dropbox"
    case onedrive = "OneDrive"
    case drive = "Google Drive"
}
