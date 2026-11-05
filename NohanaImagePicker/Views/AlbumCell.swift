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

class AlbumCell: UICollectionViewListCell {
    static let thumbnailSide: CGFloat = 70
    private static let height: CGFloat = 82

    let thumbnailImageView = UIImageView()
    let titleLabel = UILabel()

    private var representedAssetIdentifier: String?
    private var displayedAssetIdentifier: String?
    private var imageRequestID: PHImageRequestID = PHInvalidImageRequestID

    override init(frame: CGRect) {
        super.init(frame: frame)
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .black
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        let height = contentView.heightAnchor.constraint(equalToConstant: AlbumCell.height)
        // Lower than required so that it does not conflict with the temporary size the list gives the cell.
        height.priority = .defaultHigh
        NSLayoutConstraint.activate([
            height,
            thumbnailImageView.widthAnchor.constraint(equalToConstant: AlbumCell.thumbnailSide),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: AlbumCell.thumbnailSide),
            // List cells have a 4pt narrower leading margin than the table view cells used before.
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor, constant: 8),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        backgroundConfiguration = .albumListCell(for: state)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancelImageRequest()
    }

    // MARK: - Image

    func loadThumbnail(of asset: PhotoKitAsset, targetSize: CGSize) {
        cancelImageRequest()
        let identifier = asset.originalAsset.localIdentifier
        // Clear another asset's image, but keep the image when the same asset is shown again (e.g. after reloadData).
        if displayedAssetIdentifier != identifier {
            thumbnailImageView.image = nil
            displayedAssetIdentifier = nil
        }
        representedAssetIdentifier = identifier
        imageRequestID = asset.requestThumbnail(targetSize: targetSize) { [weak self] image, isDegraded in
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
        PhotoKitAsset.cancelImageRequest(imageRequestID)
        imageRequestID = PHInvalidImageRequestID
        representedAssetIdentifier = nil
    }
}

extension UIBackgroundConfiguration {
    // Clear like the table view cells used before, with the system highlight while the cell is tapped.
    static func albumListCell(for state: UICellConfigurationState) -> UIBackgroundConfiguration {
        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = state.isHighlighted || state.isSelected ? .systemGray4 : .clear
        return background
    }
}
