import Foundation

class CommonManager: NSObject {
    
    static let sharedInstance = CommonManager()
    
    private override init() {
        super.init()
    }
    
    func generateRandomHash(length:Int) -> String {
        var randomHash:String = ""
        for _ in 0...length-1 {
            randomHash += String(format: "%x", arc4random_uniform(16))
        }
        return randomHash
    }
    
}
