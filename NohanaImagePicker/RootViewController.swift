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

class RootViewController: UIViewController {
    
    private let nohanaImagePickerController: NohanaImagePickerController
    private let titleView: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold))
        button.setImage(image, for: .normal)
        return button
    }()
    private var currentChildViewController: UIViewController?
    private var albumList: PhotoKitAlbumList!
    private lazy var albumListViewController: AlbumListViewController = {
        let storyboard = UIStoryboard(name: "AlbumList", bundle: nohanaImagePickerController.assetBundle)
        guard let albumListViewController = storyboard.instantiateInitialViewController(creator: { corder in
            AlbumListViewController(coder: corder, nohanaImagePickerController: self.nohanaImagePickerController)
        }) else {
            fatalError("albumListViewController init failed.")
        }
        albumListViewController.photoKitAlbumList = PhotoKitAlbumList(assetCollectionTypes: [.smartAlbum, .album],
                                                                      assetCollectionSubtypes: nohanaImagePickerController.assetCollectionSubtypes,
                                                                      mediaType: nohanaImagePickerController.mediaType,
                                                                      shouldShowEmptyAlbum: nohanaImagePickerController.shouldShowMoment,
                                                                      ascending: !nohanaImagePickerController.canPickDateSection,
                                                                      handler: { [weak albumListViewController] in
            DispatchQueue.main.async {
                albumListViewController?.isLoading = false
                albumListViewController?.tableView.reloadData()
            }
        })
        return albumListViewController
    }()
    
    init?(coder: NSCoder, nohanaImagePickerController: NohanaImagePickerController) {
        self.nohanaImagePickerController = nohanaImagePickerController
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // titleView
        titleView.tintColor = nohanaImagePickerController.config.color.navigationBarForeground
        titleView.addTarget(self, action: #selector(didTapTitleView), for: .touchUpInside)
        navigationItem.titleView = titleView
        navigationItem.leftBarButtonItem?.tintColor = nohanaImagePickerController.config.color.navigationBarForeground
        
        // toolbar
        navigationController?.setToolbarHidden(nohanaImagePickerController.toolbarHidden, animated: false)
        setUpToolbarItems()
        
        // Notification
        addPickPhotoKitAssetNotificationObservers()
        
        if let assetCollection = nohanaImagePickerController.defaultAssetCollection {
            showPhotosFromDefaultAlbum(album: assetCollection)
        } else {
            showRecentPhotos()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setToolbarTitle(nohanaImagePickerController)
        
        // FIXME: The settings of UIBarButtonItemAppearance may not be reflected.
        // Probably, this problem occurs when the settings are set to reflect the entire application.
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([
            .foregroundColor: nohanaImagePickerController.config.color.navigationBarDoneBarButtonItem,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ], for: .normal)
    }
    
    // MARK: Private
    private func updateTitle(title: String) {
        let attributedTitle = NSAttributedString(string: title, attributes: nohanaImagePickerController.titleTextAttributes)
        titleView.setAttributedTitle(attributedTitle, for: .normal)
        titleView.sizeToFit()
        navigationController?.navigationBar.setNeedsLayout()
        if let titleLabel = titleView.titleLabel, let imageView = titleView.imageView {
            let titleLabelWidth = titleLabel.frame.width
            let imageWidth = imageView.frame.width
            let space: CGFloat = 2.0
            self.titleView.imageEdgeInsets = UIEdgeInsets(top: 0, left: titleLabelWidth + space, bottom: 0, right: -titleLabelWidth - space)
            self.titleView.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth - space, bottom: 0, right: imageWidth + space)
        }
    }
    
    @objc private func didTapTitleView() {
        showAlbumList()
        transformAnimation()
    }
    
    private func showAlbumList() {
        let navigationController = UINavigationController(rootViewController: albumListViewController)
        albumListViewController.delegate = self
        navigationController.presentationController?.delegate = self
        let appearance = navigationBarAppearance(nohanaImagePickerController)
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        present(navigationController, animated: true, completion: nil)
    }
    
    private func showPhotosFromDefaultAlbum(album: PHAssetCollection) {
        let album = PhotoKitAssetList(album: album, mediaType: nohanaImagePickerController.mediaType, ascending: !nohanaImagePickerController.canPickDateSection)
        switchChildViewController(currentChildViewController, toViewController: fetchAssetListViewController(album: album))
        updateTitle(title: album.title)
    }
    
    private func showRecentPhotos() {
        albumList = PhotoKitAlbumList(
            assetCollectionTypes: [.smartAlbum],
            assetCollectionSubtypes: [.smartAlbumUserLibrary],
            mediaType: nohanaImagePickerController.mediaType,
            shouldShowEmptyAlbum: nohanaImagePickerController.shouldShowEmptyAlbum,
            ascending: !nohanaImagePickerController.canPickDateSection,
            handler: { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else  { return }
                    guard let album = self.albumList.first else {
                        let title = self.nohanaImagePickerController.config.strings.albumListEmptyMessage ?? NSLocalizedString("albumlist.empty.message", tableName: "NohanaImagePicker", bundle: self.nohanaImagePickerController.assetBundle, comment: "")
                        let ok = self.nohanaImagePickerController.config.strings.albumListEmptyAlertButtonOK ?? NSLocalizedString("albumlist.empty.alert.button.ok", tableName: "NohanaImagePicker", bundle: self.nohanaImagePickerController.assetBundle, comment: "")
                        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: ok, style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    self.switchChildViewController(self.currentChildViewController, toViewController: self.fetchAssetListViewController(album: album))
                    self.updateTitle(title: album.title)
                }
            })
    }
    
    private func fetchMomentViewController() -> UIViewController {
        guard let momentViewController = UIStoryboard(name: "Moment", bundle: nohanaImagePickerController.assetBundle).instantiateInitialViewController(creator: { corder in
            MomentViewController(coder: corder, nohanaImagePickerController: self.nohanaImagePickerController)
        }) else {
            fatalError("Invalid ViewController")
        }
        return momentViewController
    }
    
    private func fetchAssetListViewController(album: PhotoKitAssetList) -> UIViewController {
        if nohanaImagePickerController.canPickDateSection {
            guard let assetListViewController = UIStoryboard(name: "AssetListSelectableDateSection", bundle: nohanaImagePickerController.assetBundle).instantiateInitialViewController(creator: { corder in
                AssetListSelectableDateSectionController(coder: corder, nohanaImagePickerController: self.nohanaImagePickerController, photoKitAssetList: album)
            }) else {
                fatalError("Invalid ViewController")
            }
            return assetListViewController
        } else {
            guard let assetListViewController = UIStoryboard(name: "AssetList", bundle: nohanaImagePickerController.assetBundle).instantiateInitialViewController(creator: { corder in
                AssetListViewController(coder: corder, nohanaImagePickerController: self.nohanaImagePickerController, photoKitAssetList: album)
            }) else {
                fatalError("Invalid ViewController")
            }
            return assetListViewController
        }
    }
    
    private func switchChildViewController(_ oldViewController: UIViewController?, toViewController newViewController: UIViewController) {
        oldViewController?.willMove(toParent: nil)
        newViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(newViewController)
        view.addSubview(newViewController.view)
        
        NSLayoutConstraint.activate([
            newViewController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            newViewController.view.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            newViewController.view.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            newViewController.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
        ])
        newViewController.view.layoutIfNeeded()
        
        oldViewController?.view.removeFromSuperview()
        oldViewController?.removeFromParent()
        newViewController.didMove(toParent: self)
        currentChildViewController = newViewController
    }
    
    private func transformAnimation() {
        guard let imageView = titleView.imageView else { return }
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
            if imageView.transform.isIdentity {
                let angle = 180 * CGFloat.pi / 180
                imageView.transform = CGAffineTransform(rotationAngle: angle)
            } else {
                let angle = -360 * CGFloat.pi / 180
                imageView.transform = CGAffineTransform(rotationAngle: angle)
                imageView.transform = .identity
            }
        })
    }

    @objc func didTapAddPhoto(_ notification: Notification) {
        nohanaImagePickerController.delegate?.nohanaImagePickerDidTapAddPhotoButton?(nohanaImagePickerController)
    }

    @objc func didTapAuthorizeAllPhoto(_ notification: Notification) {
        nohanaImagePickerController.delegate?.nohanaImagePickerDidTapAuthorizeAllPhotoButton?(nohanaImagePickerController)
    }
    
    // MARK: - IBAction
    @IBAction func didTapDone(_ sender: AnyObject) {
        let pickedPhotoKitAssets = nohanaImagePickerController.pickedAssetList.map { ($0 as! PhotoKitAsset).originalAsset }
        nohanaImagePickerController.delegate?.nohanaImagePicker(nohanaImagePickerController, didFinishPickingPhotoKitAssets: pickedPhotoKitAssets )
    }
    
    @IBAction func didTapClose(_ sender: AnyObject) {
        nohanaImagePickerController.delegate?.nohanaImagePickerDidCancel(nohanaImagePickerController)
    }
}

extension RootViewController: AlbumListViewControllerDelegate {
    func didSelectMoment() {
        switchChildViewController(currentChildViewController, toViewController: fetchMomentViewController())
        let title = NSLocalizedString("albumlist.moment.title", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
        updateTitle(title: title)
        setToolbarTitle(nohanaImagePickerController)
    }
    
    func didSelectAlbum(album: PhotoKitAssetList) {
        switchChildViewController(currentChildViewController, toViewController: fetchAssetListViewController(album: album))
        updateTitle(title: album.title)
        setToolbarTitle(nohanaImagePickerController)
    }
    
    func willDismissViewController(viewController: AlbumListViewController) {
        transformAnimation()
    }
}

extension RootViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }

    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        transformAnimation()
        transitionCoordinator?.animate(alongsideTransition: { context in
            //Dismissal is animating. Could be finishing or canceling the dismissal
        }, completion: { [weak self] context in
            if context.isCancelled {
                // cancelled dismiss
                self?.transformAnimation()
            }
        })
    }
}
