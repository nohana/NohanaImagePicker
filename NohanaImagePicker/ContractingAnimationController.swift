//
//  ContractingAnimationController.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/15.
//  Copyright © 2016年 nohana. All rights reserved.
//

import AVFoundation

@available(iOS 8.0, *)
extension Size {
    static func contractingAnimationToCellRect(toVC: AssetListViewController, toCell: AssetCell) -> CGRect {
        let origin = CGPoint(x: toCell.frame.origin.x, y: toCell.frame.origin.y - toVC.collectionView!.contentOffset.y)
        return CGRect(origin: origin, size: toCell.frame.size)
    }
    
    static func contractingAnimationFromCellRect(fromVC: AssetDetailListViewController, fromCell: AssetDetailCell, contractingImageSize: CGSize) -> CGRect {
        var rect = AVMakeRectWithAspectRatioInsideRect(contractingImageSize, fromCell.imageView.frame)
        rect.origin.y += Size.appBarHeight(fromVC)
        rect.origin.x -= fromCell.scrollView.contentOffset.x
        rect.origin.y -= fromCell.scrollView.contentOffset.y
        return rect
    }
}

@available(iOS 8.0, *)
class ContractingAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    var fromCell: AssetDetailCell
    
    init(fromCell: AssetDetailCell) {
        self.fromCell = fromCell
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? AssetDetailListViewController,
            toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? AssetListViewController,
            containerView = transitionContext.containerView(),
            fromCellIndex = fromVC.collectionView?.indexPathForCell(fromCell)
            else {
                return
        }
        
        var toCellTmp = toVC.collectionView?.cellForItemAtIndexPath(fromCellIndex) as? AssetCell
        if toCellTmp == nil {
            // if toCell is not shown in collection view, scroll collection view to toCell index path.
            toVC.collectionView?.scrollToItemAtIndexPath(fromVC.currentIndexPath, atScrollPosition: .CenteredVertically, animated: false)
            toVC.collectionView?.layoutIfNeeded()
            toCellTmp = toVC.collectionView?.cellForItemAtIndexPath(fromCellIndex) as? AssetCell
        }
        
        guard let toCell = toCellTmp else {
            return
        }
        
        let contractingImageView = UIImageView(image: fromCell.imageView.image)
        contractingImageView.contentMode = toCell.imageView.contentMode
        contractingImageView.clipsToBounds = true
        contractingImageView.frame = Size.contractingAnimationFromCellRect(fromVC, fromCell: fromCell, contractingImageSize: contractingImageView.image!.size)

        containerView.addSubview(toVC.view)
        containerView.addSubview(contractingImageView)
        toVC.view.alpha = 0
        fromCell.alpha = 0
        toCell.alpha = 0
        
        UIView.animateWithDuration(
            transitionDuration(transitionContext),
            delay: 0,
            options: .CurveEaseInOut,
            animations: { () -> Void in
                toVC.view.alpha = 1
                contractingImageView.frame = Size.contractingAnimationToCellRect(toVC, toCell: toCell)
            }) { (_) -> Void in
                self.fromCell.alpha = 1
                toCell.alpha = 1
                contractingImageView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        }
        
    }
    
    
}