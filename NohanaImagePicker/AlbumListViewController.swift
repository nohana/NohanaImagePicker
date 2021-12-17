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
            if nohanaImagePickerController.canPickDateSection {
                performSegue(withIdentifier: "toAssetListViewSelectableDateSectionController", sender: nil)
            } else {
                performSegue(withIdentifier: "toAssetListViewController", sender: nil)
            }
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
                let lastAsset = nohanaImagePickerController?.canPickDateSection ?? false ? albumList[0] : albumList[albumCount - 1]
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
        case .albums:
            switch segue.identifier {
            case "toAssetListViewController":
                let assetListViewController = segue.destination as! AssetListViewController
                assetListViewController.photoKitAssetList = photoKitAlbumList[tableView.indexPathForSelectedRow!.row]
                assetListViewController.nohanaImagePickerController = nohanaImagePickerController
            case "toAssetListViewSelectableDateSectionController":
                let assetListSelectableDateSectionController = segue.destination as! AssetListSelectableDateSectionController
                assetListSelectableDateSectionController.photoKitAssetList = photoKitAlbumList[tableView.indexPathForSelectedRow!.row]
                assetListSelectableDateSectionController.nohanaImagePickerController = nohanaImagePickerController
            default:
                fatalError("unexpected segue identifer")
            }
        }
    }

    // MARK: - IBAction

    @IBAction func didTapClose(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
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
        activityIndicator = UIActivityIndicatorView(style: .gray)
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
    
    // MARK: - Animation
    internal func transformAnimation(targetView: UIView) {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
            if targetView.transform.isIdentity {
                let angle = 180 * CGFloat.pi / 180
                targetView.transform = CGAffineTransform(rotationAngle: angle)
            } else {
                let angle = -360 * CGFloat.pi / 180
                targetView.transform = CGAffineTransform(rotationAngle: angle)
                targetView.transform = .identity
            }
        })
    }
}
