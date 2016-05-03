//
//  PhotoKitAsset.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/11.
//  Copyright © 2016年 nohana. All rights reserved.
//

import Photos

public class PhotoKitAsset :AssetType {
    
    let asset: PHAsset
    
    public init(asset: PHAsset) {
        self.asset = asset
    }
    
    public var originalAsset: PHAsset {
        get {
            return asset as PHAsset
        }
    }
    
    // MARK: - AssetType
    
    public var identifier:Int {
        get {
            return asset.localIdentifier.hash
        }
    }
    
    public func image(targetSize:CGSize, handler: (ImageData?) -> Void) {
        let option = PHImageRequestOptions()
        option.networkAccessAllowed = true
        
        PHImageManager.defaultManager().requestImageForAsset(
            self.asset,
            targetSize: targetSize,
            contentMode: .AspectFit,
            options: option ) { (image, info) -> Void in
                guard let image = image else {
                    handler(nil)
                    return
                }
                handler(ImageData(image: image, info: info))
        }
    }
}
