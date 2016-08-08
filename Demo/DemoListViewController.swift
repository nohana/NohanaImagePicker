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
import NohanaImagePicker
import Photos

struct Cell {
    let title: String
    let selector: Selector
}

class DemoListViewController: UITableViewController, NohanaImagePickerControllerDelegate {
    
    let cells = [
        Cell(title: "Default", selector: #selector(DemoListViewController.showDefaultPicker)),
        Cell(title: "Large thumbnail", selector: #selector(DemoListViewController.showLargeThumbnailPicker)),
        Cell(title: "No toolbar", selector: #selector(DemoListViewController.showNoToolbarPicker)),
        Cell(title: "Disable to pick assets", selector: #selector(DemoListViewController.showDisableToPickAssetsPicker)),
    ]
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPathForSelectedRow, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        cell.textLabel?.text = cells[indexPath.row].title
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        checkIfAuthorizedToAccessPhotos { isAuthorized in
            dispatch_async(dispatch_get_main_queue(), { 
                if isAuthorized {
                    self.performSelector(self.cells[indexPath.row].selector)
                } else {
                    let alert = UIAlertController(title: "Error", message: "Denied access to photos.", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            })
        }
        
        
    }
    
    // MARK: - Photos
    
    func checkIfAuthorizedToAccessPhotos(handler: (isAuthorized: Bool) -> Void) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .NotDetermined:
            PHPhotoLibrary.requestAuthorization{ status in
                switch status {
                case .Authorized:
                    handler(isAuthorized: true)
                default:
                    handler(isAuthorized: false)
                }
            }
            
        case .Restricted:
            handler(isAuthorized: false)
        case .Denied:
            handler(isAuthorized: false)
        case .Authorized:
            handler(isAuthorized: true)
        }
    }
    
    // MARK: - Show NohanaImagePicker

    @objc
    func showDefaultPicker() {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        presentViewController(picker, animated: true, completion: nil)
    }

    @objc
    func showLargeThumbnailPicker() {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        picker.numberOfColumnsInPortrait = 2
        picker.numberOfColumnsInLandscape = 3
        presentViewController(picker, animated: true, completion: nil)
    }

    @objc
    func showNoToolbarPicker() {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        picker.toolbarHidden = true
        presentViewController(picker, animated: true, completion: nil)
    }

    @objc
    func showDisableToPickAssetsPicker() {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        picker.canPickAsset = { (asset:AssetType) -> Bool in
            return asset.identifier % 2 == 0
        }
        presentViewController(picker, animated: true, completion: nil)
    }
    
    // MARK: - NohanaImagePickerControllerDelegate
    
    func nohanaImagePickerDidCancel(picker: NohanaImagePickerController) {
        print("🐷Canceled🙅")
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, didFinishPickingPhotoKitAssets pickedAssts :[PHAsset]) {
        print("🐷Completed🙆\n\tpickedAssets = \(pickedAssts)")
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, willPickPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) -> Bool {
        print("🐷\(#function)\n\tasset = \(asset)\n\tpickedAssetsCount = \(pickedAssetsCount)")
        return true
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, didPickPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) {
        print("🐷\(#function)\n\tasset = \(asset)\n\tpickedAssetsCount = \(pickedAssetsCount)")
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, willDropPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) -> Bool {
        print("🐷\(#function)\n\tasset = \(asset)\n\tpickedAssetsCount = \(pickedAssetsCount)")
        return true
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, didDropPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) {
        print("🐷\(#function)\n\tasset = \(asset)\n\tpickedAssetsCount = \(pickedAssetsCount)")
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, didSelectPhotoKitAsset asset: PHAsset) {
        print("🐷\(#function)\n\tasset = \(asset)\n\t")
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, didSelectPhotoKitAssetList assetList: PHAssetCollection) {
        print("🐷\(#function)\n\t\tassetList = \(assetList)\n\t")
    }
    
    func nohanaImagePickerDidSelectMoment(picker: NohanaImagePickerController) -> Void {
        print("🐷\(#function)")
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, assetListViewController: UICollectionViewController, cell: UICollectionViewCell, indexPath: NSIndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell {
        print("🐷\(#function)\n\tindexPath = \(indexPath)\n\tphotoKitAsset = \(photoKitAsset)")
        return cell
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, assetDetailListViewController: UICollectionViewController, cell: UICollectionViewCell, indexPath: NSIndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell {
        print("🐷\(#function)\n\tindexPath = \(indexPath)\n\tphotoKitAsset = \(photoKitAsset)")
        return cell
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, assetDetailListViewController: UICollectionViewController, didChangeAssetDetailPage indexPath: NSIndexPath, photoKitAsset: PHAsset) {
        print("🐷\(#function)\n\tindexPath = \(indexPath)")
    }
}
