
import Gloss

struct LocalFile: Glossy {
    let absolutePath: String
    let url: URL

    init(absolutePath: String, url: URL) {
        self.absolutePath = absolutePath
        self.url = url
    }
    
    init?(json: JSON) {
        guard let absolutePath: String = "absolutePath" <~~ json,
            let url: String = "url" <~~ json else {
                return nil
        }
        self.absolutePath = absolutePath
        self.url = URL(string: url)!
    }
    
    func toJSON() -> JSON? {
        return jsonify([
                "absolutePath" ~~> self.absolutePath,
                "url" ~~> self.url.absoluteString
            ])
    }
}
