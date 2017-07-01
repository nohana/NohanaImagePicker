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

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        switch operation {
        case .push where fromVC is AssetListViewController:
            guard let fromVC = fromVC as? AssetListViewController,
            let selectedIndex = fromVC.collectionView?.indexPathsForSelectedItems?.first,
            let fromCell = fromVC.collectionView?.cellForItem(at: selectedIndex) as? AssetCell
            else {
                return nil
            }
            return ExpandingAnimationController(fromCell)
        case .pop where toVC is AssetListViewController:
            guard let fromVC = fromVC as? AssetDetailListViewController,
            let fromCell = fromVC.collectionView?.cellForItem(at: IndexPath(item: fromVC.currentIndexPath.item, section: 0)) as? AssetDetailCell
            else {
                return nil
            }
            return ContractingAnimationController(fromCell)
        default:
            return nil
        }
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        swipeInteractionController.attachToViewController(viewController)
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if animationController is ExpandingAnimationController {
            return nil
        }
        if animationController is ContractingAnimationController {
            return nil
        }
        return swipeInteractionController
    }

}
