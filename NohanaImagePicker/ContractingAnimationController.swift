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

import AVFoundation

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

class ContractingAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    var fromCell: AssetDetailCell
    
    init(_ fromCell: AssetDetailCell) {
        self.fromCell = fromCell
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as? AssetDetailListViewController,
            toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as? AssetListViewController
            else {
                return
        }
        
        var toCellTmp = toVC.collectionView?.cellForItemAtIndexPath(fromVC.currentIndexPath) as? AssetCell
        if toCellTmp == nil {
            // if toCell is not shown in collection view, scroll collection view to toCell index path.
            toVC.collectionView?.scrollToItemAtIndexPath(fromVC.currentIndexPath, atScrollPosition: .CenteredVertically, animated: false)
            toVC.collectionView?.layoutIfNeeded()
            toCellTmp = toVC.collectionView?.cellForItemAtIndexPath(fromVC.currentIndexPath) as? AssetCell
        }
        
        guard let toCell = toCellTmp else {
            return
        }
        
        let contractingImageView = UIImageView(image: fromCell.imageView.image)
        contractingImageView.contentMode = toCell.imageView.contentMode
        contractingImageView.clipsToBounds = true
        contractingImageView.frame = Size.contractingAnimationFromCellRect(fromVC, fromCell: fromCell, contractingImageSize: contractingImageView.image!.size)

        let containerView = transitionContext.containerView()
        containerView.addSubview(toVC.view)
        containerView.addSubview(contractingImageView)
        toVC.view.alpha = 0
        fromCell.alpha = 0
        toCell.alpha = 0
        
        UIView.animateWithDuration(
            transitionDuration(transitionContext),
            delay: 0,
            options: .CurveEaseInOut,
            animations: { _ in
                toVC.view.alpha = 1
                contractingImageView.frame = Size.contractingAnimationToCellRect(toVC, toCell: toCell)
            }) { _  in
                self.fromCell.alpha = 1
                toCell.alpha = 1
                contractingImageView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        }
        
    }
    
    
}
