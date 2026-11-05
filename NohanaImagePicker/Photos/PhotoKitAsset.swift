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

    static func cancelImageRequest(_ requestID: PHImageRequestID) {
        guard requestID != PHInvalidImageRequestID else {
            return
        }
        PHImageManager.default().cancelImageRequest(requestID)
    }
}
