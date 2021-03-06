import UIKit
import Photos

class ImagePickerUIHelper: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var delegate: DirectoryUI!
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let info = info[UIImagePickerControllerReferenceURL], let url = info as? URL {
            let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
            if let photo = fetchResult.firstObject {
                PHImageManager.default().requestImageData(for: photo, options: nil) { (data, _, _,info) in
                    if let data = data,
                        let fileName = (info?["PHImageFileURLKey"] as? URL)?.lastPathComponent {
                        picker.dismiss(animated: true, completion: nil)
                        self.delegate.didChoosePhoto(fileData: data, fileName: fileName)
                    }
                }
            }
        } else if let image: UIImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            picker.dismiss(animated: true, completion: nil)
            self.delegate.didChoosePhoto(fileData: UIImageJPEGRepresentation(image,1)!, fileName: "\(CommonManager.sharedInstance.generateRandomHash(length: 6)).jpeg")
        }
    }
}

