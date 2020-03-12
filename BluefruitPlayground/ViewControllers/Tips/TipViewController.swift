//
//  TipViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 09/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import ActiveLabel

class TipViewController: UIViewController {
    // Constants
    static let kIdentifier = "TipViewController"

    // UI
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: ActiveLabel!
    @IBOutlet weak var actionButton: UIButton!

    // Params
    var titleText: String? {
        didSet {
            loadViewIfNeeded()
            titleLabel.text = titleText
        }
    }
    
    var detailTextLocalizationStringPrefix: String? {
        didSet {
            loadViewIfNeeded()
            
            if let detailTextLocalizationStringPrefix = detailTextLocalizationStringPrefix {
                ActiveLabelUtils.addActiveLabelLinks(label: detailLabel, linksLocalizationStringsIdPrefix: detailTextLocalizationStringPrefix)
            }
            else {
                DLog("Warning: detailTextLocalizationStringPrefix is nil")
            }
        }
    }

    var actionText: String? {
        didSet {
            loadViewIfNeeded()
            actionButton.setTitle(actionText, for: .normal)
        }
    }

    var actionHandler: (() -> Void)?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        containerView.layer.cornerRadius = 8
        containerView.layer.masksToBounds = true
    }

    @IBAction func action(_ sender: Any) {
        actionHandler?()
    }
}
