/*
 * Copyright (C) 2022 nohana, Inc.
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

protocol PhotoAuthorizationLimitedCellDeletate {
    func didSelectAddPhotoButton(_ cell: PhotoAuthorizationLimitedCell)
    func didSelectAuthorizeAllPhotoButton(_ cell: PhotoAuthorizationLimitedCell)
}

class PhotoAuthorizationLimitedCell: UICollectionViewCell {

    static var defaultReusableId: String {
        String(describing: self)
    }

    var delegate: PhotoAuthorizationLimitedCellDeletate?

    @IBOutlet weak private var containerView: UIStackView!
    @IBOutlet weak private var attentionLabel: UILabel!
    @IBOutlet weak private var addPhotoButton: UIButton! {
        didSet {
            self.addPhotoButton.layer.cornerRadius = 6
            self.addPhotoButton.layer.borderColor = UIColor(red: 187/255, green: 187/255, blue: 187/255, alpha: 1).cgColor
            self.addPhotoButton.layer.borderWidth = 1
        }
    }
    @IBOutlet weak private var authorizeAllPhotoButton: UIButton! {
        didSet {
            self.authorizeAllPhotoButton.layer.cornerRadius = 6
            self.authorizeAllPhotoButton.layer.borderColor = UIColor(red: 187/255, green: 187/255, blue: 187/255, alpha: 1).cgColor
            self.authorizeAllPhotoButton.layer.borderWidth = 1
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func tappedAddPhotoButton(_ sender: UIButton) {
        delegate?.didSelectAddPhotoButton(self)
    }

    @IBAction func tappedAuthorizeAllPhotoButton(_ sender: UIButton) {
        delegate?.didSelectAuthorizeAllPhotoButton(self)
    }

    func isHiddenMenu(_ isHidden: Bool) {
        containerView.isHidden = isHidden
    }
}
