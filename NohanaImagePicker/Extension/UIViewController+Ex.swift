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

        // A plain title item instead of UIBarButtonItem(customView: UILabel), which leaks on iOS 27 (#171).
        // Do not set isEnabled = false, because the title is then rendered greyed out.
        let labelItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        labelItem.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 17)], for: .normal)
        #if compiler(>=6.2) // The iOS 26 SDK
        if #available(iOS 26.0, *) {
            // Show the count as text, not as a glass button. Without the glass the text is drawn on the content,
            // which is black in the detail pages.
            labelItem.hidesSharedBackground = true
            if self is DetailListViewControllerProtocol {
                labelItem.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 17)], for: .normal)
            }
        }
        #endif
        self.toolbarItems = [leftSpace, labelItem, rightSpace]
    }

    func setToolbarTitle(_ nohanaImagePickerController: NohanaImagePickerController) {
        let count: Int? = toolbarItems?.count
        guard count != nil && count! >= 2 else {
            return
        }
        guard let labelItem = toolbarItems?[1] else {
            return
        }
        if nohanaImagePickerController.maximumNumberOfSelection == 0 {
            let title = String(format: nohanaImagePickerController.config.strings.toolbarTitleNoLimit ?? NSLocalizedString("toolbar.title.nolimit", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: ""),
                nohanaImagePickerController.pickedAssetList.count)
            labelItem.title = title
        } else {
            let title = String(format: nohanaImagePickerController.config.strings.toolbarTitleHasLimit ?? NSLocalizedString("toolbar.title.haslimit", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: ""),
                nohanaImagePickerController.pickedAssetList.count,
                nohanaImagePickerController.maximumNumberOfSelection)
            labelItem.title = title
        }
    }
    
    func toolBarAppearance(_ nohanaImagePickerController: NohanaImagePickerController) -> UIToolbarAppearance {
        let appearance = UIToolbarAppearance()
        if let backgroundColor = barBackgroundColor(nohanaImagePickerController) {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
        } else {
            appearance.configureWithDefaultBackground()
        }
        return appearance
    }
    
    // MARK: UINavigationBarAppearance
    func navigationBarAppearance(_ nohanaImagePickerController: NohanaImagePickerController) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        if let backgroundColor = barBackgroundColor(nohanaImagePickerController) {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
        } else {
            appearance.configureWithDefaultBackground()
        }
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

    // On iOS 26+ the bars have no background by default (Liquid Glass), so the photos can scroll under them.
    // Before iOS 26 the bars stay white as in earlier versions. A color set by the app is used on every version.
    private func barBackgroundColor(_ nohanaImagePickerController: NohanaImagePickerController) -> UIColor? {
        if let backgroundColor = nohanaImagePickerController.config.color.navigationBarBackground {
            return backgroundColor
        }
        if #available(iOS 26.0, *) {
            return nil
        }
        return .white
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
