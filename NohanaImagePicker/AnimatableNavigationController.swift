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

class AnimatableNavigationController: UINavigationController, UINavigationControllerDelegate {
    
    let swipeInteractionController = SwipeInteractionController()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
    }
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        switch operation {
        case .Push where fromVC is AssetListViewController:
            guard let fromVC = fromVC as? AssetListViewController,
            selectedIndex = fromVC.collectionView?.indexPathsForSelectedItems()?.first,
            fromCell = fromVC.collectionView?.cellForItemAtIndexPath(selectedIndex) as? AssetCell
            else {
                return nil
            }
            return ExpandingAnimationController(fromCell)
        case .Pop where toVC is AssetListViewController:
            guard let fromVC = fromVC as? AssetDetailListViewController,
            fromCell = fromVC.collectionView?.cellForItemAtIndexPath(NSIndexPath(forItem: fromVC.currentIndexPath.item, inSection: 0)) as? AssetDetailCell
            else {
                return nil
            }
            return ContractingAnimationController(fromCell)
        default:
            return nil
        }
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {        
        swipeInteractionController.attachToViewController(viewController)
    }
    
    func navigationController(navigationController: UINavigationController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if animationController is ExpandingAnimationController {
            return nil
        }
        if animationController is ContractingAnimationController {
            return nil
        }
        return swipeInteractionController
    }
    
}
