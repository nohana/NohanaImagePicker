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

struct Size {

    static var statusBarHeight: CGFloat {
        if UIApplication.shared.isStatusBarHidden {
            return 0
        }
        return UIApplication.shared.statusBarFrame.size.height
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
        let appBarHeight = Size.appBarHeight(viewController)
        let toolbarHeight = Size.toolbarHeight(viewController)
        return CGRect(
            x: 0,
            y: appBarHeight,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height - appBarHeight - toolbarHeight)
    }
}
