
import Gloss

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
