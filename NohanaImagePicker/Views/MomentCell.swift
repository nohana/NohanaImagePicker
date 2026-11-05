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

class MomentCell: UICollectionViewListCell {
    private static let height: CGFloat = 52

    let titleLabel = UILabel()
    private let separatorView = UIView()

    var config: NohanaImagePickerController.Config! {
        didSet {
            separatorView.backgroundColor = config.color.separator ?? UIColor(red: 0xbb/0xff, green: 0xbb/0xff, blue: 0xbb/0xff, alpha: 1)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        // On the cell, not the content view, so that the line spans the safe area like the table view cell's line did.
        addSubview(separatorView)
        let height = contentView.heightAnchor.constraint(equalToConstant: MomentCell.height)
        // Lower than required so that it does not conflict with the temporary size the list gives the cell.
        height.priority = .defaultHigh
        NSLayoutConstraint.activate([
            height,
            titleLabel.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: AlbumCell.horizontalMargin + 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -AlbumCell.horizontalMargin + 8),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        backgroundConfiguration = .albumListCell(for: state)
    }
}
