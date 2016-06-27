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

    static func expandingAnimationFromCellRect(fromVC: AssetListViewController, fromCell: AssetCell) -> CGRect {
        let origin = CGPoint(x: fromCell.frame.origin.x, y: fromCell.frame.origin.y - fromVC.collectionView!.contentOffset.y)
        return CGRect(origin: origin, size: fromCell.frame.size)
    }
    
    static func expandingAnimationToCellRect(fromVC: UIViewController, toSize:CGSize) -> CGRect {
        return AVMakeRectWithAspectRatioInsideRect(toSize, Size.screenRectWithoutAppBar(fromVC))
    }
}

class ExpandingAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    var fromCell: AssetCell
    
    init(_ fromCell: AssetCell) {
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
        toVC.collectionView?.alpha = 0
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
                toVC.collectionView?.alpha = 1
                expandingImageView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        }
    }
    
}

