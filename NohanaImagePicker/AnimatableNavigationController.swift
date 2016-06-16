//
//  AnimatableNavigationController.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/14.
//  Copyright © 2016年 nohana. All rights reserved.
//

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
