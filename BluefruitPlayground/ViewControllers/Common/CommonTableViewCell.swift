//
//  CommonTableViewCell.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 11/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class CommonTableViewCell: UITableViewCell {

    // UI
    @IBOutlet weak var panelView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel?

    // Data
    private var originalPanelBackgroundColor: UIColor!

    // MARK: - View Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()

        panelView.layer.borderColor = UIColor.init(white: 1, alpha: 0.5).cgColor//UIColor.darkGray.cgColor
        panelView.layer.cornerRadius = 8
        panelView.layer.masksToBounds = true

        originalPanelBackgroundColor = panelView.backgroundColor
    }

    func setPanelBackgroundColor(_ color: UIColor) {
        panelView.backgroundColor = color
        originalPanelBackgroundColor = color
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        subtitleLabel?.text = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        highlight(selected)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        highlight(highlighted)
    }

    private func highlight(_ highlighted: Bool) {
        panelView.layer.borderWidth = highlighted ? 1:0
        panelView.backgroundColor = highlighted ? originalPanelBackgroundColor.darker(0.15) : originalPanelBackgroundColor
    }
}
