//
//  PhotoKitAssetList.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/11.
//  Copyright © 2016年 nohana. All rights reserved.
//
import Photos

@available(iOS 8.0, *)
public class PhotoKitAssetList :ItemListType {
    
    private let mediaType: MediaType
    public let assetList: PHAssetCollection
    private var fetchResult: PHFetchResult!
    
    init(album: PHAssetCollection, mediaType: MediaType) {
        self.assetList = album
        self.mediaType = mediaType
        update()
    }
    
    // MARK: - ItemListType
    
    public typealias Item = PhotoKitAsset
    
    public var title: String {
        get{
            return assetList.localizedTitle ?? ""
        }
    }
    
    public var date: NSDate? {
        get {
            return assetList.startDate
        }
    }
    
    class func fetchOptions(mediaType: MediaType) -> PHFetchOptions {
        let options = PHFetchOptions()
        switch mediaType {
        case .Photo:
            options.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.Image.rawValue)
        default:
            fatalError("not supported .Video and .Any yet")
        }
        return options
    }
    
    public func update(handler: (() -> Void)? = nil) {
        fetchResult = PHAsset.fetchAssetsInAssetCollection(assetList, options: PhotoKitAssetList.fetchOptions(mediaType))
        if let handler = handler {
            handler()
        }
    }
    
    public subscript (index: Int) -> Item {
        get {
            guard let asset = fetchResult[index] as? PHAsset else {
                fatalError("invalid index")
            }
            return Item(asset: asset)
        }
    }
    
    // MARK: - CollectionType
    
    public var startIndex: Int {
        get {
            return 0
        }
    }
    
    public var endIndex: Int {
        get {
            return fetchResult.count
        }
    }
}
