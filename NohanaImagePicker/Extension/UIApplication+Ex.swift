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

extension UIApplication {
    // The scene of the key window (UIApplication.windows is deprecated).
    private var keyWindowScene: UIWindowScene? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.windows.contains(where: { $0.isKeyWindow }) }
    }

    var currentStatusBarOrientation: UIInterfaceOrientation {
        guard let orientation = keyWindowScene?.interfaceOrientation else {
            return .unknown
        }
        return orientation
    }
    
    var currentStatusBarFrame: CGRect {
        guard let frame = keyWindowScene?.statusBarManager?.statusBarFrame else {
            return .zero
        }
        return frame
    }
    
    var currentStatusBarHidden: Bool {
        guard let isStatusBarHidden = keyWindowScene?.statusBarManager?.isStatusBarHidden else {
            return false
        }
        return isStatusBarHidden
    }
}
