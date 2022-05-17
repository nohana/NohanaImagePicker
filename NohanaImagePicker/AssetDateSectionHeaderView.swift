/*
 * Copyright (C) 2021 nohana, Inc.
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

protocol AssetDateSectionHeaderViewDelegate: AnyObject {
    func didPushPickButton()
}

class AssetDateSectionHeaderView: UICollectionReusableView {
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var pickButton: UIButton!
    var date: Date? {
        didSet {
            if let dete = date {
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = DateFormatter.Style.none
                dateLabel.text = formatter.string(from: dete)
            } else {
                dateLabel.text = ""
            }
        }
    }
    var assets = [Asset]()
    weak var nohanaImagePickerController: NohanaImagePickerController?
    weak var delegate: AssetDateSectionHeaderViewDelegate?

    @IBAction func didPushPickButton(_ sender: UIButton) {
        guard let nohanaImagePickerController = nohanaImagePickerController else { return }
        let firstButtonState = sender.isSelected
        var addAssets = [Asset]()
        for asset in assets {
            guard nohanaImagePickerController.canPickAsset(asset) else { continue }
            if firstButtonState {
                _ = nohanaImagePickerController.pickedAssetList.drop(asset: asset)
                sender.isSelected = false
            } else {
                if nohanaImagePickerController.pickedAssetList.isPicked(asset) {
                    continue
                } else if nohanaImagePickerController.pickedAssetList.count + addAssets.count == nohanaImagePickerController.maximumNumberOfSelection {
                    sender.isSelected = false
                    break
                } else if nohanaImagePickerController.pickedAssetList.canPick(asset: asset) {
                    addAssets.append(asset)
                    sender.isSelected = true
                }
            }
        }
        addAssets.reversed().forEach {
            _ = nohanaImagePickerController.pickedAssetList.pick(asset: $0)
        }
        delegate?.didPushPickButton()
        nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didSelectAssetDateSectionAssets: assets.compactMap { ($0 as? PhotoKitAsset)?.originalAsset }, date: date)
    }

    func update(assets: [Asset], indexPath: IndexPath, nohanaImagePickerController: NohanaImagePickerController) {
        self.assets = assets
        self.nohanaImagePickerController = nohanaImagePickerController
        if pickButton.image(for: UIControl.State()) == nil, pickButton.image(for: .selected) == nil {
            let droppedImage: UIImage? = nohanaImagePickerController.config.image.droppedLarge ?? UIImage(named: "btn_select_l", in: nohanaImagePickerController.assetBundle, compatibleWith: nil)
            let pickedImage: UIImage? = nohanaImagePickerController.config.image.pickedLarge ?? UIImage(named: "btn_selected_l", in: nohanaImagePickerController.assetBundle, compatibleWith: nil)
            pickButton.setImage(droppedImage, for: UIControl.State())
            pickButton.setImage(pickedImage, for: .selected)
        }

        let canPick = assets.contains(where: { nohanaImagePickerController.canPickAsset($0) == true })
        pickButton.isHidden = !canPick
        if !canPick { return }
        let canPickAssets = assets.compactMap { nohanaImagePickerController.canPickAsset($0) ? $0 : nil }
        let existNotSelected = canPickAssets.contains(where: {  nohanaImagePickerController.pickedAssetList.isPicked($0) == false })
        pickButton.isSelected = !existNotSelected
    }
}
