//
//  PhotoAuthorizationLimitedCell.swift
//  NohanaImagePicker
//
//  Created by naoto.suzuki on 2022/07/27.
//  Copyright © 2022 nohana. All rights reserved.
//

import UIKit

protocol PhotoAuthorizationLimitedCellDeletate {
    func didSelectAddPhotoButton(_ cell: PhotoAuthorizationLimitedCell)
    func didSelectauthorizeAllPhotoButton(_ cell: PhotoAuthorizationLimitedCell)
}

class PhotoAuthorizationLimitedCell: UICollectionViewCell {

    static var defaultReusableId: String {
        String(describing: self)
    }

    var delegate: PhotoAuthorizationLimitedCellDeletate?

    @IBOutlet weak private var attentionLabel: UILabel!
    @IBOutlet weak private var addPhotoContainerView: UIView!
    @IBOutlet weak private var addPhotoButton: UIButton! {
        didSet {
            self.addPhotoButton.layer.cornerRadius = 6
            self.addPhotoButton.layer.borderColor = UIColor(red: 187/255, green: 187/255, blue: 187/255, alpha: 1).cgColor
            self.addPhotoButton.layer.borderWidth = 1
        }
    }
    @IBOutlet weak private var authorizeAllPhotoContainerView: UIView!
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
        delegate?.didSelectauthorizeAllPhotoButton(self)
    }

    func setMenuButtonStates(_ states: (Bool, Bool)) {
        addPhotoButton.isHidden = states.0
        authorizeAllPhotoButton.isHidden = states.1
    }
}
