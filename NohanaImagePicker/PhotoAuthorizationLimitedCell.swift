//
//  PhotoAuthorizationLimitedCell.swift
//  NohanaImagePicker
//
//  Created by naoto.suzuki on 2022/07/27.
//  Copyright © 2022 nohana. All rights reserved.
//

import UIKit

class PhotoAuthorizationLimitedCell: UICollectionViewCell {

    static var defaultReusableId: String {
        String(describing: self)
    }

    @IBOutlet weak private var attentionLabel: UILabel!
    @IBOutlet weak private var addPhotoButton: UIButton!
    @IBOutlet weak private var authorizeAllPhotoButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func tappedAddPhotoButton(_ sender: UIButton) {
    }

    @IBAction func tappedAuthorizeAllPhotoButton(_ sender: UIButton) {
    }
}
