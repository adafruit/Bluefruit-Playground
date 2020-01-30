//
//  AboutViewController.swift
//  Bluefruit Connect
//
//  Created by Antonio García on 14/02/16.
//  Copyright © 2016 Adafruit. All rights reserved.
//

import UIKit
import ActiveLabel

class AboutViewController: UIViewController {
    // Constants
    static let kIdentifier = "AboutNavigationController"//"AboutViewController"
    
    // UI
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var messageLabel: ActiveLabel!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Get version
        if let shortVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"]  as? String {
            versionLabel.text = "Version \(shortVersion)"
        }

        // Text
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("about_title")
        
        appNameLabel.text = localizationManager.localizedString("about_app_name")
        messageLabel.text  = localizationManager.localizedString("about_ios_text")
        
        doneButton.title = localizationManager.localizedString("dialog_done")
        
        
        messageLabel.customize { label in
            //let strongString = localizationManager.localizedString("about_ios_strong_text")
            
            let linkString0 = localizationManager.localizedString("about_ios_link0_text")
            let linkString1 = localizationManager.localizedString("about_ios_link1_text")

            //let customType = ActiveType.custom(pattern: "(\\w*\(strongString)\\w*)")
            let customType0 = ActiveType.custom(pattern: "(\\w*\(linkString0)\\w*)")
            let customType1 = ActiveType.custom(pattern: "(\\w*\(linkString1)\\w*)")
            label.enabledTypes = [/*customType,*/ customType0, customType1]
            
            let color = UIColor(named: "text_link")
            let selectedColor = color?.lighter()

            // label.customColor[customType] = messageLabel.textColor.lighter()
            
            label.customColor[customType0] = color
            label.customSelectedColor[customType0] = selectedColor
            label.customColor[customType1] = color
            label.customSelectedColor[customType1] = selectedColor

            label.handleCustomTap(for: customType0) { element in
                if let url = URL(string: localizationManager.localizedString("about_ios_link0_url")) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }

            label.handleCustomTap(for: customType1) { element in
                if let url = URL(string: localizationManager.localizedString("about_ios_link1_url")) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            
            label.configureLinkAttribute = { (type, attributes, isSelected) in
                var atts = attributes
                switch type {
                case customType0, customType1:
                    atts[.underlineStyle] = NSUnderlineStyle.single.rawValue
                default: ()
                }
                
                return atts
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Actions
    @IBAction func onClickDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
