//
//  MomentCell.swift
//  NohanaImagePicker
//
//  Created by kazushi.hara on 2016/03/23.
//  Copyright © 2016年 nohana. All rights reserved.
//

import UIKit

class MomentCell: AlbumCell {
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let lineWidth: CGFloat = 1 / UIScreen.mainScreen().scale
        ColorConfig.AlbumList.momentCellSeparator.setFill()
        UIRectFill(CGRect(x: 16, y: frame.size.height - lineWidth, width: frame.size.width, height:lineWidth))
    }

}
