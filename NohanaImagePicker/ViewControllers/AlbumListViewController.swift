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

@MainActor
protocol AlbumListViewControllerDelegate: AnyObject {
    func didSelectMoment()
    func didSelectAlbum(album: PhotoKitAssetList)
    func willDismissViewController(viewController: AlbumListViewController)
}

class AlbumListViewController: UIViewController, UICollectionViewDelegate, EmptyIndicatable, ActivityIndicatable {

    enum Section {
        case moment
        case albums
    }

    enum Item: Hashable {
        case moment
        // The album's local identifier.
        case album(String)
    }

    unowned let nohanaImagePickerController: NohanaImagePickerController
    var photoKitAlbumList: PhotoKitAlbumList!
    weak var delegate: AlbumListViewControllerDelegate?

    private(set) lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>?
    // The albums in the applied snapshot, keyed by their item identifiers.
    private var albumsByIdentifier: [String: PhotoKitAssetList] = [:]

    init?(coder: NSCoder, nohanaImagePickerController: NohanaImagePickerController) {
        self.nohanaImagePickerController = nohanaImagePickerController
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // The collection view is the root view, so the indicators scroll with the list as they did in the table view.
        view = collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nohanaImagePickerController.config.color.background ?? .white
        title = nohanaImagePickerController.config.strings.albumListTitle ?? NSLocalizedString("albumlist.title", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
        navigationItem.leftBarButtonItem?.tintColor = nohanaImagePickerController.config.color.navigationBarForeground
        collectionView.delegate = self
        dataSource = makeDataSource()
        setUpEmptyIndicator()
        setUpActivityIndicator()
        applySnapshot()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setToolbarTitle(nohanaImagePickerController)
        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: true)
        }
    }

    // MARK: - Snapshot

    // Shows the current albums. Does nothing until the view is loaded, because viewDidLoad applies the first snapshot.
    func applySnapshot() {
        guard let dataSource = dataSource else {
            return
        }
        let albums = Array(photoKitAlbumList)
        let identifiers = albums.map(AlbumListViewController.identifier(of:))
        let snapshot = AlbumListViewController.makeSnapshot(albumIdentifiers: identifiers, showsMoment: nohanaImagePickerController.shouldShowMoment)
        albumsByIdentifier = Dictionary(zip(identifiers, albums), uniquingKeysWith: { first, _ in first })
        dataSource.apply(snapshot, animatingDifferences: false)
        updateIndicators()
    }

    static func makeSnapshot(albumIdentifiers: [String], showsMoment: Bool) -> NSDiffableDataSourceSnapshot<Section, Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.moment, .albums])
        if showsMoment {
            snapshot.appendItems([.moment], toSection: .moment)
        }
        // A snapshot must not contain duplicate identifiers, so only the first album with an identifier is shown.
        var seen = Set<String>()
        let uniqueIdentifiers = albumIdentifiers.filter { seen.insert($0).inserted }
        snapshot.appendItems(uniqueIdentifiers.map { .album($0) }, toSection: .albums)
        return snapshot
    }

    static func identifier(of album: PhotoKitAssetList) -> String {
        if let assetCollection = album.assetList as? PHAssetCollection {
            return assetCollection.localIdentifier
        }
        // A custom asset collection has no local identifier.
        return "\(ObjectIdentifier(album.assetList))"
    }

    private func updateIndicators() {
        if let emptyIndicator = emptyIndicator {
            updateVisibilityOfEmptyIndicator(emptyIndicator)
        }
        if let activityIndicator = activityIndicator {
            updateVisibilityOfActivityIndicator(activityIndicator)
        }
    }

    // MARK: - Layout

    private func makeLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = false
        configuration.backgroundColor = .clear
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }

    // MARK: - Data source

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Item> {
        let momentCellRegistration = UICollectionView.CellRegistration<MomentCell, Item> { [unowned self] cell, _, _ in
            cell.config = nohanaImagePickerController.config
            cell.titleLabel.text = nohanaImagePickerController.config.strings.albumListMomentTitle ?? NSLocalizedString("albumlist.moment.title", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
        }
        let albumCellRegistration = UICollectionView.CellRegistration<AlbumCell, PhotoKitAssetList> { [unowned self] cell, _, albumList in
            cell.titleLabel.text = albumList.title
            let scale = UIScreen.main.scale
            let imageSize = CGSize(width: AlbumCell.thumbnailSide * scale, height: AlbumCell.thumbnailSide * scale)
            let albumCount = albumList.count
            if albumCount > 0 {
                let lastAsset = nohanaImagePickerController.canPickDateSection ? albumList[0] : albumList[albumCount - 1]
                cell.loadThumbnail(of: lastAsset, targetSize: imageSize, loader: nohanaImagePickerController.thumbnailLoader)
            } else {
                cell.clearThumbnail()
            }
        }
        return UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [unowned self] collectionView, indexPath, item in
            switch item {
            case .moment:
                return collectionView.dequeueConfiguredReusableCell(using: momentCellRegistration, for: indexPath, item: item)
            case .album(let identifier):
                guard let albumList = albumsByIdentifier[identifier] else {
                    fatalError("No album for the identifier \(identifier)")
                }
                return collectionView.dequeueConfiguredReusableCell(using: albumCellRegistration, for: indexPath, item: albumList)
            }
        }
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource?.itemIdentifier(for: indexPath) else {
            return
        }
        switch item {
        case .moment:
            delegate?.didSelectMoment()
            nohanaImagePickerController.delegate?.nohanaImagePickerDidSelectMoment?(nohanaImagePickerController)
        case .album(let identifier):
            guard let albumList = albumsByIdentifier[identifier] else {
                return
            }
            delegate?.didSelectAlbum(album: albumList)
            nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didSelectPhotoKitAssetList: albumList.assetList)
        }
        delegate?.willDismissViewController(viewController: self)
        dismiss(animated: true, completion: nil)
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
