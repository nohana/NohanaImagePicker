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
import UIKit

class AssetListSelectableDateSectionController: UICollectionViewController, UICollectionViewDelegateFlowLayout, ActivityIndicatable {
    
    private let nohanaImagePickerController: NohanaImagePickerController
    let photoKitAssetList: PhotoKitAssetList
    var dateSectionList: [AssetDateSection] = []
    
    var cellSize: CGSize {
        var numberOfColumns = nohanaImagePickerController.numberOfColumnsInLandscape
        if UIApplication.shared.currentStatusBarOrientation.isPortrait {
            numberOfColumns = nohanaImagePickerController.numberOfColumnsInPortrait
        }
        let cellMargin: CGFloat = 2
        let cellWidth = (view.frame.width - cellMargin * (CGFloat(numberOfColumns) - 1)) / CGFloat(numberOfColumns)
        return CGSize(width: cellWidth, height: cellWidth)
    }

    private var isHiddenMenu: Bool {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined, .restricted, .denied, .limited:
            return false
        case .authorized:
            return true
        @unknown default:
            fatalError()
        }
    }

    
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
        view.backgroundColor = nohanaImagePickerController.config.color.background ?? .white
        setUpToolbarItems()
        addPickPhotoKitAssetNotificationObservers()
        setUpActivityIndicator()
        collectionView.register(UINib(nibName: "PhotoAuthorizationLimitedCell", bundle: self.nohanaImagePickerController.assetBundle), forCellWithReuseIdentifier: PhotoAuthorizationLimitedCell.defaultReusableId)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dateSectionList = AssetDateSectionCreater().createSections(assetList: self.photoKitAssetList.assetList, options: PhotoKitAssetList.fetchOptions(self.photoKitAssetList.mediaType, ascending: false))
            self.isLoading = false
            self.collectionView?.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setToolbarTitle(nohanaImagePickerController)
        updateDoneBarButtonColor()
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

    private func updateDoneBarButtonColor() {
        parent?.navigationItem.rightBarButtonItem?.setTitleTextAttributes([
            .foregroundColor: nohanaImagePickerController.config.color.navigationBarDoneBarButtonItem,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ], for: .normal)
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let activityIndicator = activityIndicator {
            updateVisibilityOfActivityIndicator(activityIndicator)
        }
        return dateSectionList.count + 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return dateSectionList[section - 1].assetResult.count
        }
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoAuthorizationLimitedCell.defaultReusableId, for: indexPath) as? PhotoAuthorizationLimitedCell else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"PhotoAuthorizationLimitedCell\")")
            }
            cell.delegate = self
            cell.isHiddenMenu(isHiddenMenu)
            return cell
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetCell", for: indexPath) as? AssetCell else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"AssetCell\")")
        }
        let sectionListIndex = indexPath.section - 1
        let asset = PhotoKitAsset(asset: dateSectionList[sectionListIndex].assetResult[indexPath.row])
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
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "AssetDateSectionHeader", for: indexPath) as? AssetDateSectionHeaderView else {
                fatalError("failed to create AssetDateSectionHeader")
            }
            if indexPath.section == 0 {
                return header
            }
            let sectionListIndex = indexPath.section - 1
            let album = dateSectionList[sectionListIndex]
            header.date = album.creationDate
            header.delegate = self
            let assets = dateSectionList[sectionListIndex].assetResult.map { PhotoKitAsset(asset: $0) }
            header.update(assets: assets, indexPath: indexPath, nohanaImagePickerController: nohanaImagePickerController)
            return header

        default:
            fatalError("failed to create AssetDateSectionHeader")
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: collectionView.frame.width, height: isHiddenMenu ? 84 : 217)
        } else {
            return cellSize
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return .zero
        }

        return .init(width: .infinity, height: 44.0)
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
        nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didSelectPhotoKitAsset: dateSectionList[indexPath.section].assetResult[indexPath.row])
    }
    
    @available(iOS 13.0, *)
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let asset = PhotoKitAsset(asset: dateSectionList[indexPath.section].assetResult[indexPath.row])
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
                        collectionView.reloadSections(IndexSet(integer: indexPath.section))
                    }
                    return UIMenu(title: "", children: [deselect])
                } else {
                    let title = self.nohanaImagePickerController.config.strings.albumListTitle ?? NSLocalizedString("action.title.select", tableName: "NohanaImagePicker", bundle: self.nohanaImagePickerController.assetBundle, comment: "")
                    let select = UIAction(title: title, image: UIImage(systemName: "checkmark.circle")) { _ in
                        self.nohanaImagePickerController.pickAsset(asset)
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
        assetListDetailViewController.currentIndexPath = IndexPath(item: assetListDetailCurrentRow, section: 0)
    }

    // MARK: - IBSegueAction
    @IBSegueAction func makeDetailList(_ coder: NSCoder) -> AssetDetailListViewController? {
        AssetDetailListViewController(coder: coder, nohanaImagePickerController: nohanaImagePickerController, photoKitAssetList: photoKitAssetList)
    }
}

// MARK: - AssetDateSectionHeaderViewDelegate
extension AssetListSelectableDateSectionController: AssetDateSectionHeaderViewDelegate {
    func didPushPickButton() {
        collectionView.reloadData()
        updateDoneBarButtonColor()
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
                header?.update(assets: assets, indexPath: indexPath, nohanaImagePickerController: nohanaImagePickerController)
            } else {
                UIView.animate(withDuration: 0) { [weak self] in
                    self?.collectionView.performBatchUpdates({ [weak self] in
                        let indexSet = IndexSet(integer: indexPath.section)
                        self?.collectionView.reloadSections(indexSet)
                    }, completion: nil)
                }
            }
        }
        updateDoneBarButtonColor()
    }
}

extension AssetListSelectableDateSectionController: PhotoAuthorizationLimitedCellDeletate {
    func didSelectAddPhotoButton(_ cell: PhotoAuthorizationLimitedCell) {

    }
    func didSelectauthorizeAllPhotoButton(_ cell: PhotoAuthorizationLimitedCell) {

    }
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont = .systemFont(ofSize: 13.5)) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}
