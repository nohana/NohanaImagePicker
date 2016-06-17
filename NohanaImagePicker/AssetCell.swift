//
//  AssetCell.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/11.
//  Copyright © 2016年 nohana. All rights reserved.
//

import UIKit

class AssetCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pickButton: UIButton!
    @IBOutlet weak var overlayView: UIView!
    
    weak var nohanaImagePickerController: NohanaImagePickerController?
    var asset: AssetType?
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        if let nohanaImagePickerController = nohanaImagePickerController {
            pickButton.setImage(
                UIImage(named: ImageName.AssetCell.PickButton.SizeM.dropped, inBundle: nohanaImagePickerController.assetBundle, compatibleWithTraitCollection: nil),
                forState: .Normal)
            pickButton.setImage(
                UIImage(named: ImageName.AssetCell.PickButton.SizeM.picked, inBundle: nohanaImagePickerController.assetBundle, compatibleWithTraitCollection: nil),
                forState: [.Normal, .Selected])
        }
    }
    
    @IBAction func didPushPickButton(sender: UIButton) {
        guard let asset = asset else {
            return
        }
        if pickButton.selected {
            if nohanaImagePickerController!.pickedAssetList.dropAsset(asset) {
                pickButton.selected = false
            }
        } else {
            if nohanaImagePickerController!.pickedAssetList.pickAsset(asset) {
                pickButton.selected = true
            }
        }
        self.overlayView.hidden = !pickButton.selected
    }
    
    func update(asset: AssetType, nohanaImagePickerController: NohanaImagePickerController) {
        self.asset = asset
        self.nohanaImagePickerController = nohanaImagePickerController
        self.pickButton.selected = nohanaImagePickerController.pickedAssetList.isPicked(asset) ?? false
        self.overlayView.hidden = !pickButton.selected
        self.pickButton.hidden = !(nohanaImagePickerController.canPickAsset(asset) ?? true)
    }
}