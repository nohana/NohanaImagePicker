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

class AssetDetailListViewController: AssetListViewController, DetailListViewControllerProtocol {

    var currentIndexPath: IndexPath = IndexPath() {
        willSet {
            if currentIndexPath != newValue {
                didChangeAssetDetailPage(newValue)
            }
        }
    }

    @IBOutlet weak var pickButton: UIButton!
    var placeholder: (item: Int, image: UIImage)?

    override var cellSize: CGSize {
        return Size.screenRectWithoutAppBar(self).size
    }
    
    override func loadView() {
        super.loadView()
        self.collectionView.backgroundColor = .black
        self.collectionView.contentInsetAdjustmentBehavior = .never
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        letSwipeBackWinOverPaging()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        fitPagesBetweenBars()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Detail pages load high quality images instead of thumbnails.
        collectionView.prefetchDataSource = nil
        let droppedImage: UIImage? = nohanaImagePickerController.config.image.droppedLarge ?? UIImage(named: "btn_select_l", in: nohanaImagePickerController.assetBundle, compatibleWith: nil)
        let pickedImage: UIImage? = nohanaImagePickerController.config.image.pickedLarge ?? UIImage(named: "btn_selected_l", in: nohanaImagePickerController.assetBundle, compatibleWith: nil)
        
        pickButton.setImage(droppedImage, for: UIControl.State())
        pickButton.setImage(pickedImage, for: .selected)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let indexPath = currentIndexPath
        view.isHidden = true
        coordinator.animate(alongsideTransition: nil) { _ in
            self.view.invalidateIntrinsicContentSize()
            self.collectionView?.reloadData()
            self.scrollCollectionView(to: indexPath)
            self.view.isHidden = false
        }
    }

    func didChangeAssetDetailPage(_ indexPath: IndexPath) {
        let asset = photoKitAssetList[indexPath.item]
        pickButton.isSelected = nohanaImagePickerController.pickedAssetList.isPicked(asset)
        pickButton.isHidden = !(nohanaImagePickerController.canPickAsset(asset) )
        nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, assetDetailListViewController: self, didChangeAssetDetailPage: indexPath, photoKitAsset: asset.originalAsset)
    }

    override func scrollCollectionView(to indexPath: IndexPath) {
        guard photoKitAssetList.count > 0 else {
            return
        }
        DispatchQueue.main.async {
            let toIndexPath = IndexPath(item: indexPath.item, section: 0)
            self.collectionView?.scrollToItem(at: toIndexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: false)
        }
    }

    override func scrollCollectionViewToInitialPosition() {
        guard isFirstAppearance else {
            return
        }
        scrollToCurrentPage()
        isFirstAppearance = false
    }

    // MARK: - IBAction

    @IBAction func didPushPickButton(_ sender: UIButton) {
        let asset = photoKitAssetList[currentIndexPath.row]
        if pickButton.isSelected {
            if nohanaImagePickerController.pickedAssetList.drop(asset: asset) {
                pickButton.isSelected = false
            }
        } else {
            if nohanaImagePickerController.pickedAssetList.pick(asset: asset) {
                pickButton.isSelected = true
            }
        }
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetDetailCell", for: indexPath) as? AssetDetailCell else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"AssetDetailCell\")")
        }
        cell.scrollView.zoomScale = 1

        let imageSize = CGSize(
            width: cellSize.width * UIScreen.main.scale,
            height: cellSize.height * UIScreen.main.scale
        )
        let asset = photoKitAssetList[indexPath.item]
        let placeholder = takePlaceholder(for: indexPath)
        if placeholder != nil {
            // The page may be laid out during the transition. Lay it out right away, or the image would animate in.
            UIView.performWithoutAnimation {
                cell.imageViewHeightConstraint.constant = cellSize.height
                cell.imageViewWidthConstraint.constant = cellSize.width
                cell.layoutIfNeeded()
            }
        }
        cell.loadImage(of: asset, targetSize: imageSize, placeholder: placeholder) { [weak self, weak cell] in
            guard let self = self, let cell = cell else {
                return
            }
            cell.imageViewHeightConstraint.constant = self.cellSize.height
            cell.imageViewWidthConstraint.constant = self.cellSize.width
        }
        return (nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, assetDetailListViewController: self, cell: cell, indexPath: indexPath, photoKitAsset: asset.originalAsset)) ?? cell
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let collectionView = collectionView else {
            return
        }
        let row = Int((collectionView.contentOffset.x + cellSize.width * 0.5) / cellSize.width)
        if row < 0 {
            currentIndexPath = IndexPath(row: 0, section: currentIndexPath.section)
        } else if row >= collectionView.numberOfItems(inSection: 0) {
            currentIndexPath = IndexPath(row: collectionView.numberOfItems(inSection: 0) - 1, section: currentIndexPath.section)
        } else {
            currentIndexPath = IndexPath(row: row, section: currentIndexPath.section)
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }

}
