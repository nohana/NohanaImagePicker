//
//  AssetListViewController.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/11.
//  Copyright © 2016年 nohana. All rights reserved.
//

import UIKit
import Photos

class AssetListViewController: UICollectionViewController {
    
    weak var nohanaImagePickerController: NohanaImagePickerController!
    var photoKitAssetList: PhotoKitAssetList!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        setUpToolbarItems()
        addPickPhotoKitAssetNotificationObservers()
        self.view.backgroundColor = ColorConfig.backgroundColor
    }
    
    var cellSize: CGSize {
        get {
            var numberOfColumns = nohanaImagePickerController.numberOfColumnsInLandscape
            if UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication().statusBarOrientation) {
                numberOfColumns = nohanaImagePickerController.numberOfColumnsInPortrait
            }
            let cellMargin:CGFloat = 2
            let cellWidth = (view.frame.width - cellMargin * (CGFloat(numberOfColumns) - 1)) / CGFloat(numberOfColumns)
            return CGSize(width: cellWidth, height: cellWidth)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setToolbarTitle(nohanaImagePickerController)
        collectionView?.reloadData()
        scrollCollectionViewToInitialPosition()
    }
    
    var isFirstAppearance = true
    
    func updateTitle() {
        title = photoKitAssetList.title
    }
    
    func scrollCollectionViewToInitialPosition() {
        guard isFirstAppearance else {
            return
        }
        guard photoKitAssetList.count > 0 else {
            return
        }
        let index = NSIndexPath(forRow: self.photoKitAssetList.count - 1, inSection: 0)
        collectionView?.scrollToItemAtIndexPath(index, atScrollPosition: .Bottom, animated: false)
        
        isFirstAppearance = false
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoKitAssetList.count
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didSelectPhotoKitAsset: photoKitAssetList[indexPath.item].originalAsset)
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AssetCell", forIndexPath: indexPath) as? AssetCell,
            nohanaImagePickerController = nohanaImagePickerController else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"AssetCell\")")
        }
        cell.tag = indexPath.item
        cell.update(photoKitAssetList[indexPath.row], nohanaImagePickerController: nohanaImagePickerController)
        
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
                    }
                }
            })
        }
        return (nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, assetListViewController: self, cell: cell, indexPath: indexPath, photoKitAsset: asset.originalAsset)) ?? cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return cellSize
    }
    
    // MARK: - Storyboard
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let selectedIndexPath = collectionView?.indexPathsForSelectedItems()?.first else {
            return
        }
        
        let assetListDetailViewController = segue.destinationViewController as! AssetDetailListViewController
        assetListDetailViewController.photoKitAssetList = photoKitAssetList
        assetListDetailViewController.nohanaImagePickerController = nohanaImagePickerController
        assetListDetailViewController.currentIndexPath = selectedIndexPath
    }
    
    // MARK: - IBAction
    @IBAction func didPushDone(sender: AnyObject) {
        let pickedPhotoKitAssets = nohanaImagePickerController.pickedAssetList.map{ ($0 as! PhotoKitAsset).originalAsset }
        nohanaImagePickerController.delegate?.nohanaImagePicker(nohanaImagePickerController, didFinishPickingPhotoKitAssets: pickedPhotoKitAssets )
    }
}


