import Gloss

struct LocalFile: Glossy {
    var absolutePath: String
    let lastPathComponent: String

    init(absolutePath: String, lastPathComponent: String) {
        self.absolutePath = absolutePath
        self.lastPathComponent = lastPathComponent
    }
    
    init?(json: JSON) {
        guard let absolutePath: String = "absolutePath" <~~ json,
            let lastPathComponent: String = "lastPathComponent" <~~ json else {
                return nil
        }
        self.absolutePath = absolutePath
        self.lastPathComponent = lastPathComponent
    }
    
    func toJSON() -> JSON? {
        return jsonify([
                "absolutePath" ~~> self.absolutePath,
                "lastPathComponent" ~~> self.lastPathComponent
            ])
    }
}
