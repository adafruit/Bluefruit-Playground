//
//  ScanProblemsViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 22/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import ActiveLabel

class ScanProblemsViewController: UIViewController {

    // UI
    @IBOutlet weak var baseTableView: UITableView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup UI
        baseTableView.tableFooterView = UIView()

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("scannerproblems_title")
    }
}

// MARK: - UITableViewDataSource
extension ScanProblemsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "HelpCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! HelpTableViewCell

        let localizationManager = LocalizationManager.shared
        cell.bulletLabel.text = "\(indexPath.row + 1)"
        cell.titleLabel.text = localizationManager.localizedString("scannerproblems_tip\(indexPath.row)_title")
        cell.detailsLabel.text = localizationManager.localizedString("scannerproblems_tip\(indexPath.row)_details")

        cell.detailsLabel.customize { label in
            let linkString = localizationManager.localizedString("scannerproblems_tip\(indexPath.row)_link_text")

            let customType = ActiveType.custom(pattern: "(\\w*\(linkString)\\w*)")
            label.enabledTypes = [customType]
            label.customColor[customType] = UIColor(named: "text_link")
            label.customSelectedColor[customType] = UIColor(named: "text_link")?.lighter()

            label.handleCustomTap(for: customType) { _ in
                if let url = URL(string: localizationManager.localizedString("scannerproblems_tip\(indexPath.row)_link_url")) {
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

        if indexPath.row == 0 {
            cell.extraContainerView.isHidden = false
            cell.extraImageView.image = UIImage(named: "scanproblems_powerup")
        }
        return cell
    }
}

// MARK: UITableViewDelegate
extension ScanProblemsViewController: UITableViewDelegate {

    /*
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }*/

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

    }
}
