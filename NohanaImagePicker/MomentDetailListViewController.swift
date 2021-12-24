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

import UIKit

final class MomentDetailListViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, DetailListViewControllerProtocol {

    var currentIndexPath: IndexPath {
        willSet {
            if currentIndexPath != newValue {
                didChangeAssetDetailPage(newValue)
            }
        }
    }

    @IBOutlet weak var pickButton: UIButton!
    
    var cellSize: CGSize {
        return Size.screenRectWithoutAppBar(self).size
    }
    
    let nohanaImagePickerController: NohanaImagePickerController
    let momentInfoSection: MomentInfoSection
    var isFirstAppearance = true
    
    init?(coder: NSCoder, nohanaImagePickerController: NohanaImagePickerController, momentInfoSection: MomentInfoSection, currentIndexPath: IndexPath) {
        self.nohanaImagePickerController = nohanaImagePickerController
        self.momentInfoSection = momentInfoSection
        self.currentIndexPath = currentIndexPath
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        self.collectionView.backgroundColor = .black
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nohanaImagePickerController.config.color.background ?? .white
        title = ""
        setUpToolbarItems()
        addPickPhotoKitAssetNotificationObservers()
        
        let droppedImage: UIImage? = nohanaImagePickerController.config.image.droppedLarge ?? UIImage(named: "btn_select_l", in: nohanaImagePickerController.assetBundle, compatibleWith: nil)
        let pickedImage: UIImage? = nohanaImagePickerController.config.image.pickedLarge ?? UIImage(named: "btn_selected_l", in: nohanaImagePickerController.assetBundle, compatibleWith: nil)
        
        pickButton.setImage(droppedImage, for: UIControl.State())
        pickButton.setImage(pickedImage, for: .selected)
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
        let asset = PhotoKitAsset(asset: momentInfoSection.assetResult[indexPath.item])
        pickButton.isSelected = nohanaImagePickerController.pickedAssetList.isPicked(asset)
        pickButton.isHidden = !(nohanaImagePickerController.canPickAsset(asset))
        nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, assetDetailListViewController: self, didChangeAssetDetailPage: indexPath, photoKitAsset: asset.originalAsset)
    }

    func scrollCollectionView(to indexPath: IndexPath) {
        guard momentInfoSection.assetResult.count > 0 else {
            return
        }
        DispatchQueue.main.async {
            let toIndexPath = IndexPath(item: indexPath.item, section: 0)
            self.collectionView?.scrollToItem(at: toIndexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: false)
        }
    }

    func scrollCollectionViewToInitialPosition() {
        guard isFirstAppearance else {
            return
        }
        let indexPath = IndexPath(item: currentIndexPath.item, section: 0)
        self.scrollCollectionView(to: indexPath)
        isFirstAppearance = false
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return momentInfoSection.assetResult.count
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didSelectPhotoKitAsset: momentInfoSection.assetResult[indexPath.item])
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetDetailCell", for: indexPath) as? AssetDetailCell else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"AssetDetailCell\")")
        }
        cell.scrollView.zoomScale = 1
        cell.tag = indexPath.item

        let imageSize = CGSize(
            width: cellSize.width * UIScreen.main.scale,
            height: cellSize.height * UIScreen.main.scale
        )
        let asset = PhotoKitAsset(asset: momentInfoSection.assetResult[indexPath.item])
        asset.image(targetSize: imageSize) { (imageData) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if let imageData = imageData {
                    if cell.tag == indexPath.item {
                        cell.imageView.image = imageData.image
                        cell.imageViewHeightConstraint.constant = self.cellSize.height
                        cell.imageViewWidthConstraint.constant = self.cellSize.width
                    }
                }
            })
        }
        return (nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, assetDetailListViewController: self, cell: cell, indexPath: indexPath, photoKitAsset: asset.originalAsset)) ?? cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
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

    // MARK: - IBAction
    
    @IBAction func didPushPickButton(_ sender: UIButton) {
        let asset = PhotoKitAsset(asset: momentInfoSection.assetResult[currentIndexPath.item])
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

}
