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

class AssetDetailListViewController: AssetListViewController {
    
    var currentIndexPath: NSIndexPath = NSIndexPath() {
        willSet {
            if currentIndexPath != newValue {
                didChangeAssetDetailPage(newValue)
            }
        }
    }
    
    @IBOutlet weak var pickButton: UIButton!
    
    override var cellSize: CGSize {
        get {
            return Size.screenRectWithoutAppBar(self).size
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let nohanaImagePickerController = nohanaImagePickerController {
            pickButton.setImage(
                UIImage(named: ImageName.AssetCell.PickButton.SizeL.dropped, inBundle: nohanaImagePickerController.assetBundle, compatibleWithTraitCollection: nil),
                forState: .Normal)
            pickButton.setImage(
                UIImage(named: ImageName.AssetCell.PickButton.SizeL.picked, inBundle: nohanaImagePickerController.assetBundle, compatibleWithTraitCollection: nil),
                forState: [.Normal, .Selected])
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        let indexPath = currentIndexPath
        view.hidden = true
        coordinator.animateAlongsideTransition(nil) { _ in
            self.view.invalidateIntrinsicContentSize()
            for subView in self.view.subviews {
                subView.invalidateIntrinsicContentSize()
            }
            self.collectionView?.reloadData()
            self.scrollCollectionView(to: indexPath)
            self.view.hidden = false
        }
    }
    
    override func updateTitle() {
        self.title = ""
    }
    
    func didChangeAssetDetailPage(indexPath:NSIndexPath) {
        guard let nohanaImagePickerController = nohanaImagePickerController else {
            return
        }
        let asset = photoKitAssetList[indexPath.item]
        pickButton.selected = nohanaImagePickerController.pickedAssetList.isPicked(asset) ?? false
        pickButton.hidden = !(nohanaImagePickerController.canPickAsset(asset) ?? true)
        nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, assetDetailListViewController: self, didChangeAssetDetailPage: indexPath, photoKitAsset: asset.originalAsset)
    }
    
    override func scrollCollectionView(to indexPath: NSIndexPath) {
        guard photoKitAssetList.count > 0 else {
            return
        }
        let toIndexPath = NSIndexPath(forItem: indexPath.item, inSection: 0)
        collectionView?.scrollToItemAtIndexPath(toIndexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
    }
    
    override func scrollCollectionViewToInitialPosition() {
        guard isFirstAppearance else {
            return
        }
        let indexPath = NSIndexPath(forRow: currentIndexPath.item, inSection: 0)
        scrollCollectionView(to: indexPath)
        isFirstAppearance = false
    }
    
    // MARK: - IBAction
    
    @IBAction func didPushPickButton(sender: UIButton) {
        let asset = photoKitAssetList[currentIndexPath.row]
        if pickButton.selected {
            if nohanaImagePickerController!.pickedAssetList.dropAsset(asset) {
                pickButton.selected = false
            }
        } else {
            if nohanaImagePickerController!.pickedAssetList.pickAsset(asset) {
                pickButton.selected = true
            }
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AssetDetailCell", forIndexPath: indexPath) as? AssetDetailCell,
            nohanaImagePickerController = nohanaImagePickerController else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"AssetDetailCell\")")
        }
        cell.invalidateIntrinsicContentSize()
        cell.scrollView.zoomScale = 1
        cell.tag = indexPath.item
        
        let imageSize = CGSize(
            width: cellSize.width * UIScreen.mainScreen().scale,
            height: cellSize.height * UIScreen.mainScreen().scale
        )
        let asset = photoKitAssetList[indexPath.item]
        asset.image(imageSize) { (imageData) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
    
    // MARK: - UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        guard let collectionView = collectionView else {
            return
        }
        let row = Int((collectionView.contentOffset.x + cellSize.width * 0.5) / cellSize.width)
        if row < 0 {
            currentIndexPath = NSIndexPath(forRow: 0, inSection: currentIndexPath.section)
        } else if row >= collectionView.numberOfItemsInSection(0) {
            currentIndexPath = NSIndexPath(forRow: collectionView.numberOfItemsInSection(0) - 1, inSection: currentIndexPath.section)
        } else {
            currentIndexPath = NSIndexPath(forRow: row, inSection: currentIndexPath.section)
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    override func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return cellSize
    }
    
}