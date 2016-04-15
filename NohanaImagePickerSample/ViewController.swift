//
//  ViewController.swift
//  NohanaImagePickerSample
//
//  Created by kazushi.hara on 2016/02/08.
//  Copyright © 2016年 nohana. All rights reserved.
//

import UIKit
import Photos
import NohanaImagePicker

class ViewController: UIViewController, NohanaImagePickerControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        picker.maximumNumberOfSelection = 4
        picker.canPickAsset = { (asset:AssetType) -> Bool in
            return asset.identifier % 10 != 0
        }
        presentViewController(picker, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - NohanaImagePickerControllerDelegate
    
    func nohanaImagePickerDidCancel(picker: NohanaImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func nohanaImagePicker(picker: NohanaImagePickerController, didFinishPickingPhotoKitAssets pickedAssts :[PHAsset]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func willPickPhotoKitAsset(asset: PHAsset, pickedAssetsCount: Int) -> Bool {
        print("func:\(__FUNCTION__), asset: \(asset), pickedAssetsCount: \(pickedAssetsCount)")
        return true
    }
    
    func didPickPhotoKitAsset(asset: PHAsset, pickedAssetsCount: Int) {
        print("func:\(__FUNCTION__), asset: \(asset), pickedAssetsCount: \(pickedAssetsCount)")
    }
    
    func willDropPhotoKitAsset(asset: PHAsset, pickedAssetsCount: Int) -> Bool {
        print("func:\(__FUNCTION__), asset: \(asset), pickedAssetsCount: \(pickedAssetsCount)")
        return true
    }
    
    func didDropPhotoKitAsset(asset: PHAsset, pickedAssetsCount: Int) {
        print("func:\(__FUNCTION__), asset: \(asset), pickedAssetsCount: \(pickedAssetsCount)")
    }
    
    func didSelectPhotoKitAsset(asset: PHAsset) {
        print("func:\(__FUNCTION__), assetList: \(asset)")
    }
    
    func didSelectPhotoKitAssetList(assetList: PHAssetCollection) {
        print("func:\(__FUNCTION__), assetList: \(assetList)")
    }
    
    func assetListView(collectionView: UICollectionView, cell: UICollectionViewCell, indexPath: NSIndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell {
        print("func:\(__FUNCTION__), cell:\(cell), indexPath: \(indexPath), photoKitAsset: \(photoKitAsset)")
        return cell
    }
    
    func assetDetailListView(collectionView: UICollectionView, cell: UICollectionViewCell, indexPath: NSIndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell {
        print("func:\(__FUNCTION__), cell:\(cell), indexPath: \(indexPath), photoKitAsset: \(photoKitAsset)")
        return cell
    }
    
    func didChangeAssetDetailPage(indexPath: NSIndexPath, photoKitAsset: PHAsset) {
        print("func:\(__FUNCTION__), indexPath: \(indexPath), photoKitAsset: \(photoKitAsset)")
    }
}

