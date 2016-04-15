//
//  ExpandingAnimationController.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/14.
//  Copyright © 2016年 nohana. All rights reserved.
//

import AVFoundation

@available(iOS 8.0, *)
extension Size {

    static func expandingAnimationFromCellRect(fromVC: AssetListViewController, fromCell: AssetCell) -> CGRect {
        let origin = CGPoint(x: fromCell.frame.origin.x, y: fromCell.frame.origin.y - fromVC.collectionView!.contentOffset.y)
        return CGRect(origin: origin, size: fromCell.frame.size)
    }
    
    static func expandingAnimationToCellRect(fromVC: UIViewController, toSize:CGSize) -> CGRect {
        return AVMakeRectWithAspectRatioInsideRect(toSize, Size.screenRectWithoutAppBar(fromVC))
    }
}

@available(iOS 8.0, *)
class ExpandingAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    var fromCell: AssetCell
    
    init(fromCell: AssetCell) {
        self.fromCell = fromCell
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? AssetListViewController,
            toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? AssetDetailListViewController,
            containerView = transitionContext.containerView()
            else {
                return
        }
        
        let expandingImageView = UIImageView(image: fromCell.imageView.image)
        expandingImageView.contentMode = fromCell.imageView.contentMode
        expandingImageView.clipsToBounds = true
        expandingImageView.frame = Size.expandingAnimationFromCellRect(fromVC, fromCell: fromCell)

        containerView.addSubview(toVC.view)
        containerView.addSubview(expandingImageView)
        toVC.view.alpha = 0
        toVC.collectionView?.hidden = true
        toVC.view.backgroundColor = UIColor.blackColor()
        fromCell.alpha = 0
        
        UIView.animateWithDuration(
            transitionDuration(transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 10,
            options: .CurveEaseOut,
            animations: { () -> Void in
                toVC.view.alpha = 1
                expandingImageView.frame = Size.expandingAnimationToCellRect(fromVC, toSize: expandingImageView.image!.size)
            }) { (_) -> Void in
                self.fromCell.alpha = 1
                toVC.collectionView?.hidden = false
                expandingImageView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        }
    }
    
}

