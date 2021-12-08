//
//  ImagePreviewViewController.swift
//  NohanaImagePicker
//
//  Created by atsushi.yoshimoto on 2021/12/08.
//  Copyright © 2021 nohana. All rights reserved.
//

import UIKit

class ImagePreviewViewController: UIViewController {

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    init(asset: PhotoKitAsset) {
        super.init(nibName: nil, bundle: nil)

        asset.image(targetSize: UIScreen.main.bounds.size) { [weak self] (imageData) -> Void in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let imageData = imageData {
                    self.imageView.image = imageData.image
                }
            }
        }
    }

    override func loadView() {
        view = imageView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
