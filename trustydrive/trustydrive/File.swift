import Gloss

struct File: Glossy, Equatable {
    var name: String
    let type: FileType
    var chunks: [Chunk]?
    var uploadDate: Double
    var localName: String?
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
        self.uploadDate = uploadDate
        self.size = size
        self.files = files
    }

    init?(json: JSON) {
        guard let name: String = "name" <~~ json,
              let type: String = "type" <~~ json,
              let uploadDate: Double = "uploadDate" <~~ json else {
            return nil
        }

        self.name = name
        self.type = File.FileType(rawValue: type)!
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
                "uploadDate" ~~> self.uploadDate,
                "size" ~~> self.size,
                "files" ~~> self.files,
        ])
    }

    static func ==(lhs:File, rhs:File) ->Bool {


        if lhs.type == .file && rhs.type == .file {
            if let lhschunks = lhs.chunks,
               let rhschunks = rhs.chunks,
               let lhssize = lhs.size,
               let rhssize = rhs.size{
                return lhs.name == rhs.name && lhs.type == rhs.type  &&
                        lhs.uploadDate == rhs.uploadDate && lhssize == rhssize && lhschunks == rhschunks
            }
        } else if lhs.type == .directory && rhs.type == .directory {
            if let lhsfiles = lhs.files,
               let rhsfiles = rhs.files {
                return lhsfiles == rhsfiles
            }
        }

        return false

    }
    
    func getFile(at absolutePath: [String])->File? {
        
        var path = absolutePath
        let currentPath = path[0]
        
        let index = self.files?.index { file in file.name == currentPath }
        
        if let index = index {
            if path.count == 1 {
                return self.files?[index]
            }
            path.removeFirst()
            return self.files?[index].getFile(at: path)
            
        }
        
        return nil
        
    }

    mutating func removeFile(absolutePath: [String])-> File? {

        var path = absolutePath
        let currentPath = path[0]

        //Get the matching current directory
        let index = self.files?.index { file in file.name == currentPath }

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
            let index = self.files?.index { file in file.name == currentPath }

            if let index = index {
                pathArray.removeFirst()
                return self.files?[index].mkdir(name: name, pathArray: pathArray, absolutePath: absolutePath)
            } else {
                return nil
            }
        }

    }

    mutating func rename(newName: String, pathArray: [String])-> Array<File>.Index? {
        var path = pathArray
        let currentPath = path[0]

        let index = self.files?.index { file in file.name == currentPath }

        if let index = index {

            if path.count == 1 && self.files?[index].name == path[0]{
                self.files?[index].name = newName
                return index
            } else {
                path.removeFirst()
                return self.files![index].rename(newName: newName, pathArray: path)
            }
        } else {
            return nil
        }

    }

    mutating func setLocalName(localName: String?, pathArray: [String])-> Array<File>.Index? {
        var path = pathArray
        let currentPath = path[0]

        let index = self.files?.index { file in file.name == currentPath }

        if let index = index {

            if path.count == 1 && self.files?[index].name == path[0] {
                self.files?[index].localName = localName
                return index
            } else {
                path.removeFirst()
                return self.files![index].setLocalName(localName: localName, pathArray: path)
            }
        } else {
            return nil
        }

    }

    mutating func addFile(file: File, pathArray: [String])-> Bool {
        var path = pathArray


        if path.count == 1 {
            self.files!.append(file)
            return true
        }

        path.removeFirst()

        let index = self.files?.index { file in file.name == path[0] }

        if let index = index {
            return self.files![index].addFile(file: file, pathArray: path)
        } else {
            return false
        }

    }

}
