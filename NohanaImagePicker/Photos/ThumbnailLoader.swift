/*
 * Copyright (C) 2026 nohana, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Photos
import UIKit

/// Loads thumbnails for the grids and the album list of one picker.
///
/// It uses a `PHCachingImageManager`, so that thumbnails of cells that are about to appear can be prepared
/// (prefetching), and keeps recently loaded thumbnails in memory, so that a cell can show them immediately
/// (e.g. after `reloadData()`). Everything is released with the picker or on a memory warning.
@MainActor
final class ThumbnailLoader: NSObject {

    private let imageManager = PHCachingImageManager()
    private let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        // About two screens of grid thumbnails, enough to show the visible cells again after reloadData().
        cache.totalCostLimit = 16 * 1024 * 1024
        return cache
    }()

    // Caching only works when the same options, target size and content mode are used for caching and for requests.
    private let options: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        return options
    }()
    private let contentMode: PHImageContentMode = .aspectFit

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    deinit {
        imageManager.stopCachingImagesForAllAssets()
    }

    @objc private func didReceiveMemoryWarning() {
        removeAllCaches()
    }

    // MARK: - Requests

    /// Returns a thumbnail that was loaded before and is still in memory.
    func cachedThumbnail(for asset: PHAsset, targetSize: CGSize) -> UIImage? {
        return memoryCache.object(forKey: cacheKey(asset, targetSize))
    }

    /// Requests a thumbnail. A locally available low quality image is delivered first (e.g. for assets that are
    /// only in iCloud), followed by the final image, so the handler can be called more than once.
    /// The handler receives the image and whether it is a low quality (degraded) one, or `nil` when the request
    /// fails (e.g. a network error for an iCloud asset). It is called on the main queue and is not called when the
    /// request is cancelled.
    @discardableResult
    func requestThumbnail(for asset: PHAsset, targetSize: CGSize, handler: @escaping @MainActor (UIImage?, Bool) -> Void) -> PHImageRequestID {
        let key = cacheKey(asset, targetSize)
        return imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { [weak self] image, info in
            let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
            guard image != nil || (!isCancelled && info?[PHImageErrorKey] != nil) else {
                return
            }
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            let deliver = {
                if let image = image, !isDegraded {
                    self?.memoryCache.setObject(image, forKey: key, cost: ThumbnailLoader.cost(of: image))
                }
                handler(image, isDegraded)
            }
            if Thread.isMainThread {
                MainActor.assumeIsolated(deliver)
            } else {
                DispatchQueue.main.async {
                    MainActor.assumeIsolated(deliver)
                }
            }
        }
    }

    func cancelRequest(_ requestID: PHImageRequestID) {
        guard requestID != PHInvalidImageRequestID else {
            return
        }
        imageManager.cancelImageRequest(requestID)
    }

    // MARK: - Prefetching

    func startCaching(_ assets: [PHAsset], targetSize: CGSize) {
        imageManager.startCachingImages(for: assets, targetSize: targetSize, contentMode: contentMode, options: options)
    }

    func stopCaching(_ assets: [PHAsset], targetSize: CGSize) {
        imageManager.stopCachingImages(for: assets, targetSize: targetSize, contentMode: contentMode, options: options)
    }

    func removeAllCaches() {
        imageManager.stopCachingImagesForAllAssets()
        memoryCache.removeAllObjects()
    }

    // MARK: - Private

    private func cacheKey(_ asset: PHAsset, _ targetSize: CGSize) -> NSString {
        return "\(asset.localIdentifier)|\(Int(targetSize.width))x\(Int(targetSize.height))" as NSString
    }

    private static func cost(of image: UIImage) -> Int {
        guard let cgImage = image.cgImage else {
            return 0
        }
        return cgImage.bytesPerRow * cgImage.height
    }
}
