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
        titleView.addTarget(self, action: #selector(didTapTitleView), for: .touchUpInside)
        navigationItem.titleView = titleView
        
        // toolbar
        navigationController?.setToolbarHidden(nohanaImagePickerController.toolbarHidden, animated: false)
        setUpToolbarItems()
        
        // Notification
        addPickPhotoKitAssetNotificationObservers()
        
        showRecentPhotos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setToolbarTitle(nohanaImagePickerController)
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
        let storyboard = UIStoryboard(name: "AlbumList", bundle: nohanaImagePickerController.assetBundle)
        guard let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController else {
            fatalError("navigationController init failed.")
        }
        guard let albumListViewController = navigationController.topViewController as? AlbumListViewController else {
            fatalError("albumListViewController is not topViewController.")
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
        albumListViewController.nohanaImagePickerController = nohanaImagePickerController
        albumListViewController.delegate = self
        navigationController.presentationController?.delegate = self
        present(navigationController, animated: true, completion: nil)
    }
    
    private func showRecentPhotos() {
        albumList = PhotoKitAlbumList(
            assetCollectionTypes: [.smartAlbum, .album],
            assetCollectionSubtypes: nohanaImagePickerController.assetCollectionSubtypes,
            mediaType: nohanaImagePickerController.mediaType,
            shouldShowEmptyAlbum: nohanaImagePickerController.shouldShowEmptyAlbum,
            ascending: !nohanaImagePickerController.canPickDateSection,
            handler: { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    let album = self.albumList[0]
                    self.switchChildViewController(nil, toViewController: self.fetchAssetListViewController(album: album))
                    self.updateTitle(title: album.title)
                }
            })
    }
    
    private func fetchMomentViewController() -> UIViewController {
        guard let momentViewController = UIStoryboard(name: "Moment", bundle: nohanaImagePickerController.assetBundle).instantiateInitialViewController() as? MomentViewController else {
            fatalError("Invalid ViewController")
        }
        momentViewController.nohanaImagePickerController = nohanaImagePickerController
        return momentViewController
    }
    
    private func fetchAssetListViewController(album: PhotoKitAssetList) -> UIViewController {
        if nohanaImagePickerController.canPickDateSection {
            guard let assetListViewController = UIStoryboard(name: "AssetListSelectableDateSection", bundle: nohanaImagePickerController.assetBundle).instantiateInitialViewController() as? AssetListSelectableDateSectionController else {
                fatalError("Invalid ViewController")
            }
            assetListViewController.photoKitAssetList = album
            assetListViewController.reloadData()
            assetListViewController.nohanaImagePickerController = nohanaImagePickerController
            return assetListViewController
        } else {
            guard let assetListViewController = UIStoryboard(name: "AssetList", bundle: nohanaImagePickerController.assetBundle).instantiateInitialViewController() as? AssetListViewController else {
                fatalError("Invalid ViewController")
            }
            assetListViewController.photoKitAssetList = album
            assetListViewController.reloadData()
            assetListViewController.nohanaImagePickerController = nohanaImagePickerController
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
    
    // MARK: - IBAction
    @IBAction func didTapDone(_ sender: AnyObject) {
        let pickedPhotoKitAssets = nohanaImagePickerController.pickedAssetList.map { ($0 as! PhotoKitAsset).originalAsset }
        nohanaImagePickerController.delegate?.nohanaImagePicker(nohanaImagePickerController, didFinishPickingPhotoKitAssets: pickedPhotoKitAssets )
    }
    
    @IBAction func didTapClose(_ sender: AnyObject) {
        dismiss(animated: true)
    }
}

extension RootViewController: AlbumListViewControllerDelegate {
    func didSelectMoment() {
        switchChildViewController(currentChildViewController, toViewController: fetchMomentViewController())
        let title = NSLocalizedString("albumlist.moment.title", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
        updateTitle(title: title)
        setToolbarTitle(nohanaImagePickerController)
        transformAnimation()
    }
    
    func didSelectAlbum(album: PhotoKitAssetList) {
        switchChildViewController(currentChildViewController, toViewController: fetchAssetListViewController(album: album))
        updateTitle(title: album.title)
        setToolbarTitle(nohanaImagePickerController)
        transformAnimation()
    }
}

extension RootViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        transformAnimation()
    }
}
