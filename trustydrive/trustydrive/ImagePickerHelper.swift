//
//  ImagePickerHelper.swift
//  trustydrive
//
//  Created by Sebastian on 14/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit
import Photos

class ImagePickerHelper: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let info = info[UIImagePickerControllerReferenceURL], let url = info as? URL {
            let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
            if let photo = fetchResult.firstObject {
                PHImageManager.default().requestImageData(for: photo, options: nil) { (data, _, _, _) in
                    if let data = data {
                        print(data.count)
                        picker.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
}
