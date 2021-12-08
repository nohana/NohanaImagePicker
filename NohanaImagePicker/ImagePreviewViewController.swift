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
            guard let self = self, let image = imageData?.image else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.imageView.image = image
                let width = UIScreen.main.bounds.size.width
                let height = image.size.height * (width / image.size.width)
                let contentSize = CGSize(width: width, height: height)
                self.preferredContentSize = contentSize
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
