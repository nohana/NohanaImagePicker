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

@MainActor
struct Size {

    static func screenRectWithoutAppBar(_ viewController: UIViewController) -> CGRect {
        let appBarHeight = viewController.view.safeAreaInsets.top
        let toolbarHeight = viewController.view.safeAreaInsets.bottom
        return CGRect(
            x: 0,
            y: appBarHeight,
            width: viewController.view.bounds.width,
            height: viewController.view.bounds.height - appBarHeight - toolbarHeight)
    }
}
