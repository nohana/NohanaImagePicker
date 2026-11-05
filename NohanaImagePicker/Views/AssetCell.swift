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

@MainActor
protocol AssetCellDelegate: AnyObject {
    func didPushPickButton(cell: AssetCell)
}

class AssetCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pickButton: UIButton!
    @IBOutlet weak var overlayView: UIView!

    weak var delegate: AssetCellDelegate?
    weak var nohanaImagePickerController: NohanaImagePickerController?
    var asset: Asset?
    private var representedAssetIdentifier: String?
    private var displayedAssetIdentifier: String?
    private var imageRequestID: PHImageRequestID = PHInvalidImageRequestID
    private var showActivityIndicatorWorkItem: DispatchWorkItem?
    private var retryWorkItem: DispatchWorkItem?
    private let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    private let failureImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "photo"))
        imageView.tintColor = .secondaryLabel
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // awakeFromNib is not annotated as main actor-isolated, but nibs are always loaded on the main thread.
        MainActor.assumeIsolated {
            setUpLoadingViews()
            updateAppearance()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cancelImageRequest()
        updateAppearance()
    }

    // MARK: - Image

    func loadThumbnail(of asset: PhotoKitAsset, targetSize: CGSize) {
        cancelImageRequest()
        let identifier = asset.originalAsset.localIdentifier
        // Clear another asset's image, but keep the image when the same asset is shown again (e.g. after reloadData).
        if displayedAssetIdentifier != identifier {
            imageView.image = nil
            displayedAssetIdentifier = nil
        }
        representedAssetIdentifier = identifier
        scheduleActivityIndicator(for: identifier)
        requestThumbnail(of: asset, targetSize: targetSize, identifier: identifier, canRetry: true)
    }

    private func requestThumbnail(of asset: PhotoKitAsset, targetSize: CGSize, identifier: String, canRetry: Bool) {
        imageRequestID = asset.requestThumbnail(targetSize: targetSize) { [weak self] image, isDegraded in
            // The cell may have been reused for another asset in the meantime.
            guard let self = self, self.representedAssetIdentifier == identifier else {
                return
            }
            guard let image = image else {
                if self.displayedAssetIdentifier == identifier {
                    // Keep the low quality image that is already shown.
                    self.stopLoadingViews()
                } else if canRetry {
                    // Failures are often temporary (e.g. many iCloud downloads at once), so retry once.
                    self.scheduleRetry(of: asset, targetSize: targetSize, identifier: identifier)
                } else {
                    self.stopLoadingViews()
                    self.failureImageView.isHidden = false
                }
                return
            }
            self.stopLoadingViews()
            // Do not replace this asset's image with a low quality one when it is shown again.
            if isDegraded && self.displayedAssetIdentifier == identifier {
                return
            }
            self.imageView.image = image
            self.displayedAssetIdentifier = identifier
        }
    }

    private func cancelImageRequest() {
        PhotoKitAsset.cancelImageRequest(imageRequestID)
        imageRequestID = PHInvalidImageRequestID
        representedAssetIdentifier = nil
        stopLoadingViews()
        failureImageView.isHidden = true
    }

    private func scheduleRetry(of asset: PhotoKitAsset, targetSize: CGSize, identifier: String) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.representedAssetIdentifier == identifier else {
                return
            }
            self.requestThumbnail(of: asset, targetSize: targetSize, identifier: identifier, canRetry: false)
        }
        retryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
    }

    // MARK: - Loading state

    private func setUpLoadingViews() {
        contentView.insertSubview(activityIndicator, aboveSubview: imageView)
        contentView.insertSubview(failureImageView, aboveSubview: imageView)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            failureImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            failureImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
        ])
    }

    // Shows the activity indicator only when no image has arrived within 0.5 s (e.g. downloading from iCloud),
    // so that it does not flicker while scrolling.
    private func scheduleActivityIndicator(for identifier: String) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.representedAssetIdentifier == identifier, self.displayedAssetIdentifier != identifier else {
                return
            }
            self.activityIndicator.startAnimating()
        }
        showActivityIndicatorWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    private func stopLoadingViews() {
        retryWorkItem?.cancel()
        retryWorkItem = nil
        showActivityIndicatorWorkItem?.cancel()
        showActivityIndicatorWorkItem = nil
        activityIndicator.stopAnimating()
    }

    @IBAction func didPushPickButton(_ sender: UIButton) {
        guard let asset = asset else {
            return
        }
        if pickButton.isSelected {
            if nohanaImagePickerController!.pickedAssetList.drop(asset: asset) {
                pickButton.isSelected = false
            }
        } else {
            if nohanaImagePickerController!.pickedAssetList.pick(asset: asset) {
                pickButton.isSelected = true
            }
        }
        self.overlayView.isHidden = !pickButton.isSelected
        delegate?.didPushPickButton(cell: self)
    }

    func update(asset: Asset, nohanaImagePickerController: NohanaImagePickerController) {
        self.asset = asset
        self.nohanaImagePickerController = nohanaImagePickerController
        self.pickButton.isSelected = nohanaImagePickerController.pickedAssetList.isPicked(asset)
        self.overlayView.isHidden = !pickButton.isSelected
        self.pickButton.isHidden = !(nohanaImagePickerController.canPickAsset(asset) )
        updateAppearance()
    }
    
    private func updateAppearance() {
        if let nohanaImagePickerController = nohanaImagePickerController {
            let droppedImage: UIImage? = nohanaImagePickerController.config.image.droppedSmall ?? UIImage(named: "btn_select_m", in: nohanaImagePickerController.assetBundle, compatibleWith: nil)
            let pickedImage: UIImage? = nohanaImagePickerController.config.image.pickedSmall ?? UIImage(named: "btn_selected_m", in: nohanaImagePickerController.assetBundle, compatibleWith: nil)

            pickButton.setImage(droppedImage, for: UIControl.State())
            pickButton.setImage(pickedImage, for: .selected)
        }
    }
}
