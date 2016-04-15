//
//  ItemListType.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/14.
//  Copyright © 2016年 nohana. All rights reserved.
//

public protocol ItemListType: CollectionType {
    typealias Item
    var title:String { get }
    func update(handler:(() -> Void)?)
    subscript (index: Int) -> Item { get }
}

public protocol AssetType {
    var identifier:Int { get }
    func image(targetSize:CGSize, handler: (ImageData?) -> Void)
}

public struct ImageData {
    public var image: UIImage
    public var info: Dictionary<NSObject, AnyObject>?
}