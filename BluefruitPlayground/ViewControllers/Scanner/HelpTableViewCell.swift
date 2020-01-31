//
//  HelpTableViewCell.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 23/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import ActiveLabel

class HelpTableViewCell: UITableViewCell {

    // UI
    @IBOutlet weak var bulletContainerView: UIView!
    @IBOutlet weak var bulletLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: ActiveLabel!
    @IBOutlet weak var extraImageView: UIImageView!
    @IBOutlet weak var extraContainerView: UIView!
    
    
   // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        bulletContainerView.layer.borderColor = titleLabel.textColor.cgColor
        bulletContainerView.layer.borderWidth = 1
        bulletContainerView.layer.cornerRadius = 8
        bulletContainerView.layer.masksToBounds = true
        
        extraContainerView.layer.borderWidth = 1
        extraContainerView.layer.borderColor = UIColor.white.cgColor
        
        prepareForReuse()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        detailsLabel.text = nil
        extraImageView.image = nil
        extraContainerView.isHidden = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
