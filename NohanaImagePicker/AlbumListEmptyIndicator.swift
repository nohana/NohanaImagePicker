//
//  AlbumListEmptyIndicator.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/03/23.
//  Copyright © 2016年 nohana. All rights reserved.
//

class AlbumListEmptyIndicator: UILabel {
    
    init(message: String, description: String, frame: CGRect) {
        super.init(frame: frame)
        
        let centerStyle = NSMutableParagraphStyle()
        centerStyle.alignment = NSTextAlignment.Center
        
        let messageAttributes = [
            NSForegroundColorAttributeName : ColorConfig.emptyIndicator,
            NSFontAttributeName : UIFont.systemFontOfSize(26),
            NSParagraphStyleAttributeName : centerStyle
        ]
        let messageText = NSAttributedString(string: message, attributes: messageAttributes)
        
        let descriptionAttributes = [
            NSForegroundColorAttributeName : ColorConfig.emptyIndicator,
            NSFontAttributeName : UIFont.systemFontOfSize(14),
            NSParagraphStyleAttributeName : centerStyle
        ]
        let descriptionText = NSAttributedString(string: description, attributes: descriptionAttributes)
        
        let attributedText = NSMutableAttributedString()
        attributedText.appendAttributedString(messageText)
        attributedText.appendAttributedString(NSAttributedString(string: "\n\n", attributes: [NSFontAttributeName : UIFont.systemFontOfSize(6)]))
        attributedText.appendAttributedString(descriptionText)
        
        self.numberOfLines = 0
        self.attributedText = attributedText
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}