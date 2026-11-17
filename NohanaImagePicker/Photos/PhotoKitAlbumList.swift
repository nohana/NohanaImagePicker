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

// albumList is only read and written on the main queue; update(_:) fetches on a background queue
// and publishes the results on the main queue.
public class PhotoKitAlbumList: ItemList, @unchecked Sendable {

    private var albumList: [Item] = []
    private let assetCollectionTypes: [PHAssetCollectionType]
    private let assetCollectionSubtypes: [PHAssetCollectionSubtype]
    private let mediaType: MediaType
    private let shouldShowEmptyAlbum: Bool
    private let ascending: Bool
    private let customAssetCollection: CustomAssetCollection?

    // MARK: - init

    init(assetCollectionTypes: [PHAssetCollectionType], assetCollectionSubtypes: [PHAssetCollectionSubtype], mediaType: MediaType, shouldShowEmptyAlbum: Bool, ascending: Bool, customAssetCollection: CustomAssetCollection?, handler:(() -> Void)?) {
        self.assetCollectionTypes = assetCollectionTypes
        self.assetCollectionSubtypes = assetCollectionSubtypes
        self.mediaType = mediaType
        self.shouldShowEmptyAlbum = shouldShowEmptyAlbum
        self.ascending = ascending
        self.customAssetCollection = customAssetCollection
        update { () -> Void in
            if let handler = handler {
                handler()
            }
        }
    }

    // MARK: - ItemList

    public typealias Item = PhotoKitAssetList

    open var title: String {
        return "PhotoKit"
    }

    open func update(_ handler:(() -> Void)?) {
        // The handler is only called on the main queue.
        let handler = MainQueueHandler(handler: handler)
        DispatchQueue.global(qos: .default).async {
            var albumListFetchResult: [PHFetchResult<PHAssetCollection>] = []
            for type in self.assetCollectionTypes {
                albumListFetchResult = albumListFetchResult + [PHAssetCollection.fetchAssetCollections(with: type, subtype: .any, options: nil)]
            }
            DispatchQueue.main.async {
                self.albumList = []
            }
            let isAssetCollectionSubtypeAny = self.assetCollectionSubtypes.contains(.any)
            for fetchResult in albumListFetchResult {
                Array(0..<fetchResult.count).chunked(by: 20).map({ IndexSet($0) }).forEach {
                    var chunk: [Item] = []
                    fetchResult.enumerateObjects(at: $0, options: []) { (album, index, stop) in
                        if self.assetCollectionSubtypes.contains(album.assetCollectionSubtype) || isAssetCollectionSubtypeAny {
                            let assets = PhotoKitAssetList(album: album, mediaType: self.mediaType, ascending: self.ascending)
                            if self.shouldShowEmptyAlbum || assets.count > 0 {
                                chunk.append(assets)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.albumList.append(contentsOf: chunk)
                        handler.handler?()
                    }
                }
            }
            if let customAssetCollection = self.customAssetCollection {
                let asset = PhotoKitAssetList(album: customAssetCollection, mediaType: self.mediaType, ascending: self.ascending)
                DispatchQueue.main.async {
                    self.albumList.insert(asset, at: 0)
                }
            }
        }
    }

    open subscript (index: Int) -> Item {
        return albumList[index] as Item
    }

    // MARK: - CollectionType

    open var startIndex: Int {
        return albumList.startIndex
    }

    open var endIndex: Int {
        return albumList.endIndex
    }

}

// Carries a non-Sendable handler to the main queue, where it is called.
private struct MainQueueHandler: @unchecked Sendable {
    let handler: (() -> Void)?
}
