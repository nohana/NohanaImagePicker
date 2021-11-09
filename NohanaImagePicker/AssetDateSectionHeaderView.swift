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

class AssetDateSectionHeaderView: UICollectionReusableView {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var pickButton: UIButton!
    
    @IBAction func didPushPickButton(_ sender: UIButton) {
        // TODO data selection
        sender.isSelected = !sender.isSelected
    }
    
    func update(nohanaImagePickerController: NohanaImagePickerController) {
        if pickButton.image(for: UIControl.State()) == nil, pickButton.image(for: .selected) == nil {
            let droppedImage: UIImage? = nohanaImagePickerController.config.image.droppedSmall ?? UIImage(named: "btn_select_l", in: nohanaImagePickerController.assetBundle, compatibleWith: nil)
            let pickedImage: UIImage? = nohanaImagePickerController.config.image.pickedSmall ?? UIImage(named: "btn_selected_l", in: nohanaImagePickerController.assetBundle, compatibleWith: nil)
            pickButton.setImage(droppedImage, for: UIControl.State())
            pickButton.setImage(pickedImage, for: .selected)
        }
    }
}
