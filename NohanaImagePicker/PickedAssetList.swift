//
//  PickedAssetList.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/17.
//  Copyright © 2016年 nohana. All rights reserved.
//

import Foundation

class PickedAssetList: ItemListType {
    
    var assetlist: Array<AssetType> = []
    weak var nohanaImagePickerController: NohanaImagePickerController?
    
    // MARK: - ItemListType
    
    typealias Item = AssetType
    
    var title: String {
        get {
            return "Selected Assets"
        }
    }
    
    func update(handler:(() -> Void)?) {
        fatalError("not supported")
    }
    
    
    subscript (index: Int) -> Item {
        get {
            return assetlist[index]
        }
    }
    
    // MARK: - CollectionType
    
    var startIndex: Int {
        get {
            return 0
        }
    }
    
    var endIndex: Int {
        get {
            return assetlist.count
        }
    }
    
    // MARK: - Manage assetlist
    
    func pickAsset(asset: AssetType) -> Bool {
        guard !isPicked(asset) else {
            return false
        }
        guard let nohanaImagePickerController = nohanaImagePickerController else {
            return false
        }
        let assetsCountBeforePicking = self.count
        if asset is PhotoKitAsset {
            if let canPick = nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, willPickPhotoKitAsset: (asset as! PhotoKitAsset).originalAsset, pickedAssetsCount: assetsCountBeforePicking)
                where !canPick {
                return false
            }
        }
        guard nohanaImagePickerController.maximumNumberOfSelection == 0 || assetsCountBeforePicking < nohanaImagePickerController.maximumNumberOfSelection else {
            return false
        }
        assetlist.append(asset)
        let assetsCountAfterPicking = self.count
        if asset is PhotoKitAsset {
            let originalAsset = (asset as! PhotoKitAsset).originalAsset
            nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didPickPhotoKitAsset: originalAsset, pickedAssetsCount: assetsCountAfterPicking)
            NSNotificationCenter.defaultCenter().postNotification(
                NSNotification(
                    name: NotificationInfo.Asset.PhotoKit.didPick,
                    object: nohanaImagePickerController,
                    userInfo: [
                        NotificationInfo.Asset.PhotoKit.didPickUserInfoKeyAsset : originalAsset,
                        NotificationInfo.Asset.PhotoKit.didPickUserInfoKeyPickedAssetsCount : assetsCountAfterPicking
                    ]
                )
            )
        }
        return true
        
    }
    
    func dropAsset(asset: AssetType) -> Bool {
        guard let nohanaImagePickerController = nohanaImagePickerController else {
            return false
        }
        let assetsCountBeforeDropping = self.count
        if asset is PhotoKitAsset {
            if let canDrop = nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, willDropPhotoKitAsset: (asset as! PhotoKitAsset).originalAsset, pickedAssetsCount: assetsCountBeforeDropping) where !canDrop {
                return false
            }
        }
        assetlist = assetlist.filter{ $0.identifier != asset.identifier }
        let assetsCountAfterDropping = self.count
        if asset is PhotoKitAsset {
            let originalAsset = (asset as! PhotoKitAsset).originalAsset
            nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didDropPhotoKitAsset: originalAsset, pickedAssetsCount: assetsCountAfterDropping)
            NSNotificationCenter.defaultCenter().postNotification(
                NSNotification(
                    name: NotificationInfo.Asset.PhotoKit.didDrop,
                    object: nohanaImagePickerController,
                    userInfo: [
                        NotificationInfo.Asset.PhotoKit.didDropUserInfoKeyAsset : originalAsset,
                        NotificationInfo.Asset.PhotoKit.didDropUserInfoKeyPickedAssetsCount : assetsCountAfterDropping
                    ]
                )
            )
        }
        return true
    }
    
    func isPicked(asset: AssetType) -> Bool {
        return assetlist.contains{ $0.identifier == asset.identifier }
    }
    
}