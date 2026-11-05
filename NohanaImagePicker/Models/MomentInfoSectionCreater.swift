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
    /// Groups all photos by the day they were taken, oldest first.
    /// The photos are fetched once and grouped in memory; this can take a while for a large library,
    /// so call it on a background queue.
    func createSections(mediaType: MediaType) -> [MomentInfoSection] {
        if case .video = mediaType {
            fatalError("not supported .Video and .Any yet")
        }
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fetchResult = PHAsset.fetchAssets(with: options)

        let calendar = Calendar(identifier: .gregorian)
        var sections = [MomentInfoSection]()
        var currentDay: DateComponents?
        var currentDate = Date()
        var currentAssets = [PHAsset]()
        fetchResult.enumerateObjects { asset, _, _ in
            // Photos without a creation date are not shown in Moment.
            guard let creationDate = asset.creationDate else {
                return
            }
            let day = calendar.dateComponents([.year, .month, .day], from: creationDate)
            if day != currentDay {
                if !currentAssets.isEmpty {
                    sections.append(MomentInfoSection(creationDate: currentDate, assetResult: currentAssets))
                }
                currentDay = day
                currentDate = creationDate
                currentAssets = []
            }
            currentAssets.append(asset)
        }
        if !currentAssets.isEmpty {
            sections.append(MomentInfoSection(creationDate: currentDate, assetResult: currentAssets))
        }
        return sections
    }
}
