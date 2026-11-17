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
import Photos

public enum MediaType: Int, Sendable {
    case any = 0, photo, video
}

@objc public protocol NohanaImagePickerControllerDelegate {
    func nohanaImagePickerDidCancel(_ picker: NohanaImagePickerController)
    func nohanaImagePicker(_ picker: NohanaImagePickerController, didFinishPickingPhotoKitAssets pickedAssts: [PHAsset])
    @objc optional func nohanaImagePicker(_ picker: NohanaImagePickerController, willPickPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) -> Bool
    @objc optional func nohanaImagePicker(_ picker: NohanaImagePickerController, didPickPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int)
    @objc optional func nohanaImagePicker(_ picker: NohanaImagePickerController, willDropPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) -> Bool
    @objc optional func nohanaImagePicker(_ picker: NohanaImagePickerController, didDropPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int)
    @objc optional func nohanaImagePicker(_ picker: NohanaImagePickerController, didSelectPhotoKitAsset asset: PHAsset)
    @objc optional func nohanaImagePicker(_ picker: NohanaImagePickerController, didSelectAssetDateSectionAssets assets: [PHAsset], date: Date?)
    @objc optional func nohanaImagePicker(_ picker: NohanaImagePickerController, didSelectPhotoKitAssetList assetList: AssetCollection)
    @objc optional func nohanaImagePickerDidSelectMoment(_ picker: NohanaImagePickerController) -> Void
    @objc optional func nohanaImagePicker(_ picker: NohanaImagePickerController, assetListViewController: UICollectionViewController, cell: UICollectionViewCell, indexPath: IndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell
    @objc optional func nohanaImagePicker(_ picker: NohanaImagePickerController, assetDetailListViewController: UICollectionViewController, cell: UICollectionViewCell, indexPath: IndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell
    @objc optional func nohanaImagePicker(_ picker: NohanaImagePickerController, assetDetailListViewController: UICollectionViewController, didChangeAssetDetailPage indexPath: IndexPath, photoKitAsset: PHAsset)
    @objc optional func nohanaImagePickerDidTapAddPhotoButton(_ picker: NohanaImagePickerController)
    @objc optional func nohanaImagePickerDidTapAuthorizeAllPhotoButton(_ picker: NohanaImagePickerController)
}

open class NohanaImagePickerController: UIViewController {

    open var maximumNumberOfSelection: Int = 21 // set 0 to no limit
    open var numberOfColumnsInPortrait: Int = 4
    open var numberOfColumnsInLandscape: Int = 7
    open weak var delegate: NohanaImagePickerControllerDelegate?
    open var shouldShowMoment: Bool = true
    open var shouldShowEmptyAlbum: Bool = false
    open var toolbarHidden: Bool = false
    open var canPickAsset = { (asset: Asset) -> Bool in
        return true
    }
    open var config: Config = Config()
    open var canPickDateSection: Bool = false
    open var titleTextAttributes: [NSAttributedString.Key: Any] = {
        return [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
    }()
    open var isHiddenPhotoAuthorizationLimitedView: Bool = false
    lazy var assetBundle: Bundle = {
        #if SWIFT_PACKAGE
            return Bundle.module
        #else
            let bundle = Bundle(for: type(of: self))
            if let path = bundle.path(forResource: "NohanaImagePicker", ofType: "bundle") {
                return Bundle(path: path)!
            }
            return bundle
        #endif
    }()
    let pickedAssetList: PickedAssetList
    let thumbnailLoader = ThumbnailLoader()
    let mediaType: MediaType
    /// On iOS 18+, the detail page zooms out of the tapped photo and back into the photo shown when going back.
    /// Before iOS 18 the standard push and pop are used, and also in a sheet when built with the iOS 27 SDK, where
    /// the zoom hides the sheet.
    let enableExpandingPhotoAnimation: Bool
    let assetCollectionSubtypes: [PHAssetCollectionSubtype]
    let defaultAssetCollection: AssetCollection?
    let customAssetCollection: CustomAssetCollection?

    public init() {
        assetCollectionSubtypes = [
            .albumRegular,
            .albumSyncedEvent,
            .albumSyncedFaces,
            .albumSyncedAlbum,
            .albumImported,
            .albumMyPhotoStream,
            .albumCloudShared,
            .smartAlbumGeneric,
            .smartAlbumFavorites,
            .smartAlbumRecentlyAdded,
            .smartAlbumUserLibrary
        ]
        mediaType = .photo
        pickedAssetList = PickedAssetList()
        enableExpandingPhotoAnimation = true
        defaultAssetCollection = nil
        customAssetCollection = nil
        super.init(nibName: nil, bundle: nil)
        self.pickedAssetList.nohanaImagePickerController = self
    }

    public init(assetCollectionSubtypes: [PHAssetCollectionSubtype], mediaType: MediaType, enableExpandingPhotoAnimation: Bool, defaultAssetCollection: AssetCollection?, customAssetCollection: CustomAssetCollection? = nil) {
        self.assetCollectionSubtypes = assetCollectionSubtypes
        self.mediaType = mediaType
        self.enableExpandingPhotoAnimation = enableExpandingPhotoAnimation
        self.defaultAssetCollection = defaultAssetCollection
        self.customAssetCollection = customAssetCollection
        if let assetCollection = self.defaultAssetCollection as? PHAssetCollection {
            if !assetCollectionSubtypes.contains(assetCollection.assetCollectionSubtype) {
                fatalError("defaultAssetCollection doesn't contain the specified PHAssetCollectionSubtype")
            }
        }
        pickedAssetList = PickedAssetList()
        super.init(nibName: nil, bundle: nil)
        self.pickedAssetList.nohanaImagePickerController = self
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        // show rootViewController
        let storyboard = UIStoryboard(name: "NohanaImagePicker", bundle: assetBundle)
        let rootViewController = storyboard.instantiateViewController(identifier: "RootViewController", creator: { coder in
            RootViewController(coder: coder, nohanaImagePickerController: self)
        })
        let navigationController = UINavigationController(rootViewController: rootViewController)

        let navigationBarAppearance = navigationBarAppearance(self)
        navigationController.navigationBar.standardAppearance = navigationBarAppearance
        navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        navigationController.navigationBar.compactAppearance = navigationBarAppearance
        navigationController.navigationBar.tintColor = config.color.navigationBarForeground
        
        let toobarAppearance = toolBarAppearance(self)
        navigationController.toolbar.standardAppearance = toobarAppearance
        navigationController.toolbar.scrollEdgeAppearance = toobarAppearance
        navigationController.toolbar.compactAppearance = toobarAppearance
        navigationController.toolbar.tintColor = config.color.navigationBarForeground
        
        addChild(navigationController)
        view.addSubview(navigationController.view)
        NSLayoutConstraint.activate([
            navigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            navigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        navigationController.view.layoutIfNeeded()
        navigationController.didMove(toParent: self)
    }

    open func pickAsset(_ asset: Asset) {
        _ = pickedAssetList.pick(asset: asset)
    }

    open func dropAsset(_ asset: Asset) {
        _ = pickedAssetList.drop(asset: asset)
    }
}

extension NohanaImagePickerController {
    public struct Config {
        public struct Color {
            public var background: UIColor?
            public var empty: UIColor?
            public var separator: UIColor?
            /// The background of the navigation bar and the toolbar. When nil, the bars have no background on iOS 26+
            /// (Liquid Glass) and are the system background (white in light mode) on earlier versions. On iOS 26+ the
            /// system does not draw a toolbar background, so only the navigation bar uses this color.
            public var navigationBarBackground: UIColor?
            public var navigationBarForeground: UIColor = .label
            /// The done button. Before iOS 26 it is the title color; on iOS 26+ it is the fill color of the button.
            public var navigationBarDoneBarButtonItem: UIColor = .label
        }
        public var color = Color()

        public struct Image {
            public var pickedSmall: UIImage?
            public var pickedLarge: UIImage?
            public var droppedSmall: UIImage?
            public var droppedLarge: UIImage?
        }
        public var image = Image()

        public struct Strings {
            public var albumListTitle: String?
            public var albumListMomentTitle: String?
            public var albumListEmptyMessage: String?
            public var albumListEmptyDescription: String?
            public var albumListEmptyAlertButtonOK: String?
            public var toolbarTitleNoLimit: String?
            public var toolbarTitleHasLimit: String?
        }
        public var strings = Strings()
    }
}
