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