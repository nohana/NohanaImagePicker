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
import NohanaImagePicker
import Photos
import PhotosUI

struct Cell {
    let title: String
    let selector: Selector
}

class DemoListViewController: UITableViewController, NohanaImagePickerControllerDelegate {

    let cells = [
        Cell(title: "Default", selector: #selector(DemoListViewController.showDefaultPicker)),
        Cell(title: "Large thumbnail", selector: #selector(DemoListViewController.showLargeThumbnailPicker)),
        Cell(title: "No toolbar", selector: #selector(DemoListViewController.showNoToolbarPicker)),
        Cell(title: "Disable to pick assets", selector: #selector(DemoListViewController.showDisableToPickAssetsPicker)),
        Cell(title: "Custom UI", selector: #selector(DemoListViewController.showCustomUIPicker)),
        Cell(title: "Selectable Album Date Section", selector: #selector(DemoListViewController.showSelectableDateSectionPicker)),
        Cell(title: "Specify the default album", selector: #selector(DemoListViewController.showSpecifyDefaultAlbumPicker)),
    ]

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = cells[indexPath.row].title
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        checkIfAuthorizedToAccessPhotos { isAuthorized in
            DispatchQueue.main.async(execute: {
                if isAuthorized {
                    self.perform(self.cells[indexPath.row].selector)
                } else {
                    let alert = UIAlertController(title: "Error", message: "Denied access to photos.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            })
        }
    }

    // MARK: - Photos

    func checkIfAuthorizedToAccessPhotos(_ handler: @escaping (_ isAuthorized: Bool) -> Void) {
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        handler(true)
                    default:
                        handler(false)
                    }
                }
            }
        case .restricted:
            handler(false)
        case .denied:
            handler(false)
        case .authorized:
            handler(true)
        case .limited:
            handler(true)
        @unknown default:
            fatalError()
        }
    }

    // MARK: - Show NohanaImagePicker

    @objc func showDefaultPicker() {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    @objc func showLargeThumbnailPicker() {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        picker.numberOfColumnsInPortrait = 2
        picker.numberOfColumnsInLandscape = 3
        present(picker, animated: true, completion: nil)
    }

    @objc func showNoToolbarPicker() {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        picker.toolbarHidden = true
        present(picker, animated: true, completion: nil)
    }

    @objc func showDisableToPickAssetsPicker() {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        picker.canPickAsset = { (asset: Asset) -> Bool in
            return asset.identifier % 2 == 0
        }
        present(picker, animated: true, completion: nil)
    }

    @objc func showCustomUIPicker() {
        let picker = NohanaImagePickerController()
        picker.delegate = self
        picker.config.color.background = UIColor(red: 0xcc/0xff, green: 0xff/0xff, blue: 0xff/0xff, alpha: 1)
        picker.config.color.separator = UIColor(red: 0x00/0xff, green: 0x66/0xff, blue: 0x66/0xff, alpha: 1)
        picker.config.strings.albumListTitle = "🏞"
        picker.config.image.droppedSmall = UIImage(named: "btn_select_m")
        picker.config.image.pickedSmall = UIImage(named: "btn_selected_m")
        present(picker, animated: true, completion: nil)
    }

    @objc func showSelectableDateSectionPicker() {
        let picker = NohanaImagePickerController()
        picker.canPickDateSection = true
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    @objc func showSpecifyDefaultAlbumPicker() {
        let subtypes: [PHAssetCollectionSubtype] = [
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
        var albumListFetchResult: [PHFetchResult<PHAssetCollection>] = []
        let assetCollectionTypes: [PHAssetCollectionType] = [.smartAlbum, .album]
        assetCollectionTypes.forEach {
            albumListFetchResult += [PHAssetCollection.fetchAssetCollections(with: $0, subtype: .any, options: nil)]
        }
        var assetCollections: [PHAssetCollection] = []
        albumListFetchResult.forEach {
            $0.enumerateObjects { (assetCollection, _, _) in
                if subtypes.contains(assetCollection.assetCollectionSubtype) {
                    assetCollections.append(assetCollection)
                }
            }
        }
        let picker = NohanaImagePickerController(assetCollectionSubtypes: subtypes, mediaType: .photo, enableExpandingPhotoAnimation: false, defaultAssetCollection: assetCollections.last)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    // MARK: - NohanaImagePickerControllerDelegate

    func nohanaImagePickerDidCancel(_ picker: NohanaImagePickerController) {
        print("🐷Canceled🙅")
        picker.dismiss(animated: true, completion: nil)
    }

    func nohanaImagePicker(_ picker: NohanaImagePickerController, didFinishPickingPhotoKitAssets pickedAssts: [PHAsset]) {
        print("🐷Completed🙆\n\tpickedAssets = \(pickedAssts)")
        picker.dismiss(animated: true, completion: nil)
    }

    func nohanaImagePicker(_ picker: NohanaImagePickerController, willPickPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) -> Bool {
        print("🐷\(#function)\n\tasset = \(asset)\n\tpickedAssetsCount = \(pickedAssetsCount)")
        return true
    }

    func nohanaImagePicker(_ picker: NohanaImagePickerController, didPickPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) {
        print("🐷\(#function)\n\tasset = \(asset)\n\tpickedAssetsCount = \(pickedAssetsCount)")
    }

    func nohanaImagePicker(_ picker: NohanaImagePickerController, willDropPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) -> Bool {
        print("🐷\(#function)\n\tasset = \(asset)\n\tpickedAssetsCount = \(pickedAssetsCount)")
        return true
    }

    func nohanaImagePicker(_ picker: NohanaImagePickerController, didDropPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) {
        print("🐷\(#function)\n\tasset = \(asset)\n\tpickedAssetsCount = \(pickedAssetsCount)")
    }

    func nohanaImagePicker(_ picker: NohanaImagePickerController, didSelectPhotoKitAsset asset: PHAsset) {
        print("🐷\(#function)\n\tasset = \(asset)\n\t")
    }
    
    func nohanaImagePicker(_ picker: NohanaImagePickerController, didSelectAssetDateSectionAssets assets: [PHAsset], date: Date?) {
        print("🐷\(#function)\n\tasset = \(assets)\n\tDate = \(String(describing: date))")
    }

    func nohanaImagePicker(_ picker: NohanaImagePickerController, didSelectPhotoKitAssetList assetList: PHAssetCollection) {
        print("🐷\(#function)\n\t\tassetList = \(assetList)\n\t")
    }

    func nohanaImagePickerDidSelectMoment(_ picker: NohanaImagePickerController) -> Void {
        print("🐷\(#function)")
    }

    func nohanaImagePicker(_ picker: NohanaImagePickerController, assetListViewController: UICollectionViewController, cell: UICollectionViewCell, indexPath: IndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell {
        print("🐷\(#function)\n\tindexPath = \(indexPath)\n\tphotoKitAsset = \(photoKitAsset)")
        return cell
    }

    func nohanaImagePicker(_ picker: NohanaImagePickerController, assetDetailListViewController: UICollectionViewController, cell: UICollectionViewCell, indexPath: IndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell {
        print("🐷\(#function)\n\tindexPath = \(indexPath)\n\tphotoKitAsset = \(photoKitAsset)")
        return cell
    }

    func nohanaImagePicker(_ picker: NohanaImagePickerController, assetDetailListViewController: UICollectionViewController, didChangeAssetDetailPage indexPath: IndexPath, photoKitAsset: PHAsset) {
        print("🐷\(#function)\n\tindexPath = \(indexPath)")
    }

    func nohanaImagePickerDidTapAddPhotoButton(_ picker: NohanaImagePickerController) {
        print("🐷\(#function)")
        if #available(iOS 14, *) {
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: picker)
        }
    }

    func nohanaImagePickerDidTapAuthorizeAllPhotoButton(_ picker: NohanaImagePickerController) {
        print("🐷\(#function)")
        guard let url = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(url) else {
                assertionFailure("Not able to open App privacy settings")
                return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
