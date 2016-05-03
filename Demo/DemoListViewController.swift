//
//  DemoListViewController.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/05/02.
//  Copyright © 2016年 nohana. All rights reserved.
//

import UIKit
import NohanaImagePicker
import Photos

struct Cell {
    let title: String
    let selector: Selector
}

class DemoListViewController: UITableViewController, NohanaImagePickerControllerDelegate {
    
    let cells = [
        Cell(title: "Default", selector: "showDefaultPicker"),
        Cell(title: "Large thumbnail", selector: "showLargeThumbnailPicker"),
        Cell(title: "No toolbar", selector: "showNoToolbarPicker"),
        Cell(title: "Disable to pick assets", selector: "showDisableToPickAssetsPicker"),
    ]
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        cell.textLabel?.text = cells[indexPath.row].title
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSelector(cells[indexPath.row].selector)
    }
    
    // MARK: - Show NohanaImagePicker
    
    func showDefaultPicker() {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func showLargeThumbnailPicker() {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        picker.numberOfColumnsInPortrait = 2
        picker.numberOfColumnsInLandscape = 3
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func showNoToolbarPicker() {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        picker.toolbarHidden = true
        presentViewController(picker, animated: true, completion: nil)
    }
    
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
        print("🐷\(__FUNCTION__)\n\tasset = \(asset)\n\tpickedAssetsCount = \(pickedAssetsCount)")
        return true
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, didPickPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) {
        print("🐷\(__FUNCTION__)\n\tasset = \(asset)\n\tpickedAssetsCount = \(pickedAssetsCount)")
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, willDropPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) -> Bool {
        print("🐷\(__FUNCTION__)\n\tasset = \(asset)\n\tpickedAssetsCount = \(pickedAssetsCount)")
        return true
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, didDropPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) {
        print("🐷\(__FUNCTION__)\n\tasset = \(asset)\n\tpickedAssetsCount = \(pickedAssetsCount)")
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, didSelectPhotoKitAsset asset: PHAsset) {
        print("🐷\(__FUNCTION__)\n\tasset = \(asset)\n\t")
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, didSelectPhotoKitAssetList assetList: PHAssetCollection) {
        print("🐷\(__FUNCTION__)\n\t\tassetList = \(assetList)\n\t")
    }
    
    func nohanaImagePickerDidSelectMoment(picker: NohanaImagePickerController) -> Void {
        print("🐷\(__FUNCTION__)")
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, assetListViewController: UICollectionViewController, cell: UICollectionViewCell, indexPath: NSIndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell {
        print("🐷\(__FUNCTION__)\n\tindexPath = \(indexPath)\n\tphotoKitAsset = \(photoKitAsset)")
        return cell
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, assetDetailListViewController: UICollectionViewController, cell: UICollectionViewCell, indexPath: NSIndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell {
        print("🐷\(__FUNCTION__)\n\tindexPath = \(indexPath)\n\tphotoKitAsset = \(photoKitAsset)")
        return cell
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, assetDetailListViewController: UICollectionViewController, didChangeAssetDetailPage indexPath: NSIndexPath, photoKitAsset: PHAsset) {
        print("🐷\(__FUNCTION__)\n\tindexPath = \(indexPath)")
    }
}
