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

struct Size {

    static var statusBarHeight: CGFloat {
        if UIApplication.shared.currentStatusBarHidden {
            return 0
        }
        return UIApplication.shared.currentStatusBarFrame.size.height
    }

    static func navigationBarHeight(_ viewController: UIViewController) -> CGFloat {
        return viewController.navigationController?.navigationBar.frame.size.height ?? CGFloat(0)
    }

    static func appBarHeight(_ viewController: UIViewController) -> CGFloat {
        return statusBarHeight + navigationBarHeight(viewController)
    }

    static func toolbarHeight(_ viewController: UIViewController) -> CGFloat {
        guard let navigationController = viewController.navigationController else {
            return 0
        }
        guard !navigationController.isToolbarHidden else {
            return 0
        }
        return navigationController.toolbar.frame.size.height
    }

    static func screenRectWithoutAppBar(_ viewController: UIViewController) -> CGRect {
        let appBarHeight: CGFloat = {
            if #available(iOS 11.0, *) {
                return viewController.view.safeAreaInsets.top
            } else {
                return Size.appBarHeight(viewController)
            }
        }()
        let toolbarHeight: CGFloat = {
            if #available(iOS 11.0, *) {
                return viewController.view.safeAreaInsets.bottom
            } else {
                return Size.toolbarHeight(viewController)
            }
        }()
        return CGRect(
            x: 0,
            y: appBarHeight,
            width: viewController.view.bounds.width,
            height: viewController.view.bounds.height - appBarHeight - toolbarHeight)
    }
}
