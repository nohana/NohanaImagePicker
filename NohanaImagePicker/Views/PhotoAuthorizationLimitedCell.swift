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

@MainActor
protocol PhotoAuthorizationLimitedCellDeletate: AnyObject {
    func didSelectAddPhotoButton(_ cell: PhotoAuthorizationLimitedCell)
    func didSelectAuthorizeAllPhotoButton(_ cell: PhotoAuthorizationLimitedCell)
}

class PhotoAuthorizationLimitedCell: UICollectionViewCell {

    static var defaultReusableId: String {
        String(describing: self)
    }

    weak var delegate: PhotoAuthorizationLimitedCellDeletate?

    @IBOutlet weak private var containerView: UIStackView!
    @IBOutlet weak private var attentionLabel: UILabel!
    @IBOutlet weak private var addPhotoButton: UIButton! {
        didSet {
            self.addPhotoButton.layer.cornerRadius = 6
            self.addPhotoButton.layer.borderWidth = 1
        }
    }
    @IBOutlet weak private var authorizeAllPhotoButton: UIButton! {
        didSet {
            self.authorizeAllPhotoButton.layer.cornerRadius = 6
            self.authorizeAllPhotoButton.layer.borderWidth = 1
        }
    }
    
    // The light color is the one set in the nib.
    private static let attentionColor = UIColor(
        light: UIColor(red: 74/255, green: 62/255, blue: 54/255, alpha: 1),
        dark: UIColor(red: 221/255, green: 213/255, blue: 207/255, alpha: 1)
    )

    override func awakeFromNib() {
        super.awakeFromNib()
        // awakeFromNib is not annotated as main actor-isolated, but nibs are always loaded on the main thread.
        MainActor.assumeIsolated {
            attentionLabel.textColor = Self.attentionColor
            addPhotoButton.configuration?.baseForegroundColor = .label
            authorizeAllPhotoButton.configuration?.baseForegroundColor = .label
            updateBorderColors()
            // A CGColor does not follow the appearance, so set it again when the appearance changes.
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (cell: PhotoAuthorizationLimitedCell, _: UITraitCollection) in
                cell.updateBorderColors()
            }
        }
    }

    private func updateBorderColors() {
        let borderColor = UIColor.opaqueSeparator.resolvedColor(with: traitCollection).cgColor
        addPhotoButton.layer.borderColor = borderColor
        authorizeAllPhotoButton.layer.borderColor = borderColor
    }

    @IBAction func tappedAddPhotoButton(_ sender: UIButton) {
        delegate?.didSelectAddPhotoButton(self)
    }

    @IBAction func tappedAuthorizeAllPhotoButton(_ sender: UIButton) {
        delegate?.didSelectAuthorizeAllPhotoButton(self)
    }

    func update(_ isHidden: Bool, nohanaImagePickerController: NohanaImagePickerController) {

        containerView.isHidden = isHidden
        attentionLabel.text = NSLocalizedString(
            "albumlist.menu.description",
            tableName: "NohanaImagePicker",
            bundle: nohanaImagePickerController.assetBundle,
            comment: ""
        )

        addPhotoButton.setTitle(
            NSLocalizedString(
                "albumlist.menu.addPhoto.title",
                tableName: "NohanaImagePicker",
                bundle: nohanaImagePickerController.assetBundle,
                comment: ""
            ),
            for: .normal
        )

        authorizeAllPhotoButton.setTitle(
            NSLocalizedString(
                "albumlist.menu.authorizeAllPhoto.title",
                tableName: "NohanaImagePicker",
                bundle: nohanaImagePickerController.assetBundle,
                comment: ""
            ),
            for: .normal
        )
    }
    
    func isHiddenCell(_ isHidden: Bool) {
        containerView.isHidden = isHidden
    }

    static func cellSize(_ nohanaImagePickerController: NohanaImagePickerController) -> CGSize {
        let descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .systemFont(ofSize: 13.5)
        descriptionLabel.text = NSLocalizedString("albumlist.menu.description", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
        let maxSize: CGSize = .init(width: UIScreen.main.bounds.width - 28, height: .infinity)
        let height: CGFloat = descriptionLabel.sizeThatFits(maxSize).height + 44 * 2 + 10 + 16 * 3
        return .init(width: UIScreen.main.bounds.width, height: height)
    }
}
