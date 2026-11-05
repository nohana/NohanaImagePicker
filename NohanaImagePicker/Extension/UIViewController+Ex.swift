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

extension UIViewController {

    // MARK: - Toolbar

    func setUpToolbarItems() {
        let leftSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let rightSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17)
        let labelItem = UIBarButtonItem(customView: label)
        self.toolbarItems = [leftSpace, labelItem, rightSpace]
    }

    func setToolbarTitle(_ nohanaImagePickerController: NohanaImagePickerController) {
        let count: Int? = toolbarItems?.count
        guard count != nil && count! >= 2 else {
            return
        }
        guard let labelItem = toolbarItems?[1], let titleLabel = labelItem.customView as? UILabel else {
            return
        }
        if nohanaImagePickerController.maximumNumberOfSelection == 0 {
            let title = String(format: nohanaImagePickerController.config.strings.toolbarTitleNoLimit ?? NSLocalizedString("toolbar.title.nolimit", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: ""),
                nohanaImagePickerController.pickedAssetList.count)
            titleLabel.text = title
            titleLabel.sizeToFit()
        } else {
            let title = String(format: nohanaImagePickerController.config.strings.toolbarTitleHasLimit ?? NSLocalizedString("toolbar.title.haslimit", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: ""),
                nohanaImagePickerController.pickedAssetList.count,
                nohanaImagePickerController.maximumNumberOfSelection)
            titleLabel.text = title
            titleLabel.sizeToFit()
        }
    }
    
    func toolBarAppearance(_ nohanaImagePickerController: NohanaImagePickerController) -> UIToolbarAppearance {
        let appearance = UIToolbarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = nohanaImagePickerController.config.color.navigationBarBackground
        return appearance
    }
    
    // MARK: UINavigationBarAppearance
    func navigationBarAppearance(_ nohanaImagePickerController: NohanaImagePickerController) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = nohanaImagePickerController.config.color.navigationBarBackground
        appearance.titleTextAttributes =  [
            .foregroundColor: nohanaImagePickerController.config.color.navigationBarForeground,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        let donebuttonAppearance = UIBarButtonItemAppearance()
        donebuttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: nohanaImagePickerController.config.color.navigationBarForeground,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.doneButtonAppearance = donebuttonAppearance
        return appearance
    }

    // MARK: - Notification

    func addPickPhotoKitAssetNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(AlbumListViewController.didPickPhotoKitAsset(_:)), name: NotificationInfo.Asset.PhotoKit.didPick, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AlbumListViewController.didDropPhotoKitAsset(_:)), name:  NotificationInfo.Asset.PhotoKit.didDrop, object: nil)
    }

    @objc func didPickPhotoKitAsset(_ notification: Notification) {
        guard let picker = notification.object as? NohanaImagePickerController else {
            return
        }
        setToolbarTitle(picker)
    }

    @objc func didDropPhotoKitAsset(_ notification: Notification) {
        guard let picker = notification.object as? NohanaImagePickerController else {
            return
        }
        setToolbarTitle(picker)
    }
}
