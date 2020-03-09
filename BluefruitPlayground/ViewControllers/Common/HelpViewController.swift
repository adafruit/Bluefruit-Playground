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
    func addMessage(_ message: String?) {
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
        imageView.tintColor = UIColor(named: "text_default")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)

        // Add imageView inside container to adjust proportions
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.addSubview(imageView)

        imageView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true

        imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        //imageView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor).isActive = true
        //imageView.trailingAnchor.constraint(greaterThanOrEqualTo: containerView.trailingAnchor).isActive = true

        let proportionalWidthConstraint = imageView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.75)
        proportionalWidthConstraint.priority = UILayoutPriority(rawValue: 999)
        proportionalWidthConstraint.isActive = true
        imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 350).isActive = true        // Limit image to 350 width

        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: image.size.height / image.size.width).isActive = true

        contentStackView.addArrangedSubview(containerView)
    }

    // MARK: - Actions
    @IBAction func onClickDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
