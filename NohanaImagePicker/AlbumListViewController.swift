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

class AlbumListViewController: UITableViewController, EmptyIndicatable, ActivityIndicatable {

    enum AlbumListViewControllerSectionType: Int {
        case moment = 0
        case albums

        static func count() -> Int {
            var count: Int = 0
            for i in 0..<Int.max {
                guard AlbumListViewControllerSectionType(rawValue: i) != nil else {
                    break
                }
                count = count + 1
            }
            return count
        }
    }

    weak var nohanaImagePickerController: NohanaImagePickerController?
    var photoKitAlbumList: PhotoKitAlbumList!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let nohanaImagePickerController = nohanaImagePickerController {
            view.backgroundColor = nohanaImagePickerController.config.color.background ?? .white
            title = nohanaImagePickerController.config.strings.albumListTitle ?? NSLocalizedString("albumlist.title", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
            setUpToolbarItems()
            navigationController?.setToolbarHidden(nohanaImagePickerController.toolbarHidden, animated: false)
        }
        setUpEmptyIndicator()
        setUpActivityIndicator()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nohanaImagePickerController = nohanaImagePickerController {
            setToolbarTitle(nohanaImagePickerController)
        }
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.reloadData()
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sectionType = AlbumListViewControllerSectionType(rawValue: indexPath.section) else {
            fatalError("Invalid section")
        }
        guard let nohanaImagePickerController = nohanaImagePickerController else {
            return
        }
        switch sectionType {
        case .moment:
            nohanaImagePickerController.delegate?.nohanaImagePickerDidSelectMoment?(nohanaImagePickerController)
        case .albums:
            nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didSelectPhotoKitAssetList: photoKitAlbumList[indexPath.row].assetList)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let sectionType = AlbumListViewControllerSectionType(rawValue: indexPath.section) else {
            fatalError("Invalid section")
        }
        switch sectionType {
        case .moment:
            return 52
        case .albums:
            return 82
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return AlbumListViewControllerSectionType.count()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let emptyIndicator = emptyIndicator {
            updateVisibilityOfEmptyIndicator(emptyIndicator)
        }
        if let activityIndicator = activityIndicator {
            updateVisibilityOfActivityIndicator(activityIndicator)
        }

        guard let sectionType = AlbumListViewControllerSectionType(rawValue: section) else {
            fatalError("Invalid section")
        }

        switch sectionType {
        case .moment:
            if let nohanaImagePickerController = nohanaImagePickerController {
                return nohanaImagePickerController.shouldShowMoment ? 1 : 0
            }
            return 0

        case .albums:
            return photoKitAlbumList.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = AlbumListViewControllerSectionType(rawValue: indexPath.section) else {
            fatalError("Invalid section")
        }

        switch sectionType {
        case .moment:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "MomentAlbumCell") as? MomentCell else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"MomentAlbumCell\")")
            }
            if let nohanaImagePickerController = nohanaImagePickerController {
                cell.config = nohanaImagePickerController.config
                cell.titleLabel?.text = nohanaImagePickerController.config.strings.albumListMomentTitle ?? NSLocalizedString("albumlist.moment.title", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
            }
            return cell
        case .albums:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumCell") as? AlbumCell else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"AlbumCell\")")
            }
            let albumList = photoKitAlbumList[indexPath.row]
            cell.titleLabel.text = albumList.title
            cell.tag = indexPath.row
            let imageSize = CGSize(
                width: cell.thumbnailImageView.frame.size.width * UIScreen.main.scale,
                height: cell.thumbnailImageView.frame.size.width * UIScreen.main.scale
            )
            let albumCount = albumList.count
            if albumCount > 0 {
                let lastAsset = albumList[albumCount - 1]
                lastAsset.image(targetSize: imageSize, handler: { (imageData) -> Void in
                    DispatchQueue.main.async(execute: { () -> Void in
                        if let imageData = imageData {
                            if cell.tag == indexPath.row {
                                cell.thumbnailImageView.image = imageData.image
                            }
                        }
                    })
                })
            } else {
                cell.thumbnailImageView.image = nil
            }
            return cell
        }
    }

    // MARK: - Storyboard

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let sectionType = AlbumListViewControllerSectionType(rawValue: tableView.indexPathForSelectedRow!.section) else {
            fatalError("Invalid section")
        }
        switch sectionType {
        case .moment:
            let momentViewController = segue.destination as! MomentViewController
            momentViewController.nohanaImagePickerController = nohanaImagePickerController
            momentViewController.momentAlbumList = PhotoKitAlbumList(
                assetCollectionTypes: [.moment],
                assetCollectionSubtypes: [.any],
                mediaType: nohanaImagePickerController!.mediaType,
                shouldShowEmptyAlbum: nohanaImagePickerController!.shouldShowEmptyAlbum,
                handler: { () -> Void in
                    DispatchQueue.main.async(execute: { [weak momentViewController] in
                        momentViewController?.isLoading = false
                        momentViewController?.collectionView?.reloadData()
                        momentViewController?.isFirstAppearance = true
                        momentViewController?.scrollCollectionViewToInitialPosition()
                    })
            })
        case .albums:
            let assetListViewController = segue.destination as! AssetListViewController
            assetListViewController.photoKitAssetList = photoKitAlbumList[tableView.indexPathForSelectedRow!.row]
            assetListViewController.nohanaImagePickerController = nohanaImagePickerController
        }
    }

    // MARK: - IBAction

    @IBAction func didPushCancel(_ sender: AnyObject) {
        if let nohanaImagePickerController = nohanaImagePickerController {
            nohanaImagePickerController.delegate?.nohanaImagePickerDidCancel(nohanaImagePickerController)
        }
    }

    // MARK: - EmptyIndicatable

    var emptyIndicator: UIView?

    func setUpEmptyIndicator() {
        let frame = CGRect(origin: CGPoint.zero, size: Size.screenRectWithoutAppBar(self).size)
        guard let nohanaImagePickerController = nohanaImagePickerController else {
            return
        }
        emptyIndicator = AlbumListEmptyIndicator(
            message: nohanaImagePickerController.config.strings.albumListEmptyMessage ?? NSLocalizedString("albumlist.empty.message", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: ""),
            description: nohanaImagePickerController.config.strings.albumListEmptyDescription ?? NSLocalizedString("albumlist.empty.description", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: ""),
            frame: frame,
            config: nohanaImagePickerController.config)
    }

    func isEmpty() -> Bool {
        if isProgressing() {
            return false
        }
        return photoKitAlbumList.count == 0
    }

    // MARK: - ActivityIndicatable

    var activityIndicator: UIActivityIndicatorView?
    var isLoading = true

    func setUpActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        let screenRect = Size.screenRectWithoutAppBar(self)
        activityIndicator?.center = CGPoint(x: screenRect.size.width / 2, y: screenRect.size.height / 2)
        activityIndicator?.startAnimating()
    }

    func isProgressing() -> Bool {
        return isLoading
    }
}

extension UIViewController {

    // MARK: - Toolbar

    func setUpToolbarItems() {
        let leftSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let rightSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let infoButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        infoButton.isEnabled = false
        infoButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor: UIColor.black], for: UIControlState())
        self.toolbarItems = [leftSpace, infoButton, rightSpace]
    }

    func setToolbarTitle(_ nohanaImagePickerController: NohanaImagePickerController) {
        let count: Int? = toolbarItems?.count
        guard count != nil && count! >= 2 else {
            return
        }
        guard let infoButton = toolbarItems?[1] else {
            return
        }
        if nohanaImagePickerController.maximumNumberOfSelection == 0 {
            let title = String(format: nohanaImagePickerController.config.strings.toolbarTitleNoLimit ?? NSLocalizedString("toolbar.title.nolimit", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: ""),
                nohanaImagePickerController.pickedAssetList.count)
            infoButton.title = title
        } else {
            let title = String(format: nohanaImagePickerController.config.strings.toolbarTitleHasLimit ?? NSLocalizedString("toolbar.title.haslimit", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: ""),
                nohanaImagePickerController.pickedAssetList.count,
                nohanaImagePickerController.maximumNumberOfSelection)
            infoButton.title = title
        }
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
