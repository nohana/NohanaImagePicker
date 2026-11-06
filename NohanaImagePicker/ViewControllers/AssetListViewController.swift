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

class AssetListViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    unowned let nohanaImagePickerController: NohanaImagePickerController
    let photoKitAssetList: PhotoKitAssetList
    
    init?(coder: NSCoder, nohanaImagePickerController: NohanaImagePickerController, photoKitAssetList: PhotoKitAssetList) {
        self.nohanaImagePickerController = nohanaImagePickerController
        self.photoKitAssetList = photoKitAssetList
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nohanaImagePickerController.config.color.background ?? .systemBackground
        setUpToolbarItems()
        addPickPhotoKitAssetNotificationObservers()
        collectionView.prefetchDataSource = self
    }

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

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setToolbarTitle(nohanaImagePickerController)
        collectionView?.reloadData()
        scrollCollectionViewToInitialPosition()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        view.isHidden = true
        coordinator.animate(alongsideTransition: nil) { _ in
            // http://saygoodnight.com/2015/06/18/openpics-swift-rotation.html
            if self.navigationController?.visibleViewController != self {
                self.view.frame = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y, width: size.width, height: size.height)
            }
            self.collectionView?.reloadData()
            self.scrollCollectionViewToInitialPosition()
            self.view.isHidden = false
        }
    }

    var isFirstAppearance = true

    func scrollCollectionView(to indexPath: IndexPath) {
        guard photoKitAssetList.count > 0 else {
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
        let indexPath = IndexPath(item: self.photoKitAssetList.count - 1, section: 0)
        self.scrollCollectionView(to: indexPath)
        isFirstAppearance = false
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoKitAssetList.count
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didSelectPhotoKitAsset: photoKitAssetList[indexPath.item].originalAsset)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let asset = photoKitAssetList[indexPath.item]
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
        guard let indexPath = configuration.identifier as? IndexPath,
              let detailList = storyboard?.instantiateViewController(identifier: "AssetDetailListViewController", creator: { [weak self] coder in
                  self?.makeDetailList(coder)
              }) else {
            return
        }
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        prepareDetailList(detailList, at: indexPath, image: (animator.previewViewController as? ImagePreviewViewController)?.image)
        pushDetailList(detailList, expandingFrom: animator)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetCell", for: indexPath) as? AssetCell else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"AssetCell\")")
        }
        cell.update(asset: photoKitAssetList[indexPath.row], nohanaImagePickerController: nohanaImagePickerController)

        let imageSize = thumbnailSize
        let asset = photoKitAssetList[indexPath.item]
        cell.loadThumbnail(of: asset, targetSize: imageSize, loader: nohanaImagePickerController.thumbnailLoader)
        return (nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, assetListViewController: self, cell: cell, indexPath: indexPath, photoKitAsset: asset.originalAsset)) ?? cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }

    // MARK: - Storyboard

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let selectedIndexPath = collectionView?.indexPathsForSelectedItems?.first else {
            return
        }

        prepareDetailList(segue.destination as! AssetDetailListViewController, at: selectedIndexPath, image: nil)
    }

    /// `image` is shown until the photo is loaded; the thumbnail is used when it is nil.
    private func prepareDetailList(_ detailList: AssetDetailListViewController, at indexPath: IndexPath, image: UIImage?) {
        detailList.currentIndexPath = indexPath
        detailList.showWhileLoading(image ?? (collectionView?.cellForItem(at: indexPath) as? AssetCell)?.imageView.image)
        zoomDetailList(detailList, nohanaImagePickerController) { page in
            IndexPath(item: page.item, section: 0)
        }
    }

    // MARK: - IBSegueAction
    @IBSegueAction func makeDetailList(_ coder: NSCoder) -> AssetDetailListViewController? {
        return AssetDetailListViewController(coder: coder, nohanaImagePickerController: nohanaImagePickerController, photoKitAssetList: photoKitAssetList)
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension AssetListViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        nohanaImagePickerController.thumbnailLoader.startCaching(prefetchAssets(at: indexPaths), targetSize: thumbnailSize)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        nohanaImagePickerController.thumbnailLoader.stopCaching(prefetchAssets(at: indexPaths), targetSize: thumbnailSize)
    }

    private func prefetchAssets(at indexPaths: [IndexPath]) -> [PHAsset] {
        return indexPaths.filter { $0.item < photoKitAssetList.count }.map { photoKitAssetList[$0.item].originalAsset }
    }
}
