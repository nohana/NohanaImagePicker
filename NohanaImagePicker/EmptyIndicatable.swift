//
//  EmptyIndicatable.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/03/23.
//  Copyright © 2016年 nohana. All rights reserved.
//

public protocol EmptyIndicatable {
    func isEmpty() -> Bool
    func updateVisibilityOfEmptyIndicator(emptyIndicator: UIView)
}

public extension EmptyIndicatable where Self: UIViewController {
    func updateVisibilityOfEmptyIndicator(emptyIndicator: UIView) {
        if isEmpty(){
            if !view.subviews.contains(emptyIndicator) {
                view.addSubview(emptyIndicator)
            }
        } else {
            emptyIndicator.removeFromSuperview()
        }
    }
}