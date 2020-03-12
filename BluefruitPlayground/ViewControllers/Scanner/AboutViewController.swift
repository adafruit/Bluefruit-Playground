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
        doneButton.title = localizationManager.localizedString("dialog_done")

        ActiveLabelUtils.addActiveLabelLinks(label: messageLabel, linksLocalizationStringsIdPrefix: "about_ios")
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
