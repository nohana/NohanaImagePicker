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

import UIKit
import Photos

final class MomentViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, ActivityIndicatable {

    private unowned let nohanaImagePickerController: NohanaImagePickerController
    var momentInfoSectionList: [MomentInfoSection] = []
    var isFirstAppearance = true
    
    var cellSize: CGSize {
        var numberOfColumns = nohanaImagePickerController.numberOfColumnsInLandscape
        if UIApplication.shared.currentStatusBarOrientation.isPortrait {
            numberOfColumns = nohanaImagePickerController.numberOfColumnsInPortrait
        }
        let cellMargin: CGFloat = 2
        let cellWidth = (view.frame.width - cellMargin * (CGFloat(numberOfColumns) - 1)) / CGFloat(numberOfColumns)
        return CGSize(width: cellWidth, height: cellWidth)
    }

    // The same size is used for prefetching and for requests, so that the cached thumbnails are used.
    var thumbnailSize: CGSize {
        return CGSize(width: cellSize.width * UIScreen.main.scale, height: cellSize.height * UIScreen.main.scale)
    }
    
    init?(coder: NSCoder, nohanaImagePickerController: NohanaImagePickerController) {
        self.nohanaImagePickerController = nohanaImagePickerController
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nohanaImagePickerController.config.color.background ?? .white
        setUpToolbarItems()
        addPickPhotoKitAssetNotificationObservers()
        setUpActivityIndicator()
        collectionView.prefetchDataSource = self
        // Building the sections reads the whole library, so do it off the main thread
        // while the activity indicator is shown.
        let mediaType = nohanaImagePickerController.mediaType
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let sections = MomentInfoSectionCreater().createSections(mediaType: mediaType)
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.momentInfoSectionList = sections
                self.isLoading = false
                self.collectionView?.reloadData()
                self.isFirstAppearance = true
                self.scrollCollectionViewToInitialPosition()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setToolbarTitle(nohanaImagePickerController)
        collectionView?.reloadData()
        scrollCollectionViewToInitialPosition()
    }

    func scrollCollectionView(to indexPath: IndexPath) {
        let count: Int? = momentInfoSectionList.count
        guard count != nil && count! > 0 else {
            return
        }
        DispatchQueue.main.async {
            self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: false)
        }
    }

    func scrollCollectionViewToInitialPosition() {
        guard isFirstAppearance else {
            return
        }
        let lastSection = momentInfoSectionList.count - 1
        guard lastSection >= 0 else {
            return
        }
        let indexPath = IndexPath(item: momentInfoSectionList[lastSection].assetResult.count - 1, section: lastSection)
        scrollCollectionView(to: indexPath)
        isFirstAppearance = false
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let activityIndicator = activityIndicator {
            updateVisibilityOfActivityIndicator(activityIndicator)
        }

        return momentInfoSectionList.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return momentInfoSectionList[section].assetResult.count
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetCell", for: indexPath) as? AssetCell else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"AssetCell\")")
        }

        let asset = PhotoKitAsset(asset: momentInfoSectionList[indexPath.section].assetResult[indexPath.row])
        cell.update(asset: asset, nohanaImagePickerController: nohanaImagePickerController)

        let imageSize = thumbnailSize
        cell.loadThumbnail(of: asset, targetSize: imageSize, loader: nohanaImagePickerController.thumbnailLoader)
        return (nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, assetListViewController: self, cell: cell, indexPath: indexPath, photoKitAsset: asset.originalAsset)) ?? cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let album = momentInfoSectionList[indexPath.section]
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "MomentHeader", for: indexPath) as? MomentSectionHeaderView else {
                fatalError("failed to create MomentHeader")
            }
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = DateFormatter.Style.none
            header.dateLabel.text = formatter.string(from: album.creationDate)
            return header
        default:
            fatalError("failed to create MomentHeader")
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }

    // MARK: - ActivityIndicatable

    var activityIndicator: UIActivityIndicatorView?
    var isLoading = true

    func setUpActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator?.color = .gray
        let screenRect = Size.screenRectWithoutAppBar(self)
        activityIndicator?.center = CGPoint(x: screenRect.size.width / 2, y: screenRect.size.height / 2)
        activityIndicator?.startAnimating()
    }

    func isProgressing() -> Bool {
        return isLoading
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didSelectPhotoKitAsset: momentInfoSectionList[indexPath.section].assetResult[indexPath.row])
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let asset = PhotoKitAsset(asset: momentInfoSectionList[indexPath.section].assetResult[indexPath.row])
        if let cell = collectionView.cellForItem(at: indexPath) as? AssetCell {
            return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: { [weak self] in
                // Create a preview view controller and return it
                guard let self = self else { return nil }
                let previewViewController = ImagePreviewViewController(asset: asset)
                let imageSize = cell.imageView.image?.size ?? .zero
                let width = self.view.bounds.width
                let height = imageSize.height * (width / imageSize.width)
                let contentSize = CGSize(width: width, height: height)
                previewViewController.preferredContentSize = contentSize
                return previewViewController
            }, actionProvider: { [weak self] _ in
                guard let self = self else { return nil }
                if self.nohanaImagePickerController.pickedAssetList.isPicked(asset) {
                    let title = self.nohanaImagePickerController.config.strings.albumListTitle ?? NSLocalizedString("action.title.deselect", tableName: "NohanaImagePicker", bundle: self.nohanaImagePickerController.assetBundle, comment: "")
                    let deselect = UIAction(title: title, image: UIImage(systemName: "minus.circle"), attributes: [.destructive]) { _ in
                        self.nohanaImagePickerController.dropAsset(asset)
                        collectionView.reloadItems(at: [indexPath])
                    }
                    return UIMenu(title: "", children: [deselect])
                } else {
                    let title = self.nohanaImagePickerController.config.strings.albumListTitle ?? NSLocalizedString("action.title.select", tableName: "NohanaImagePicker", bundle: self.nohanaImagePickerController.assetBundle, comment: "")
                    let select = UIAction(title: title, image: UIImage(systemName: "checkmark.circle")) { _ in
                        self.nohanaImagePickerController.pickAsset(asset)
                        collectionView.reloadItems(at: [indexPath])
                    }
                    return UIMenu(title: "", children: [select])
                }
            })
        } else {
            return nil
        }
    }

    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [weak self] in
            guard let self = self else { return }
            if let indexPath = configuration.identifier as? IndexPath {
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.performSegue(withIdentifier: "toMomentDetailListViewController", sender: nil)
            }
        }
    }

    // MARK: - IBSegueAction
    @IBSegueAction func makeMomentDetail(_ coder: NSCoder) -> MomentDetailListViewController? {
        guard let selectedIndexPath = collectionView?.indexPathsForSelectedItems?.first else {
            return nil
        }
        return MomentDetailListViewController(coder: coder, nohanaImagePickerController: nohanaImagePickerController, momentInfoSection: momentInfoSectionList[selectedIndexPath.section], currentIndexPath: selectedIndexPath)
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension MomentViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        nohanaImagePickerController.thumbnailLoader.startCaching(prefetchAssets(at: indexPaths), targetSize: thumbnailSize)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        nohanaImagePickerController.thumbnailLoader.stopCaching(prefetchAssets(at: indexPaths), targetSize: thumbnailSize)
    }

    private func prefetchAssets(at indexPaths: [IndexPath]) -> [PHAsset] {
        return indexPaths.compactMap { indexPath in
            guard indexPath.section < momentInfoSectionList.count else { return nil }
            let assets = momentInfoSectionList[indexPath.section].assetResult
            return indexPath.item < assets.count ? assets[indexPath.item] : nil
        }
    }
}
