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

class AssetListSelectableDateSectionController: UICollectionViewController, UICollectionViewDelegateFlowLayout, ActivityIndicatable {
    
    weak var nohanaImagePickerController: NohanaImagePickerController?
    var photoKitAssetList: PhotoKitAssetList!
    var dateSectionList: [AssetDateSection] = []
    var isFirstAppearance = true
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nohanaImagePickerController?.config.color.background ?? .white
        updateTitle()
        setUpToolbarItems()
        addPickPhotoKitAssetNotificationObservers()
        setUpActivityIndicator()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // TODO: DI
            self.dateSectionList = { [weak self] in
                guard let self = self else { return [] }
                var albumDateSectionList = [AssetDateSection]()
                let options = PHFetchOptions()
                options.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                let fetchAssetlist = PHAsset.fetchAssets(in: self.photoKitAssetList.assetList, options: options)
                let allAssets = fetchAssetlist.objects(at: IndexSet(0..<fetchAssetlist.count))
                let calender = Calendar.current
                var assetsByDate = [(DateComponents, [PHAsset])]()
                var assetsByDateIndex = 0
                for asset in allAssets {
                    if  assetsByDateIndex > 0 {
                        if assetsByDate[assetsByDateIndex - 1].0 == calender.dateComponents([.day, .year, .month], from: (asset.creationDate)!) {
                            assetsByDate[assetsByDateIndex - 1].1.append(asset)
                        } else {
                            let value = (calender.dateComponents([.day, .year, .month], from: (asset.creationDate)!), [asset])
                            assetsByDate.append(value)
                            assetsByDateIndex += 1
                        }
                    } else if assetsByDate.count == assetsByDateIndex {
                        let value = (calender.dateComponents([.day, .year, .month], from: (asset.creationDate)!), [asset])
                        assetsByDate.append(value)
                        assetsByDateIndex += 1
                    }
                }
                albumDateSectionList = assetsByDate.map { AssetDateSection(creationDate: calender.date(from: $0.0) ?? Date(timeIntervalSince1970: 0), assetResult: $0.1) }

                return albumDateSectionList
            }()
            self.isLoading = false
            self.collectionView?.reloadData()
            self.isFirstAppearance = true
            self.scrollCollectionViewToInitialPosition()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nohanaImagePickerController = nohanaImagePickerController {
            setToolbarTitle(nohanaImagePickerController)
        }
        collectionView?.reloadData()
        scrollCollectionViewToInitialPosition()
    }
    
    func updateTitle() {
        title = photoKitAssetList.title
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

    func scrollCollectionViewToInitialPosition() {
        guard isFirstAppearance else {
            return
        }
        let lastSection = dateSectionList.count - 1
        guard lastSection >= 0 else {
            return
        }
        let indexPath = IndexPath(item: dateSectionList[lastSection].assetResult.count - 1, section: lastSection)
        scrollCollectionView(to: indexPath)
        isFirstAppearance = false
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
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = DateFormatter.Style.none
            header.dateLabel.text = formatter.string(from: album.creationDate)
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

    // MARK: - Storyboard

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let selectedIndexPath = collectionView?.indexPathsForSelectedItems?.first else {
            return
        }
        // TODO show detail views
    }

    // MARK: - IBAction

    @IBAction func didPushDone(_ sender: AnyObject) {
        if let nohanaImagePickerController = nohanaImagePickerController {
            let pickedPhotoKitAssets = nohanaImagePickerController.pickedAssetList.map { ($0 as! PhotoKitAsset).originalAsset }
            nohanaImagePickerController.delegate?.nohanaImagePicker(nohanaImagePickerController, didFinishPickingPhotoKitAssets: pickedPhotoKitAssets)
        }
    }
}

// MARK: - AssetDateSectionHeaderViewDelegate
extension AssetListSelectableDateSectionController: AssetDateSectionHeaderViewDelegate {
    func didPushPickButton(isSelected: Bool, indexPath: IndexPath) {
        let assets = dateSectionList[indexPath.section].assetResult.map { PhotoKitAsset(asset: $0) }
        for asset in assets {
            if isSelected {
                _ = nohanaImagePickerController?.pickedAssetList.drop(asset: asset)
            } else {
                if nohanaImagePickerController?.canPickAsset(asset) ?? false {
                    _ = nohanaImagePickerController?.pickedAssetList.pick(asset: asset)
                }
            }
        }
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
}

// MARK: - AssetCellDelegate
extension AssetListSelectableDateSectionController: AssetCellDelegate {
    func didPushPickButton(cell: AssetCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            UIView.animate(withDuration: 0) { [weak self] in
                self?.collectionView.performBatchUpdates({ [weak self] in
                    let indexSet = IndexSet(integer: indexPath.section)
                    self?.collectionView.reloadSections(indexSet)
                }, completion: nil)
            }
        }
    }
}
