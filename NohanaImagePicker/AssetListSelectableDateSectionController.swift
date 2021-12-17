/*
 * Copyright (C) 2021 nohana, Inc.
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

import Foundation
import Photos

protocol AssetListSelectableDateSectionControllerDelegate: AnyObject {
    func didSelectMoment(controller: AssetListSelectableDateSectionController)
}

class AssetListSelectableDateSectionController: UICollectionViewController, UICollectionViewDelegateFlowLayout, ActivityIndicatable {
    
    weak var nohanaImagePickerController: NohanaImagePickerController?
    var photoKitAssetList: PhotoKitAssetList?
    var dateSectionList: [AssetDateSection] = []
    private let titleView = NohanaImagePickerController.titleView()
    var cellSize: CGSize {
        guard let nohanaImagePickerController = nohanaImagePickerController else {
            return CGSize.zero
        }
        var numberOfColumns = nohanaImagePickerController.numberOfColumnsInLandscape
        if UIApplication.shared.statusBarOrientation.isPortrait {
            numberOfColumns = nohanaImagePickerController.numberOfColumnsInPortrait
        }
        let cellMargin: CGFloat = 2
        let cellWidth = (view.frame.width - cellMargin * (CGFloat(numberOfColumns) - 1)) / CGFloat(numberOfColumns)
        return CGSize(width: cellWidth, height: cellWidth)
    }
    weak var delegate: AssetListSelectableDateSectionControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        titleView.addTarget(self, action: #selector(didTapTitleView), for: .touchUpInside)
        navigationItem.titleView = titleView
        view.backgroundColor = nohanaImagePickerController?.config.color.background ?? .white
        updateTitle()
        if let nohanaImagePickerController = nohanaImagePickerController {
            navigationController?.setToolbarHidden(nohanaImagePickerController.toolbarHidden, animated: false)
            setUpToolbarItems()
        }
        addPickPhotoKitAssetNotificationObservers()
        setUpActivityIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nohanaImagePickerController = nohanaImagePickerController {
            setToolbarTitle(nohanaImagePickerController)
        }
        collectionView?.reloadData()
    }

    func scrollCollectionView(to indexPath: IndexPath) {
        let count: Int? = dateSectionList.count
        guard count != nil && count! > 0 else {
            return
        }
        DispatchQueue.main.async {
            self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    func reloadData() {
        guard let photoKitAssetList = self.photoKitAssetList else { return }
        updateTitle()
        dateSectionList = AssetDateSectionCreater().createSections(assetList: photoKitAssetList.assetList, options: PhotoKitAssetList.fetchOptions(photoKitAssetList.mediaType, ascending: false))
        isLoading = false
        collectionView?.reloadData()
    }
    
    private func updateTitle() {
        if let title = photoKitAssetList?.title {
            let attributedTitle = NSAttributedString(string: title, attributes: nohanaImagePickerController?.titleTextAttributes)
            self.titleView.setAttributedTitle(attributedTitle, for: .normal)
            self.titleView.sizeToFit()
            self.navigationController?.navigationBar.setNeedsLayout()
            if let titleLabel = self.titleView.titleLabel, let imageView = self.titleView.imageView {
                let titleLabelWidth = titleLabel.frame.width
                let imageWidth = imageView.frame.width
                let space: CGFloat = 2.0
                self.titleView.imageEdgeInsets = UIEdgeInsets(top: 0, left: titleLabelWidth + space, bottom: 0, right: -titleLabelWidth - space)
                self.titleView.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth - space, bottom: 0, right: imageWidth + space)
            }
        }
    }
    
    @objc private func didTapTitleView() {
        showAlbumList()
        if let targetView = titleView.imageView {
            transformAnimation(targetView: targetView)
        }
    }
    
    private func showAlbumList() {
        guard let nohanaImagePickerController = nohanaImagePickerController else { return }
        let storyboard = UIStoryboard(name: "AlbumList", bundle: nohanaImagePickerController.assetBundle)
        guard let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController else {
            fatalError("navigationController init failed.")
        }
        guard let albumListViewController = navigationController.topViewController as? AlbumListViewController else {
            fatalError("albumListViewController is not topViewController.")
        }
        albumListViewController.photoKitAlbumList = PhotoKitAlbumList(assetCollectionTypes: [.smartAlbum, .album],
                                                                      assetCollectionSubtypes: nohanaImagePickerController.assetCollectionSubtypes,
                                                                      mediaType: nohanaImagePickerController.mediaType,
                                                                      shouldShowEmptyAlbum: nohanaImagePickerController.shouldShowMoment,
                                                                      ascending: !nohanaImagePickerController.canPickDateSection,
                                                                      handler: { [weak albumListViewController] in
            DispatchQueue.main.async {
                albumListViewController?.isLoading = false
                albumListViewController?.tableView.reloadData()
            }
        })
        albumListViewController.nohanaImagePickerController = nohanaImagePickerController
        albumListViewController.delegate = self
        present(navigationController, animated: true, completion: nil)
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let activityIndicator = activityIndicator {
            updateVisibilityOfActivityIndicator(activityIndicator)
        }

        return dateSectionList.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dateSectionList[section].assetResult.count
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetCell", for: indexPath) as? AssetCell,
            let nohanaImagePickerController = nohanaImagePickerController else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"AssetCell\")")
        }

        let asset = PhotoKitAsset(asset: dateSectionList[indexPath.section].assetResult[indexPath.row])
        cell.tag = indexPath.item
        cell.delegate = self
        cell.update(asset: asset, nohanaImagePickerController: nohanaImagePickerController)

        let imageSize = CGSize(
            width: cellSize.width * UIScreen.main.scale,
            height: cellSize.height * UIScreen.main.scale
        )
        asset.image(targetSize: imageSize) { (imageData) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if let imageData = imageData {
                    if cell.tag == indexPath.item {
                        cell.imageView.image = imageData.image
                    }
                }
            })
        }
        return (nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, assetListViewController: self, cell: cell, indexPath: indexPath, photoKitAsset: asset.originalAsset)) ?? cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let album = dateSectionList[indexPath.section]
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "AssetDateSectionHeader", for: indexPath) as? AssetDateSectionHeaderView,
                  let nohanaImagePickerController = nohanaImagePickerController else {
                fatalError("failed to create AssetDateSectionHeader")
            }
            header.date = album.creationDate
            header.delegate = self
            let assets = dateSectionList[indexPath.section].assetResult.map { PhotoKitAsset(asset: $0) }
            header.update(assets: assets, indexPath: indexPath, nohanaImagePickerController: nohanaImagePickerController)
            return header
        default:
            fatalError("failed to create AssetDateSectionHeader")
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
        activityIndicator = UIActivityIndicatorView(style: .gray)
        let screenRect = Size.screenRectWithoutAppBar(self)
        activityIndicator?.center = CGPoint(x: screenRect.size.width / 2, y: screenRect.size.height / 2)
        activityIndicator?.startAnimating()
    }

    func isProgressing() -> Bool {
        return isLoading
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let nohanaImagePickerController = nohanaImagePickerController {
            nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didSelectPhotoKitAsset: dateSectionList[indexPath.section].assetResult[indexPath.row])
        }
    }
    
    @available(iOS 13.0, *)
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let asset = PhotoKitAsset(asset: dateSectionList[indexPath.section].assetResult[indexPath.row])
        if let cell = collectionView.cellForItem(at: indexPath) as? AssetCell, let nohanaImagePickerController = self.nohanaImagePickerController {
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
            }, actionProvider: { _ in
                if nohanaImagePickerController.pickedAssetList.isPicked(asset) {
                    let title = nohanaImagePickerController.config.strings.albumListTitle ?? NSLocalizedString("action.title.deselect", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
                    let deselect = UIAction(title: title, image: UIImage(systemName: "minus.circle"), attributes: [.destructive]) { _ in
                        nohanaImagePickerController.dropAsset(asset)
                        collectionView.reloadSections(IndexSet(integer: indexPath.section))
                    }
                    return UIMenu(title: "", children: [deselect])
                } else {
                    let title = nohanaImagePickerController.config.strings.albumListTitle ?? NSLocalizedString("action.title.select", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
                    let select = UIAction(title: title, image: UIImage(systemName: "checkmark.circle")) { _ in
                        nohanaImagePickerController.pickAsset(asset)
                        collectionView.reloadSections(IndexSet(integer: indexPath.section))
                    }
                    return UIMenu(title: "", children: [select])
                }
            })
        } else {
            return nil
        }
    }

    @available(iOS 13.0, *)
    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [weak self] in
            guard let self = self else { return }
            if let indexPath = configuration.identifier as? IndexPath {
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.performSegue(withIdentifier: "toAssetDetailListViewController", sender: nil)
            }
        }
    }

    // MARK: - Storyboard

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let photoKitAssetList = photoKitAssetList else { return }
        guard let selectedIndexPath = collectionView?.indexPathsForSelectedItems?.first,
              selectedIndexPath.section < dateSectionList.count else {
            return
        }
        var assetListDetailCurrentRow = 0
        for section in 0..<(selectedIndexPath.section + 1) {
            if selectedIndexPath.section == section {
                assetListDetailCurrentRow += selectedIndexPath.row
            } else {
                assetListDetailCurrentRow += dateSectionList[section].assetResult.count
            }
        }
        if assetListDetailCurrentRow >= photoKitAssetList.count {
            assetListDetailCurrentRow = photoKitAssetList.count - 1
        }
        
        let assetListDetailViewController = segue.destination as! AssetDetailListViewController
        assetListDetailViewController.photoKitAssetList = photoKitAssetList
        assetListDetailViewController.nohanaImagePickerController = nohanaImagePickerController
        assetListDetailViewController.currentIndexPath = IndexPath(item: assetListDetailCurrentRow, section: 0)
    }

    // MARK: - IBAction

    @IBAction func didPushDone(_ sender: AnyObject) {
        if let nohanaImagePickerController = nohanaImagePickerController {
            let pickedPhotoKitAssets = nohanaImagePickerController.pickedAssetList.map { ($0 as! PhotoKitAsset).originalAsset }
            nohanaImagePickerController.delegate?.nohanaImagePicker(nohanaImagePickerController, didFinishPickingPhotoKitAssets: pickedPhotoKitAssets)
        }
    }
    
    @IBAction func didTapClose(_ sender: AnyObject) {
        dismiss(animated: true)
    }
}

// MARK: - AssetDateSectionHeaderViewDelegate
extension AssetListSelectableDateSectionController: AssetDateSectionHeaderViewDelegate {
    func didPushPickButton() {
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
}

// MARK: - AssetCellDelegate
extension AssetListSelectableDateSectionController: AssetCellDelegate {
    func didPushPickButton(cell: AssetCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            if #available(iOS 9.0, *) {
                let rowResetIndexPath = IndexPath(row: 0, section: indexPath.section)
                let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: rowResetIndexPath) as? AssetDateSectionHeaderView
                let assets = dateSectionList[indexPath.section].assetResult.map { PhotoKitAsset(asset: $0) }
                header?.update(assets: assets, indexPath: indexPath, nohanaImagePickerController: nohanaImagePickerController!)
            } else {
                UIView.animate(withDuration: 0) { [weak self] in
                    self?.collectionView.performBatchUpdates({ [weak self] in
                        let indexSet = IndexSet(integer: indexPath.section)
                        self?.collectionView.reloadSections(indexSet)
                    }, completion: nil)
                }
            }
        }
    }
}

extension AssetListSelectableDateSectionController: AlbumListViewControllerDelegate {
    func didSelectMoment() {
        delegate?.didSelectMoment(controller: self)
    }
    
    func didSelectAlbum(album: PhotoKitAssetList) {
        self.photoKitAssetList = album
        reloadData()
    }
}
