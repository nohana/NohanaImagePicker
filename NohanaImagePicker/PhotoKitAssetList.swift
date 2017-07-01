/*
 * Copyright (C) 2016 nohana, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Photos

open class PhotoKitAssetList: ItemList {

    fileprivate let mediaType: MediaType
    open let assetList: PHAssetCollection
    fileprivate var fetchResult: PHFetchResult<PHAsset>!

    init(album: PHAssetCollection, mediaType: MediaType) {
        self.assetList = album
        self.mediaType = mediaType
        update()
    }

    // MARK: - ItemList

    public typealias Item = PhotoKitAsset

    open var title: String {
        return assetList.localizedTitle ?? ""
    }

    open var date: Date? {
        return assetList.startDate
    }

    class func fetchOptions(_ mediaType: MediaType) -> PHFetchOptions {
        let options = PHFetchOptions()
        switch mediaType {
        case .photo:
            options.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        default:
            fatalError("not supported .Video and .Any yet")
        }
        return options
    }

    open func update(_ handler: (() -> Void)? = nil) {
        fetchResult = PHAsset.fetchAssets(in: assetList, options: PhotoKitAssetList.fetchOptions(mediaType))
        if let handler = handler {
            handler()
        }
    }

    open subscript (index: Int) -> Item {
        return Item(asset: fetchResult.object(at: index))
    }

    // MARK: - CollectionType

    open var startIndex: Int {
        return 0
    }

    open var endIndex: Int {
        return fetchResult.count
    }
}
