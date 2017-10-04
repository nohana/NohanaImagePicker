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

class AlbumListEmptyIndicator: UILabel {

    init(message: String, description: String, frame: CGRect, config: NohanaImagePickerController.Config) {
        super.init(frame: frame)

        let centerStyle = NSMutableParagraphStyle()
        centerStyle.alignment = NSTextAlignment.center

        let messageAttributes = [
            NSAttributedStringKey.foregroundColor : config.color.empty ?? UIColor(red: 0x88/0xff, green: 0x88/0xff, blue: 0x88/0xff, alpha: 1),
            NSAttributedStringKey.font : UIFont.systemFont(ofSize: 26),
            NSAttributedStringKey.paragraphStyle : centerStyle
        ]
        let messageText = NSAttributedString(string: message, attributes: messageAttributes)

        let descriptionAttributes = [
            NSAttributedStringKey.foregroundColor : config.color.empty ?? UIColor(red: 0x88/0xff, green: 0x88/0xff, blue: 0x88/0xff, alpha: 1),
            NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14),
            NSAttributedStringKey.paragraphStyle : centerStyle
        ]
        let descriptionText = NSAttributedString(string: description, attributes: descriptionAttributes)

        let attributedText = NSMutableAttributedString()
        attributedText.append(messageText)
        attributedText.append(NSAttributedString(string: "\n\n", attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 6)]))
        attributedText.append(descriptionText)

        self.numberOfLines = 0
        self.attributedText = attributedText
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
