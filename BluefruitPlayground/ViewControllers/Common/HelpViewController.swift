//
//  HelpViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 26/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class HelpViewController: UIViewController {
    // Constants
    static let kIdentifier = "HelpNavigationController"//"HelpViewController"
    
    // UI
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    // Params
    var message: String?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageLabel.text = message
        
        // Text
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("help_title")
        doneButton.title = localizationManager.localizedString("dialog_done")
    }
    
    // MARK: - Actions
    @IBAction func onClickDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
