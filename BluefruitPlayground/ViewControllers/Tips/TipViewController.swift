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
    var detailText: String? {
        didSet {
            loadViewIfNeeded()
            detailLabel.text = detailText
        }
    }
    
    var detailTextLinkString: String? {
        didSet {
            loadViewIfNeeded()
            updateLink()
        }
    }

    var detailTextLinkUrl: URL? {
        didSet {
            loadViewIfNeeded()
            updateLink()
        }
    }
    
    var actionText: String? {
        didSet {
            loadViewIfNeeded()
            actionButton.setTitle(actionText, for: .normal)
        }
    }
    
    var actionHandler: (()->())?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.layer.cornerRadius = 8
        containerView.layer.masksToBounds = true
        
        //detailLabel.enabledTypes = [.url]
        
        updateLink()
    }
    
    @IBAction func action(_ sender: Any) {
        actionHandler?()
    }
    
    private func updateLink() {
        detailLabel.customize { label in
            guard let linkString = detailTextLinkString else { return }
            
            let customType = ActiveType.custom(pattern: "(\\w*\(linkString)\\w*)")
            label.enabledTypes = [customType]
            label.customColor[customType] = UIColor(named: "text_link")
            label.customSelectedColor[customType] = UIColor(named: "text_link")?.lighter()
            
            label.handleCustomTap(for: customType) { [unowned self] element in
                if let url = self.detailTextLinkUrl {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            label.configureLinkAttribute = { (type, attributes, isSelected) in
                var atts = attributes
                switch type {
                case customType:
                    atts[.underlineStyle] = NSUnderlineStyle.single.rawValue
                default: ()
                }
                return atts
            }
        }
    }
}
