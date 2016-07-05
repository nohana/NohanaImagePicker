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

public class PhotoKitAlbumList: ItemListType {
    
    private var albumList:[Item] = []
    private let assetCollectionTypes: [PHAssetCollectionType]
    private let assetCollectionSubtypes: [PHAssetCollectionSubtype]
    private let mediaType: MediaType
    private var shouldShowEmptyAlbum: Bool
    
    // MARK: - init

    init(assetCollectionTypes: [PHAssetCollectionType], assetCollectionSubtypes: [PHAssetCollectionSubtype], mediaType: MediaType, shouldShowEmptyAlbum: Bool, handler:(() -> Void)?) {
        self.assetCollectionTypes = assetCollectionTypes
        self.assetCollectionSubtypes = assetCollectionSubtypes
        self.mediaType = mediaType
        self.shouldShowEmptyAlbum = shouldShowEmptyAlbum
        update { () -> Void in
            if let handler = handler {
                handler()
            }
        }
    }
    
    // MARK: - ItemListType
    
    public typealias Item = PhotoKitAssetList
    
    public var title:String {
        get {
            return "PhotoKit"
        }
    }
    
    public func update(handler:(() -> Void)?) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            var albumListFetchResult: [PHFetchResult] = []
            for type in self.assetCollectionTypes {
                albumListFetchResult = albumListFetchResult + [PHAssetCollection.fetchAssetCollectionsWithType(type, subtype: .Any, options: nil)]
            }
            
            self.albumList = []
            var tmpAlbumList:[Item] = []
            let isAssetCollectionSubtypeAny = self.assetCollectionSubtypes.contains(.Any)
            for fetchResult in albumListFetchResult {
                fetchResult.enumerateObjectsUsingBlock { (album, index, stop) -> Void in
                    guard let album = album as? PHAssetCollection else {
                        return
                    }
                    if self.assetCollectionSubtypes.contains(album.assetCollectionSubtype) || isAssetCollectionSubtypeAny {
                        if self.shouldShowEmptyAlbum || PHAsset.fetchAssetsInAssetCollection(album, options: PhotoKitAssetList.fetchOptions(self.mediaType)).count != 0 {
                            tmpAlbumList.append(PhotoKitAssetList(album: album, mediaType: self.mediaType))
                        }
                    }
                }
            }
            if self.assetCollectionTypes == [.Moment] {
                self.albumList =  tmpAlbumList.sort{ $0.date?.timeIntervalSince1970 < $1.date?.timeIntervalSince1970 }
            } else {
                self.albumList =  tmpAlbumList
            }
            
            if let handler = handler {
                handler()
            }
        }
    }
    
    public subscript (index: Int) -> Item {
        get {
            return albumList[index] as Item
        }
    }
    
    // MARK: - CollectionType
    
    public var startIndex: Int {
        get {
            return albumList.startIndex
        }
    }
    
    public var endIndex: Int {
        get {
            return albumList.endIndex
        }
    }
    
}
