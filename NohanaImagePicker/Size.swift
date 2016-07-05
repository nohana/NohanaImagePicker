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
        get {
            if UIApplication.sharedApplication().statusBarHidden {
                return 0
            }
            return UIApplication.sharedApplication().statusBarFrame.size.height
        }
    }
    
    static func navigationBarHeight(viewController: UIViewController) -> CGFloat {
        return viewController.navigationController?.navigationBar.frame.size.height ?? CGFloat(0)
    }
    
    static func appBarHeight(viewController: UIViewController) -> CGFloat {
        return statusBarHeight + navigationBarHeight(viewController)
    }
    
    static func toolbarHeight(viewController: UIViewController) -> CGFloat {
        guard let navigationController = viewController.navigationController else {
            return 0
        }
        guard !navigationController.toolbarHidden else {
            return 0
        }
        return navigationController.toolbar.frame.size.height
    }
    
    static func screenRectWithoutAppBar(viewController: UIViewController) -> CGRect {
        let appBarHeight = Size.appBarHeight(viewController)
        let toolbarHeight = Size.toolbarHeight(viewController)
        return CGRect(
            x: 0,
            y: appBarHeight,
            width: UIScreen.mainScreen().bounds.width,
            height: UIScreen.mainScreen().bounds.height - appBarHeight - toolbarHeight)
    }
}
