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

import Photos

final class MomentInfoSectionCreater {
    func createSections(mediaType: MediaType) -> [MomentInfoSection] {
        if case .video = mediaType {
            fatalError("not supported .Video and .Any yet")
        }
        var momentInfoSectionList = [MomentInfoSection]()
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fetchAssetlist = PHAsset.fetchAssets(with: allPhotosOptions)
        // Group date by day, year, month.
        let allAssets = fetchAssetlist.objects(at: IndexSet(0..<fetchAssetlist.count))
        let calender = Calendar.current
        var assetsByDate = [(DateComponents, [PHAsset])]()
        var assetsByDateIndex = 0
        for asset in allAssets {
            if  assetsByDateIndex > 0 {
                if assetsByDate[assetsByDateIndex - 1].0 == calender.dateComponents([.day, .year, .month], from: (asset.creationDate)!) {
                    assetsByDate[assetsByDateIndex - 1].1.append(asset)
                } else {
                    let value = (calender.dateComponents([.day, .year, .month], from: (asset.creationDate)!), [asset])
                    assetsByDate.append(value)
                    assetsByDateIndex += 1
                }
            } else if assetsByDate.count == assetsByDateIndex {
                let value = (calender.dateComponents([.day, .year, .month], from: (asset.creationDate)!), [asset])
                assetsByDate.append(value)
                assetsByDateIndex += 1
            }
        }
        momentInfoSectionList = assetsByDate.map { MomentInfoSection(creationDate: calender.date(from: $0.0) ?? Date(timeIntervalSince1970: 0), assetResult: $0.1) }

        return momentInfoSectionList
    }
}
