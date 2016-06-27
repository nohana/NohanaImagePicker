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

class MomentViewController: AssetListViewController, ActivityIndicatable {
    
    var momentAlbumList: PhotoKitAlbumList!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpActivityIndicator()
    }
    
    override func updateTitle() {
        if let nohanaImagePickerController = nohanaImagePickerController {
            title = NSLocalizedString("albumlist.moment.title", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
        }
    }
    
    override func scrollCollectionViewToInitialPosition() {
        guard isFirstAppearance else {
            return
        }
        dispatch_async(dispatch_get_main_queue()) {
            let lastSection = self.momentAlbumList.count - 1
            guard lastSection >= 0 else {
                return
            }
            let indexPath = NSIndexPath(forItem: self.momentAlbumList[lastSection].count - 1, inSection: lastSection)
            self.scrollCollectionView(to: indexPath)
        }
        isFirstAppearance = false
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if let activityIndicator = activityIndicator {
            updateVisibilityOfActivityIndicator(activityIndicator)
        }
        
        return momentAlbumList.count
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return momentAlbumList[section].count
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AssetCell", forIndexPath: indexPath) as? AssetCell,
            nohanaImagePickerController = nohanaImagePickerController else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"AssetCell\")")
        }
        
        let asset = momentAlbumList[indexPath.section][indexPath.row]
        cell.tag = indexPath.item
        cell.update(asset, nohanaImagePickerController: nohanaImagePickerController)

        let imageSize = CGSize(
            width: cellSize.width * UIScreen.mainScreen().scale,
            height: cellSize.height * UIScreen.mainScreen().scale
        )
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
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let album = momentAlbumList[indexPath.section]
            guard let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "MomentHeader", forIndexPath: indexPath) as? MomentSectionHeaderView else {
                fatalError("failed to create MomentHeader")
            }
            header.locationLabel.text = album.title
            if let date =  album.date {
                let formatter = NSDateFormatter()
                formatter.dateStyle = .LongStyle
                formatter.timeStyle = NSDateFormatterStyle.NoStyle
                header.dateLabel.text = formatter.stringFromDate(date)
            } else  {
                header.dateLabel.text = ""
            }
            return header
        default:
            fatalError("failed to create MomentHeader")
        }
    }
    
    // MARK: - ActivityIndicatable
    
    var activityIndicator: UIActivityIndicatorView?
    var isLoading = true
    
    func setUpActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        let screenRect = Size.screenRectWithoutAppBar(self)
        activityIndicator?.center = CGPoint(x: screenRect.size.width / 2, y: screenRect.size.height / 2)
        activityIndicator?.startAnimating()
    }
    
    func isProgressing() -> Bool {
        return isLoading
    }
    
    func didProgressComplete() {
        isFirstAppearance = true
        scrollCollectionViewToInitialPosition()
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let nohanaImagePickerController = nohanaImagePickerController {
            nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didSelectPhotoKitAsset: momentAlbumList[indexPath.section][indexPath.row].originalAsset)
        }
    }
    
    // MARK: - Storyboard
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let selectedIndexPath = collectionView?.indexPathsForSelectedItems()?.first else {
            return
        }
        
        let assetListDetailViewController = segue.destinationViewController as! AssetDetailListViewController
        assetListDetailViewController.photoKitAssetList = momentAlbumList[selectedIndexPath.section]
        assetListDetailViewController.nohanaImagePickerController = nohanaImagePickerController
        assetListDetailViewController.currentIndexPath = selectedIndexPath
    }
    
    // MARK: - IBAction
    
    @IBAction override func didPushDone(sender: AnyObject) {
        super.didPushDone(sender)
    }
    
}