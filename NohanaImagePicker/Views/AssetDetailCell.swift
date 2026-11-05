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

class AssetDetailCell: UICollectionViewCell, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    let doubleTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()
    private var representedAssetIdentifier: String?
    private var displayedAssetIdentifier: String?
    private var imageRequestID: PHImageRequestID = PHInvalidImageRequestID

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        doubleTapGestureRecognizer.addTarget(self, action: #selector(AssetDetailCell.didDoubleTap(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        scrollView.removeGestureRecognizer(doubleTapGestureRecognizer)
        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancelImageRequest()
    }

    // MARK: - Image

    /// Loads the high quality image and calls `completion` after it is set.
    func loadImage(of asset: PhotoKitAsset, targetSize: CGSize, completion: @escaping @MainActor () -> Void) {
        cancelImageRequest()
        let identifier = asset.originalAsset.localIdentifier
        // Clear another asset's image, but keep the image when the same asset is shown again (e.g. after reloadData).
        if displayedAssetIdentifier != identifier {
            imageView.image = nil
            displayedAssetIdentifier = nil
        }
        representedAssetIdentifier = identifier
        imageRequestID = asset.requestImage(targetSize: targetSize) { [weak self] imageData in
            DispatchQueue.main.async {
                // The cell may have been reused for another asset in the meantime.
                guard let self = self, self.representedAssetIdentifier == identifier, let imageData = imageData else {
                    return
                }
                self.imageView.image = imageData.image
                self.displayedAssetIdentifier = identifier
                completion()
            }
        }
    }

    private func cancelImageRequest() {
        PhotoKitAsset.cancelImageRequest(imageRequestID)
        imageRequestID = PHInvalidImageRequestID
        representedAssetIdentifier = nil
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    // MARK: - Zoom

    @objc func didDoubleTap(_ sender: UITapGestureRecognizer) {
        if scrollView.zoomScale < scrollView.maximumZoomScale {
            let center = sender.location(in: imageView)
            scrollView.zoom(to: zoomRect(center), animated: true)
        } else {
            let defaultScale: CGFloat = 1
            scrollView.setZoomScale(defaultScale, animated: true)
        }
    }

    func zoomRect(_ center: CGPoint) -> CGRect {
        var zoomRect: CGRect = CGRect()
        zoomRect.size.height = scrollView.frame.size.height / scrollView.maximumZoomScale
        zoomRect.size.width = scrollView.frame.size.width / scrollView.maximumZoomScale

        zoomRect.origin.x = center.x - zoomRect.size.width / 2.0
        zoomRect.origin.y = center.y - zoomRect.size.height / 2.0

        return zoomRect
    }

}
