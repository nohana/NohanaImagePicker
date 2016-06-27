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

struct NotificationInfo {
    struct Asset {
        struct PhotoKit {
            static let didPick = "jp.co.nohana.NotificationName.Asset.PhotoKit.didPick"
            static let didPickUserInfoKeyAsset = "asset"
            static let didPickUserInfoKeyPickedAssetsCount = "pickedAssetsCount"
            static let didDrop = "jp.co.nohana.NotificationName.Asset.PhotoKit.didDrop"
            static let didDropUserInfoKeyAsset = "asset"
            static let didDropUserInfoKeyPickedAssetsCount = "pickedAssetsCount"
        }
    }
}