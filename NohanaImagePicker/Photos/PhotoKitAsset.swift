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
import UIKit

public class PhotoKitAsset: Asset {

    let asset: PHAsset

    public init(asset: PHAsset) {
        self.asset = asset
    }

    public var originalAsset: PHAsset {
        return asset as PHAsset
    }

    // MARK: - Asset

    public var identifier: Int {
        return asset.localIdentifier.hash
    }

    public func image(targetSize: CGSize, handler: @escaping (ImageData?) -> Void) {
        requestImage(targetSize: targetSize, handler: handler)
    }

    // MARK: - Image requests

    /// Requests the high quality image (never a degraded one), downloading it from iCloud if needed.
    /// Calls `handler(nil)` when the request fails. Returns the request ID so that the request can be cancelled.
    @discardableResult
    func requestImage(targetSize: CGSize, handler: @escaping (ImageData?) -> Void) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .highQualityFormat

        return PHImageManager.default().requestImage(
            for: self.asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: option ) { (image, info) -> Void in
                if info?[PHImageErrorKey] != nil {
                    handler(nil)
                    return
                }
                let isDegraded = (
                    info?[PHImageResultIsDegradedKey] as? Bool
                ) ?? false
                guard !isDegraded, let image = image else {
                    return
                }
                handler(ImageData(image: image, info: info as Dictionary<NSObject, AnyObject>?))
        }
    }

    /// Requests a thumbnail. A locally available low quality image is delivered first (e.g. for assets that are
    /// only in iCloud), followed by the final image, so the handler can be called more than once.
    /// The handler receives the image and whether it is a low quality (degraded) one, or `nil` when the request
    /// fails (e.g. a network error for an iCloud asset). It is called on the main queue and is not called when the
    /// request is cancelled.
    @discardableResult
    func requestThumbnail(targetSize: CGSize, handler: @escaping @MainActor @Sendable (UIImage?, Bool) -> Void) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .opportunistic
        option.resizeMode = .fast

        return PHImageManager.default().requestImage(
            for: self.asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: option ) { (image, info) -> Void in
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                guard image != nil || (!isCancelled && info?[PHImageErrorKey] != nil) else {
                    return
                }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if Thread.isMainThread {
                    MainActor.assumeIsolated {
                        handler(image, isDegraded)
                    }
                } else {
                    DispatchQueue.main.async {
                        handler(image, isDegraded)
                    }
                }
        }
    }

    static func cancelImageRequest(_ requestID: PHImageRequestID) {
        guard requestID != PHInvalidImageRequestID else {
            return
        }
        PHImageManager.default().cancelImageRequest(requestID)
    }
}
