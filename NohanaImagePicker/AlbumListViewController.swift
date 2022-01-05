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

protocol AlbumListViewControllerDelegate: AnyObject {
    func didSelectMoment()
    func didSelectAlbum(album: PhotoKitAssetList)
    func willDismissViewController(viewController: AlbumListViewController)
}

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

    let nohanaImagePickerController: NohanaImagePickerController
    var photoKitAlbumList: PhotoKitAlbumList!
    weak var delegate: AlbumListViewControllerDelegate?
    
    init?(coder: NSCoder, nohanaImagePickerController: NohanaImagePickerController) {
        self.nohanaImagePickerController = nohanaImagePickerController
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nohanaImagePickerController.config.color.background ?? .white
        title = nohanaImagePickerController.config.strings.albumListTitle ?? NSLocalizedString("albumlist.title", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
        navigationItem.leftBarButtonItem?.tintColor = nohanaImagePickerController.config.color.navigationBarForeground
        setUpEmptyIndicator()
        setUpActivityIndicator()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setToolbarTitle(nohanaImagePickerController)
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
        switch sectionType {
        case .moment:
            delegate?.didSelectMoment()
            nohanaImagePickerController.delegate?.nohanaImagePickerDidSelectMoment?(nohanaImagePickerController)
            delegate?.willDismissViewController(viewController: self)
            dismiss(animated: true, completion: nil)
        case .albums:
            delegate?.didSelectAlbum(album: photoKitAlbumList[indexPath.row])
            nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didSelectPhotoKitAssetList: photoKitAlbumList[indexPath.row].assetList)
            delegate?.willDismissViewController(viewController: self)
            dismiss(animated: true, completion: nil)
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
            return nohanaImagePickerController.shouldShowMoment ? 1 : 0
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
            cell.config = nohanaImagePickerController.config
            cell.titleLabel?.text = nohanaImagePickerController.config.strings.albumListMomentTitle ?? NSLocalizedString("albumlist.moment.title", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
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
                let lastAsset = nohanaImagePickerController.canPickDateSection ? albumList[0] : albumList[albumCount - 1]
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

    // MARK: - IBAction

    @IBAction func didTapClose(_ sender: AnyObject) {
        delegate?.willDismissViewController(viewController: self)
        dismiss(animated: true, completion: nil)
    }

    // MARK: - EmptyIndicatable

    var emptyIndicator: UIView?

    func setUpEmptyIndicator() {
        let frame = CGRect(origin: CGPoint.zero, size: Size.screenRectWithoutAppBar(self).size)
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
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator?.color = .gray
        let screenRect = Size.screenRectWithoutAppBar(self)
        activityIndicator?.center = CGPoint(x: screenRect.size.width / 2, y: screenRect.size.height / 2)
        activityIndicator?.startAnimating()
    }

    func isProgressing() -> Bool {
        return isLoading
    }
}
