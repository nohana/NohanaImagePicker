//
//  NohanaImagePickerController.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/09.
//  Copyright © 2016年 nohana. All rights reserved.
//

import UIKit
import Photos

public enum MediaType: Int {
    case Any = 0, Photo, Video
}

@available(iOS 8.0, *)
@objc public protocol NohanaImagePickerControllerDelegate {
    func nohanaImagePickerDidCancel(picker: NohanaImagePickerController)
    func nohanaImagePicker(picker: NohanaImagePickerController, didFinishPickingPhotoKitAssets pickedAssts :[PHAsset])
    optional func nohanaImagePicker(picker: NohanaImagePickerController, willPickPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) -> Bool
    optional func nohanaImagePicker(picker: NohanaImagePickerController, didPickPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int)
    optional func nohanaImagePicker(picker: NohanaImagePickerController, willDropPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) -> Bool
    optional func nohanaImagePicker(picker: NohanaImagePickerController, didDropPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int)
    optional func nohanaImagePicker(picker: NohanaImagePickerController, didSelectPhotoKitAsset asset: PHAsset)
    optional func nohanaImagePicker(picker: NohanaImagePickerController, didSelectPhotoKitAssetList assetList: PHAssetCollection)
    optional func nohanaImagePicker(picker: NohanaImagePickerController, assetListViewController: UICollectionViewController, cell: UICollectionViewCell, indexPath: NSIndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell
    optional func nohanaImagePicker(picker: NohanaImagePickerController, assetDetailListViewController: UICollectionViewController, cell: UICollectionViewCell, indexPath: NSIndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell
    optional func nohanaImagePicker(picker: NohanaImagePickerController, assetDetailListViewController: UICollectionViewController, didChangeAssetDetailPage indexPath: NSIndexPath, photoKitAsset: PHAsset)
    
}

@available(iOS 8.0, *)
public class NohanaImagePickerController: UIViewController {
    
    public var maximumNumberOfSelection: Int = 21 // set 0 to set no limit
    public var numberOfColumnsInPortrait: Int = 4
    public var numberOfColumnsInLandscape: Int = 7
    public weak var delegate: NohanaImagePickerControllerDelegate?
    public var shouldShowMoment: Bool = true
    public var shouldShowEmptyAlbum: Bool = false
    public var toolbarHidden: Bool = false
    public var canPickAsset = { (asset:AssetType) -> Bool in
        return true
    }
    lazy var assetBundle:NSBundle = NSBundle(forClass: self.dynamicType)
    let pickedAssetList: PickedAssetList
    let mediaType: MediaType
    private let assetCollectionSubtypes: [PHAssetCollectionSubtype]
    
    public init() {
        assetCollectionSubtypes = [
            .AlbumRegular,
            .AlbumSyncedEvent,
            .AlbumSyncedFaces,
            .AlbumSyncedAlbum,
            .AlbumImported,
            .AlbumMyPhotoStream,
            .AlbumCloudShared,
            .SmartAlbumGeneric,
            .SmartAlbumFavorites,
            .SmartAlbumRecentlyAdded,
            .SmartAlbumUserLibrary
        ]
        mediaType = .Photo
        pickedAssetList = PickedAssetList()
        super.init(nibName: nil, bundle: nil)
        self.pickedAssetList.nohanaImagePickerController = self
    }
    
    public init(assetCollectionSubtypes: [PHAssetCollectionSubtype], mediaType: MediaType) {
        self.assetCollectionSubtypes = assetCollectionSubtypes
        self.mediaType = mediaType
        pickedAssetList = PickedAssetList()
        super.init(nibName: nil, bundle: nil)
        self.pickedAssetList.nohanaImagePickerController = self
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // show albumListViewController
        let storyboard = UIStoryboard(name: "NohanaImagePicker", bundle: assetBundle)
        guard let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController else {
            fatalError("navigationController init failed.")
        }
        addChildViewController(navigationController)
        view.addSubview(navigationController.view)
        navigationController.didMoveToParentViewController(self)
        
        // setup albumListViewController
        guard let albumListViewController = navigationController.topViewController as? AlbumListViewController else {
            fatalError("albumListViewController is not topViewController.")
        }
        albumListViewController.photoKitAlbumList =
            PhotoKitAlbumList(
                assetCollectionTypes: [.SmartAlbum, .Album],
                assetCollectionSubtypes: assetCollectionSubtypes,
                mediaType: mediaType,
                shouldShowEmptyAlbum: shouldShowEmptyAlbum,
                handler: {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    albumListViewController.isLoading = false
                    albumListViewController.tableView.reloadData()
                })
            })
        albumListViewController.nohanaImagePickerController = self
    }
    
    public func pickAsset(asset: AssetType) {
        pickedAssetList.pickAsset(asset)
    }
    
    public func dropAsset(asset: AssetType) {
        pickedAssetList.dropAsset(asset)
    }
}

