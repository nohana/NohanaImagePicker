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

import Foundation

class PickedAssetList: ItemList {

    var assetlist: Array<Asset> = []
    weak var nohanaImagePickerController: NohanaImagePickerController?

    // MARK: - ItemList

    typealias Item = Asset

    var title: String {
        return "Selected Assets"
    }

    func update(_ handler:(() -> Void)?) {
        fatalError("not supported")
    }

    subscript (index: Int) -> Item {
        return assetlist[index]
    }

    // MARK: - CollectionType

    var startIndex: Int {
        return 0
    }

    var endIndex: Int {
        return assetlist.count
    }

    // MARK: - Manage assetlist

    func pick(asset: Asset) -> Bool {
        guard !isPicked(asset) else {
            return false
        }
        let assetsCountBeforePicking = self.count
        if asset is PhotoKitAsset {
            if let canPick = nohanaImagePickerController!.delegate?.nohanaImagePicker?(nohanaImagePickerController!, willPickPhotoKitAsset: (asset as! PhotoKitAsset).originalAsset, pickedAssetsCount: assetsCountBeforePicking), !canPick {
                return false
            }
        }
        guard nohanaImagePickerController!.maximumNumberOfSelection == 0 || assetsCountBeforePicking < nohanaImagePickerController!.maximumNumberOfSelection else {
            return false
        }
        assetlist.append(asset)
        let assetsCountAfterPicking = self.count
        if asset is PhotoKitAsset {
            let originalAsset = (asset as! PhotoKitAsset).originalAsset
            nohanaImagePickerController!.delegate?.nohanaImagePicker?(nohanaImagePickerController!, didPickPhotoKitAsset: originalAsset, pickedAssetsCount: assetsCountAfterPicking)
            NotificationCenter.default.post(
                Notification(
                    name: NotificationInfo.Asset.PhotoKit.didPick,
                    object: nohanaImagePickerController,
                    userInfo: [
                        NotificationInfo.Asset.PhotoKit.didPickUserInfoKeyAsset : originalAsset,
                        NotificationInfo.Asset.PhotoKit.didPickUserInfoKeyPickedAssetsCount : assetsCountAfterPicking
                    ]
                )
            )
        }
        return true

    }

    func drop(asset: Asset) -> Bool {
        let assetsCountBeforeDropping = self.count
        if asset is PhotoKitAsset {
            if let canDrop = nohanaImagePickerController!.delegate?.nohanaImagePicker?(nohanaImagePickerController!, willDropPhotoKitAsset: (asset as! PhotoKitAsset).originalAsset, pickedAssetsCount: assetsCountBeforeDropping), !canDrop {
                return false
            }
        }
        assetlist = assetlist.filter { $0.identifier != asset.identifier }
        let assetsCountAfterDropping = self.count
        if asset is PhotoKitAsset {
            let originalAsset = (asset as! PhotoKitAsset).originalAsset
            nohanaImagePickerController!.delegate?.nohanaImagePicker?(nohanaImagePickerController!, didDropPhotoKitAsset: originalAsset, pickedAssetsCount: assetsCountAfterDropping)
            NotificationCenter.default.post(
                Notification(
                    name: NotificationInfo.Asset.PhotoKit.didDrop,
                    object: nohanaImagePickerController,
                    userInfo: [
                        NotificationInfo.Asset.PhotoKit.didDropUserInfoKeyAsset : originalAsset,
                        NotificationInfo.Asset.PhotoKit.didDropUserInfoKeyPickedAssetsCount : assetsCountAfterDropping
                    ]
                )
            )
        }
        return true
    }

    func isPicked(_ asset: Asset) -> Bool {
        return assetlist.contains { $0.identifier == asset.identifier }
    }

}
