//
//  AssetDetailListViewController.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/11.
//  Copyright © 2016年 nohana. All rights reserved.
//

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
        pickButton.setImage(
            UIImage(named: ImageName.AssetCell.PickButton.SizeL.dropped, inBundle: nohanaImagePickerController?.assetBundle, compatibleWithTraitCollection: nil),
            forState: .Normal)
        pickButton.setImage(
            UIImage(named: ImageName.AssetCell.PickButton.SizeL.picked, inBundle: nohanaImagePickerController?.assetBundle, compatibleWithTraitCollection: nil),
            forState: [.Normal, .Selected])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func updateTitle() {
        self.title = ""
    }
    
    func didChangeAssetDetailPage(indexPath:NSIndexPath) {
        let asset = photoKitAssetList[indexPath.item]
        pickButton.selected = nohanaImagePickerController?.pickedAssetList.isPicked(asset) ?? false
        pickButton.hidden = !(nohanaImagePickerController?.canPickAsset(asset) ?? true)
        guard let nohanaImagePickerController = nohanaImagePickerController else {
            return
        }
        nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, assetDetailListViewController: self, didChangeAssetDetailPage: indexPath, photoKitAsset: asset.originalAsset)
    }
    
    override func scrollCollectionViewToInitialPosition() {
        guard isFirstAppearance else {
            return
        }
        isFirstAppearance = false
        guard photoKitAssetList.count > 0 else {
            return
        }
        let indexPath = NSIndexPath(forRow: currentIndexPath.item, inSection: 0)
        collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
    }
    
    // MARK: - IBAction
    
    @IBAction func didPushPickButton(sender: UIButton) {
        guard let nohanaImagePickerController = nohanaImagePickerController else {
            return
        }
        let asset = photoKitAssetList[currentIndexPath.row]
        if pickButton.selected {
            if nohanaImagePickerController.pickedAssetList.dropAsset(asset) {
                pickButton.selected = false
            }
        } else {
            if nohanaImagePickerController.pickedAssetList.pickAsset(asset) {
                pickButton.selected = true
            }
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AssetDetailCell", forIndexPath: indexPath) as? AssetDetailCell,
            nohanaImagePickerController = nohanaImagePickerController
            else {
                return UICollectionViewCell(frame: CGRectZero)
        }
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
        currentIndexPath = NSIndexPath(forRow: row, inSection: currentIndexPath.section)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    override func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return cellSize
    }
    
}