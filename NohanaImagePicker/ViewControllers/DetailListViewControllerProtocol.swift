/*
 * Copyright (C) 2021 nohana, Inc.
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

protocol DetailListViewControllerProtocol where Self: UICollectionViewController {
    var currentIndexPath: IndexPath { get set }
}

extension DetailListViewControllerProtocol {
    /// The detail pages page their photos horizontally, so their pan gesture would win over the swipe from the
    /// left edge. Let it wait for the navigation controller's standard swipe-back gesture to fail.
    @MainActor
    func letSwipeBackWinOverPaging() {
        guard let popGesture = navigationController?.interactivePopGestureRecognizer else {
            return
        }
        collectionView?.panGestureRecognizer.require(toFail: popGesture)
    }

    /// The view extends under the bars, but each page is as tall as the area between them. A horizontal collection
    /// view does not get a top inset automatically, so set the insets so that the pages sit between the bars.
    /// Call this from viewSafeAreaInsetsDidChange; contentInsetAdjustmentBehavior must be .never.
    @MainActor
    func fitPagesBetweenBars() {
        collectionView?.contentInset = UIEdgeInsets(top: view.safeAreaInsets.top, left: 0, bottom: view.safeAreaInsets.bottom, right: 0)
    }

    /// Show the page of `currentIndexPath` right away instead of on the next run loop, so that the page is right
    /// when the zoom transition starts. Call this when the detail list is about to appear for the first time.
    @MainActor
    func scrollToCurrentPage() {
        // Laying out may scroll to the first page and change currentIndexPath.
        let item = currentIndexPath.item
        guard let collectionView else {
            return
        }
        collectionView.layoutIfNeeded()
        guard item < collectionView.numberOfItems(inSection: 0) else {
            return
        }
        collectionView.scrollToItem(at: IndexPath(item: item, section: 0), at: .centeredHorizontally, animated: false)
    }

    /// Whether the photo of the current page is zoomed in. Then a swipe pans the photo instead of going back.
    @MainActor
    var isZoomedIn: Bool {
        guard let cell = collectionView?.cellForItem(at: IndexPath(item: currentIndexPath.item, section: 0)) as? AssetDetailCell else {
            return false
        }
        return cell.scrollView.zoomScale > cell.scrollView.minimumZoomScale
    }
}

extension UICollectionViewController {
    /// On iOS 18+, let the detail list zoom out of the tapped photo, and back into the photo of the page shown when
    /// going back. `indexPathForPage` gives the item in this grid for a page of the detail list.
    func zoomDetailList(_ detailList: some DetailListViewControllerProtocol, _ nohanaImagePickerController: NohanaImagePickerController, indexPathForPage: @escaping (IndexPath) -> IndexPath?) {
        guard nohanaImagePickerController.enableExpandingPhotoAnimation, #available(iOS 18.0, *) else {
            return
        }
        #if compiler(>=6.4) // The iOS 27 SDK
        // Built with the iOS 27 SDK (checked up to 27.2), the zoom in a sheet hides the sheet: it comes back with the
        // detail list on a device, and does not come back on the simulator. Use the standard push in a sheet.
        if isInSheet {
            return
        }
        #endif
        let options = UIViewController.Transition.ZoomOptions()
        options.interactiveDismissShouldBegin = { [weak detailList] _ in
            !(detailList?.isZoomedIn ?? false)
        }
        detailList.preferredTransition = .zoom(options: options) { [weak self, weak detailList] _ in
            guard let self, let detailList, let collectionView, let indexPath = indexPathForPage(detailList.currentIndexPath) else {
                return nil
            }
            // When going back, the photo of the current page may be scrolled out of the grid.
            if collectionView.cellForItem(at: indexPath) == nil {
                collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
                collectionView.layoutIfNeeded()
            }
            return collectionView.cellForItem(at: indexPath)
        }
    }

    #if compiler(>=6.4) // The iOS 27 SDK
    /// Whether this view controller is shown in a sheet, e.g. when the picker is presented with the default style.
    private var isInSheet: Bool {
        var root: UIViewController = self
        while let parent = root.parent {
            root = parent
        }
        return root.presentingViewController != nil && root.sheetPresentationController != nil
    }
    #endif
}
