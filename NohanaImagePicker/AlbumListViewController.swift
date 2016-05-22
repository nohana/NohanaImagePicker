//
//  AlbumListViewController.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/02/08.
//  Copyright © 2016年 nohana. All rights reserved.
//

import UIKit
import Photos

class AlbumListViewController: UITableViewController, EmptyIndicatable, ActivityIndicatable {
    
    enum AlbumListViewControllerSectionType: Int {
        case Moment = 0
        case Albums
        
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
    
    weak var nohanaImagePickerController: NohanaImagePickerController!
    var photoKitAlbumList: PhotoKitAlbumList!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("albumlist.title", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
        setUpToolbarItems()
        navigationController?.setToolbarHidden(nohanaImagePickerController.toolbarHidden ?? false, animated: false)
        setUpEmptyIndicator()
        setUpActivityIndicator()
        self.view.backgroundColor = ColorConfig.backgroundColor
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setToolbarTitle(nohanaImagePickerController)
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPathForSelectedRow, animated: true)
        }
    }

    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let sectionType = AlbumListViewControllerSectionType(rawValue: indexPath.section) else {
            fatalError("Invalid section")
        }
        switch sectionType {
        case .Moment:
            nohanaImagePickerController.delegate?.nohanaImagePickerDidSelectMoment?(nohanaImagePickerController)
        case .Albums:
            nohanaImagePickerController.delegate?.nohanaImagePicker?(nohanaImagePickerController, didSelectPhotoKitAssetList: photoKitAlbumList[indexPath.row].assetList)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard let sectionType = AlbumListViewControllerSectionType(rawValue: indexPath.section) else {
            fatalError("Invalid section")
        }
        switch sectionType {
        case .Moment:
            return 52
        case .Albums:
            return 82
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return AlbumListViewControllerSectionType.count()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        case .Moment:
            return nohanaImagePickerController.shouldShowMoment ? 1 : 0
        case .Albums:
            return photoKitAlbumList.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let sectionType = AlbumListViewControllerSectionType(rawValue: indexPath.section) else {
            fatalError("Invalid section")
        }
        
        switch sectionType {
        case .Moment:
            guard let cell = tableView.dequeueReusableCellWithIdentifier("MomentAlbumCell") as? AlbumCell else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"MomentAlbumCell\")")
            }
            cell.titleLabel?.text = NSLocalizedString("albumlist.moment.title", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: "")
            return cell
        case .Albums:
            guard let cell = tableView.dequeueReusableCellWithIdentifier("AlbumCell") as? AlbumCell else {
                fatalError("failed to dequeueReusableCellWithIdentifier(\"AlbumCell\")")
            }
            let albumList = photoKitAlbumList[indexPath.row]
            cell.titleLabel.text = albumList.title
            cell.tag = indexPath.row
            let imageSize = CGSize(
                width: cell.thumbnailImageView.frame.size.width * UIScreen.mainScreen().scale,
                height: cell.thumbnailImageView.frame.size.width * UIScreen.mainScreen().scale
            )
            if let lastAsset = albumList.last {
                lastAsset.image(imageSize, handler: { (imageData) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let sectionType = AlbumListViewControllerSectionType(rawValue: tableView.indexPathForSelectedRow!.section) else {
            fatalError("Invalid section")
        }
        switch sectionType {
        case .Moment:
            let momentViewController = segue.destinationViewController as! MomentViewController
            momentViewController.nohanaImagePickerController = nohanaImagePickerController
            momentViewController.momentAlbumList = PhotoKitAlbumList(
                assetCollectionTypes: [.Moment],
                assetCollectionSubtypes: [.Any],
                mediaType: nohanaImagePickerController.mediaType,
                shouldShowEmptyAlbum: nohanaImagePickerController.shouldShowEmptyAlbum,
                handler: { () -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        momentViewController.isLoading = false
                        momentViewController.collectionView?.reloadData()
                    })
            })
        case .Albums:
            let assetListViewController = segue.destinationViewController as! AssetListViewController
            assetListViewController.photoKitAssetList = photoKitAlbumList[tableView.indexPathForSelectedRow!.row]
            assetListViewController.nohanaImagePickerController = nohanaImagePickerController
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func didPushCancel(sender: AnyObject) {
        nohanaImagePickerController.delegate?.nohanaImagePickerDidCancel(nohanaImagePickerController)
    }
    
    // MARK: - EmptyIndicatable
    
    var emptyIndicator: UIView?
    
    func setUpEmptyIndicator() {
        let frame = CGRect(origin: CGPoint.zero, size: Size.screenRectWithoutAppBar(self).size)
        emptyIndicator = AlbumListEmptyIndicator(
            message: NSLocalizedString("albumlist.empty.message", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: ""),
            description: NSLocalizedString("albumlist.empty.description", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: ""),
            frame: frame)
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
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
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
        let leftSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let rightSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        let infoButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        infoButton.enabled = false
        infoButton.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(14), NSForegroundColorAttributeName: UIColor.blackColor()], forState: .Normal)
        self.toolbarItems = [leftSpace, infoButton, rightSpace]
    }
    
    func setToolbarTitle(nohanaImagePickerController:NohanaImagePickerController) {
        guard toolbarItems?.count >= 2 else {
            return
        }
        guard let infoButton = toolbarItems?[1] else {
            return
        }
        if nohanaImagePickerController.maximumNumberOfSelection == 0 {
            let title = String(format: NSLocalizedString("toolbar.title.nolimit", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: ""),
                nohanaImagePickerController.pickedAssetList.count)
            infoButton.title = title
        } else {
            let title = String(format: NSLocalizedString("toolbar.title.haslimit", tableName: "NohanaImagePicker", bundle: nohanaImagePickerController.assetBundle, comment: ""),
                nohanaImagePickerController.pickedAssetList.count,
                nohanaImagePickerController.maximumNumberOfSelection)
            infoButton.title = title
        }
    }
    
    // MARK: - Notification
    
    func addPickPhotoKitAssetNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didPickPhotoKitAsset:", name: NotificationInfo.Asset.PhotoKit.didPick, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didDropPhotoKitAsset:", name: NotificationInfo.Asset.PhotoKit.didDrop, object: nil)
    }
    
    func didPickPhotoKitAsset(notification: NSNotification) {
        guard let picker = notification.object as? NohanaImagePickerController else {
            return
        }
        setToolbarTitle(picker)
    }
    
    func didDropPhotoKitAsset(notification: NSNotification) {
        guard let picker = notification.object as? NohanaImagePickerController else {
            return
        }
        setToolbarTitle(picker)
    }
}
