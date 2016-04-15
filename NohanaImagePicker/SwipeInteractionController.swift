//
//  SwipeInteractionController.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/21.
//  Copyright © 2016年 nohana. All rights reserved.
//

import UIKit

@available(iOS 8.0, *)
class SwipeInteractionController: UIPercentDrivenInteractiveTransition {
    
    var viewController: UIViewController?
    
    func attachToViewController(viewController: UIViewController) {
        guard viewController.navigationController?.viewControllers.count > 1 else {
            return
        }
        let target = viewController.navigationController?.valueForKey("_cachedInteractionController")
        let gesture = UIScreenEdgePanGestureRecognizer(target: target, action: "handleNavigationTransition:")
        gesture.edges = .Left
        viewController.view.addGestureRecognizer(gesture)
    }
}