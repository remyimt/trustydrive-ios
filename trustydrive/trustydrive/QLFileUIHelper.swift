//
//  QLPickerDataSource.swift
//  trustydrive
//
//  Created by Sebastian on 14/02/2017.
//  Copyright © 2017 SS Developing. All rights reserved.
//

import UIKit
import QuickLook

class QLFileUIHelper: QLPreviewControllerDataSource {
    
    var urls: [NSURL]?
    
    //QLPreviewControllerDataSource protocol
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.urls!.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.urls![index]
    }
    
}
