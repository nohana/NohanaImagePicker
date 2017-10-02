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

    static func expandingAnimationFromCellRect(_ fromVC: AssetListViewController, fromCell: AssetCell) -> CGRect {
        let origin = CGPoint(x: fromCell.frame.origin.x, y: fromCell.frame.origin.y - fromVC.collectionView!.contentOffset.y)
        return CGRect(origin: origin, size: fromCell.frame.size)
    }

    static func expandingAnimationToCellRect(_ fromVC: UIViewController, toSize: CGSize) -> CGRect {
        return AVMakeRect(aspectRatio: toSize, insideRect: Size.screenRectWithoutAppBar(fromVC))
    }
}

class ExpandingAnimationController: NSObject, UIViewControllerAnimatedTransitioning {

    var fromCell: AssetCell

    init(_ fromCell: AssetCell) {
        self.fromCell = fromCell
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? AssetListViewController,
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? AssetDetailListViewController
            else {
                return
        }

        let expandingImageView = UIImageView(image: fromCell.imageView.image)
        expandingImageView.contentMode = fromCell.imageView.contentMode
        expandingImageView.clipsToBounds = true
        expandingImageView.frame = Size.expandingAnimationFromCellRect(fromVC, fromCell: fromCell)

        transitionContext.containerView.addSubview(toVC.view)
        transitionContext.containerView.addSubview(expandingImageView)
        toVC.view.alpha = 0
        toVC.collectionView?.isHidden = true
        toVC.view.backgroundColor = UIColor.black
        fromCell.alpha = 0

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 10,
            options: .curveEaseOut,
            animations: { () -> Void in
                toVC.view.alpha = 1
                expandingImageView.frame = Size.expandingAnimationToCellRect(fromVC, toSize: expandingImageView.image!.size)
            }) { (_) -> Void in
                self.fromCell.alpha = 1
                toVC.collectionView?.isHidden = false
                expandingImageView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

}
