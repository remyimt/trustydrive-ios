import Gloss

struct Chunk: Glossy, Equatable {
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

    init(account: Account, name: String) {
        self.account = account
        self.name = name
    }

    func toJSON() -> JSON? {
        return jsonify([
                "account" ~~> self.account,
                "name" ~~> self.name
        ])
    }

    static func ==(lhs: Chunk, rhs: Chunk)->Bool {
        return lhs.account == rhs.account && lhs.name == rhs.name
    }
}
