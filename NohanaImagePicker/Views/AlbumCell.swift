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

class AlbumCell: UITableViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    private var representedAssetIdentifier: String?
    private var displayedAssetIdentifier: String?
    private var imageRequestID: PHImageRequestID = PHInvalidImageRequestID
    private weak var thumbnailLoader: ThumbnailLoader?

    override func prepareForReuse() {
        super.prepareForReuse()
        cancelImageRequest()
    }

    // MARK: - Image

    func loadThumbnail(of asset: PhotoKitAsset, targetSize: CGSize, loader: ThumbnailLoader) {
        cancelImageRequest()
        thumbnailLoader = loader
        let identifier = asset.originalAsset.localIdentifier
        // Show a thumbnail that is still in memory immediately (e.g. after reloadData).
        if let image = loader.cachedThumbnail(for: asset.originalAsset, targetSize: targetSize) {
            thumbnailImageView.image = image
            displayedAssetIdentifier = identifier
            return
        }
        // Clear another asset's image, but keep the image when the same asset is shown again.
        if displayedAssetIdentifier != identifier {
            thumbnailImageView.image = nil
            displayedAssetIdentifier = nil
        }
        representedAssetIdentifier = identifier
        imageRequestID = loader.requestThumbnail(for: asset.originalAsset, targetSize: targetSize) { [weak self] image, isDegraded in
            // The cell may have been reused for another album in the meantime.
            guard let self = self, self.representedAssetIdentifier == identifier, let image = image else {
                return
            }
            // Do not replace this asset's image with a low quality one when it is shown again.
            if isDegraded && self.displayedAssetIdentifier == identifier {
                return
            }
            self.thumbnailImageView.image = image
            self.displayedAssetIdentifier = identifier
        }
    }

    func clearThumbnail() {
        cancelImageRequest()
        thumbnailImageView.image = nil
        displayedAssetIdentifier = nil
    }

    private func cancelImageRequest() {
        thumbnailLoader?.cancelRequest(imageRequestID)
        imageRequestID = PHInvalidImageRequestID
        representedAssetIdentifier = nil
    }
}
