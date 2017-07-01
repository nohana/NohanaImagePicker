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

class MomentCell: AlbumCell {
    var config: NohanaImagePickerController.Config!

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let lineWidth: CGFloat = 1 / UIScreen.main.scale
        let separatorColor: UIColor = config.color.separator ?? UIColor(red: 0xbb/0xff, green: 0xbb/0xff, blue: 0xbb/0xff, alpha: 1)
        separatorColor.setFill()
        UIRectFill(CGRect(x: 16, y: frame.size.height - lineWidth, width: frame.size.width, height:lineWidth))
    }

}
