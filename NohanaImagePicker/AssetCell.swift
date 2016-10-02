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
    var asset: Asset?
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if let nohanaImagePickerController = nohanaImagePickerController {
            pickButton.setImage(
                UIImage(named: ImageName.AssetCell.PickButton.SizeM.dropped, in: nohanaImagePickerController.assetBundle, compatibleWith: nil),
                for: UIControlState())
            pickButton.setImage(
                UIImage(named: ImageName.AssetCell.PickButton.SizeM.picked, in: nohanaImagePickerController.assetBundle, compatibleWith: nil),
                for: .selected)
        }
    }
    
    @IBAction func didPushPickButton(_ sender: UIButton) {
        guard let asset = asset else {
            return
        }
        if pickButton.isSelected {
            if nohanaImagePickerController!.pickedAssetList.drop(asset: asset) {
                pickButton.isSelected = false
            }
        } else {
            if nohanaImagePickerController!.pickedAssetList.pick(asset: asset) {
                pickButton.isSelected = true
            }
        }
        self.overlayView.isHidden = !pickButton.isSelected
    }
    
    func update(asset: Asset, nohanaImagePickerController: NohanaImagePickerController) {
        self.asset = asset
        self.nohanaImagePickerController = nohanaImagePickerController
        self.pickButton.isSelected = nohanaImagePickerController.pickedAssetList.isPicked(asset) 
        self.overlayView.isHidden = !pickButton.isSelected
        self.pickButton.isHidden = !(nohanaImagePickerController.canPickAsset(asset) )
    }
}
