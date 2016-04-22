//
//  AssetDetailCell.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/12.
//  Copyright © 2016年 nohana. All rights reserved.
//

import UIKit

class AssetDetailCell: UICollectionViewCell, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    let doubleTapGestureRecognizer :UITapGestureRecognizer = UITapGestureRecognizer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        doubleTapGestureRecognizer.addTarget(self, action: "didDoubleTap:")
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        scrollView.removeGestureRecognizer(doubleTapGestureRecognizer)
        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    deinit {
        scrollView.removeGestureRecognizer(doubleTapGestureRecognizer)
        doubleTapGestureRecognizer.removeTarget(self, action: "didDoubleTap:")
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // MARK: - Zoom
    
    func didDoubleTap(sender: UITapGestureRecognizer) {
        if scrollView.zoomScale < scrollView.maximumZoomScale {
            let center = sender.locationInView(imageView)
            scrollView.zoomToRect(zoomRect(center), animated: true)
        } else {
            let defaultScale: CGFloat = 1
            scrollView.setZoomScale(defaultScale, animated: true)
        }
    }
    
    func zoomRect(center: CGPoint) -> CGRect {
        var zoomRect: CGRect = CGRect()
        zoomRect.size.height = scrollView.frame.size.height / scrollView.maximumZoomScale
        zoomRect.size.width = scrollView.frame.size.width / scrollView.maximumZoomScale
        
        zoomRect.origin.x = center.x - zoomRect.size.width / 2.0
        zoomRect.origin.y = center.y - zoomRect.size.height / 2.0
        
        return zoomRect
    }
    
}