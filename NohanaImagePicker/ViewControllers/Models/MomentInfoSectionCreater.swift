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
        // MEMO: run faster create temp list than reference creationDate of fetchAssetlist.
        var creationDateList = [Date]()
        var dateList = [String]()

        for index in 0..<fetchAssetlist.count {
            if let creationDate = fetchAssetlist[index].creationDate {
                let formattedDate = formatter.string(from: creationDate)
                if !dateList.contains(formattedDate) {
                    dateList.append(formattedDate)
                    creationDateList.append(creationDate)
                    if let section = fetchInfoSection(date: creationDate, fetchOptions: allPhotosOptions) {
                        momentInfoSectionList.append(section)
                    }
                }
            }
        }
        return momentInfoSectionList
    }
    
    private func fetchInfoSection(date: Date, fetchOptions: PHFetchOptions) -> MomentInfoSection? {
        if let startDate = createDate(forDay: date, forHour: 0, forMinute: 0, forSecond: 0), let endDate = createDate(forDay: date, forHour: 23, forMinute: 59, forSecond: 59) {
            fetchOptions.predicate = NSPredicate(format: "creationDate => %@ AND creationDate < %@ && mediaType == %ld", startDate as NSDate, endDate as NSDate, PHAssetMediaType.image.rawValue)
            let assetsPhotoFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            return MomentInfoSection(creationDate: date, assetResult: assetsPhotoFetchResult)
        }
        return nil
    }
    
    private func createDate(forDay date: Date, forHour hour: Int, forMinute minute: Int, forSecond second: Int) -> Date? {
        var dateComponents = DateComponents()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let tempDate = calendar.dateComponents(in: TimeZone.current, from: date)
        dateComponents.day = tempDate.day
        dateComponents.month = tempDate.month
        dateComponents.year = tempDate.year
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second
        return calendar.date(from: dateComponents)
    }
}
