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

class AssetDetailCell: UICollectionViewCell, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    let doubleTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        doubleTapGestureRecognizer.addTarget(self, action: #selector(AssetDetailCell.didDoubleTap(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        scrollView.removeGestureRecognizer(doubleTapGestureRecognizer)
        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
    }

    deinit {
        scrollView.removeGestureRecognizer(doubleTapGestureRecognizer)
        doubleTapGestureRecognizer.removeTarget(self, action: #selector(AssetDetailCell.didDoubleTap(_:)))
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    // MARK: - Zoom

    @objc func didDoubleTap(_ sender: UITapGestureRecognizer) {
        if scrollView.zoomScale < scrollView.maximumZoomScale {
            let center = sender.location(in: imageView)
            scrollView.zoom(to: zoomRect(center), animated: true)
        } else {
            let defaultScale: CGFloat = 1
            scrollView.setZoomScale(defaultScale, animated: true)
        }
    }

    func zoomRect(_ center: CGPoint) -> CGRect {
        var zoomRect: CGRect = CGRect()
        zoomRect.size.height = scrollView.frame.size.height / scrollView.maximumZoomScale
        zoomRect.size.width = scrollView.frame.size.width / scrollView.maximumZoomScale

        zoomRect.origin.x = center.x - zoomRect.size.width / 2.0
        zoomRect.origin.y = center.y - zoomRect.size.height / 2.0

        return zoomRect
    }

}
