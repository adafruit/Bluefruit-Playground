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
    @IBOutlet weak var contentStackView: UIStackView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Text
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("help_title")
        doneButton.title = localizationManager.localizedString("dialog_done")
    }
        
    // MARK: - Add Items
    func addMessage(_ message: String) {
        loadViewIfNeeded()
        
        let label = UILabel()
        label.textColor = UIColor(named: "text_default")
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.text = message
        contentStackView.addArrangedSubview(label)
    }
    
    func addImage(_ image: UIImage) {
        loadViewIfNeeded()

        let imageView = UIImageView(image: image)
        contentStackView.addArrangedSubview(imageView)
    }
    
    // MARK: - Actions
    @IBAction func onClickDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
