//
//  ActivityIndicatable.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/04/08.
//  Copyright © 2016年 nohana. All rights reserved.
//

public protocol ActivityIndicatable {
    func isProgressing() -> Bool
    func updateVisibilityOfActivityIndicator(activityIndicator: UIView)
}

public extension ActivityIndicatable where Self: UIViewController {
    func updateVisibilityOfActivityIndicator(activityIndicator: UIView) {
        if isProgressing() {
            if !view.subviews.contains(activityIndicator) {
                view.addSubview(activityIndicator)
            }
        } else {
            activityIndicator.removeFromSuperview()
        }
    }
}