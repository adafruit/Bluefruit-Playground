//
//  HomeViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 12/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    // Constants
    static let kNavigationControllerIdentifier = "ModulesNavigationController"
    static let kIdentifier = "HomeViewController"

    // UI
    @IBOutlet weak var baseTableView: UITableView!

    // Data
    private enum Modules: Int {
        case color = 0
        case light
        case button
        case tone
        case accelerometer
        case temperature
        case puppet

        var titleStringId: String {
            switch self {
            case .color: return "modules_color_title"
            case .light: return "modules_light_title"
            case .button: return "modules_button_title"
            case .tone: return "modules_tone_title"
            case .accelerometer: return "modules_accelerometer_title"
            case .temperature: return "modules_temperature_title"
            case .puppet: return "modules_puppet_title"
            }
        }

        var subtitleStringId: String {
            switch self {
            case .color: return "modules_color_subtitle"
            case .light: return "modules_light_subtitle"
            case .button: return "modules_button_subtitle"
            case .tone: return "modules_tone_subtitle"
            case .accelerometer: return "modules_accelerometer_subtitle"
            case .temperature: return "modules_temperature_subtitle"
            case .puppet: return "modules_puppet_subtitle"
            }
        }

        var color: UIColor {
            switch self {
            case .color: return UIColor(named: "module_neopixels_color")!
            case .light: return UIColor(named: "module_light_color")!
            case .button: return UIColor(named: "module_buttons_color")!
            case .tone: return UIColor(named: "module_tone_color")!
            case .accelerometer: return UIColor(named: "module_accelerometer_color")!
            case .temperature: return UIColor(named: "module_temperature_color")!
            case .puppet: return UIColor(named: "module_puppet_color")!
            }
        }
    }

    private let menuItems: [Modules] = [.color, .light, .button, .tone, .accelerometer, .temperature, .puppet]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup UI
        /*
        let topContentInsetForDetails: CGFloat = 20
        baseTableView.contentInset = UIEdgeInsets(top: topContentInsetForDetails, left: 0, bottom: 0, right: 0)
        */

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("modules_title")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        /*
        if let customNavigationBar = navigationController?.navigationBar as? NavigationBarWithScrollAwareRightButton {
            customNavigationBar.setRightButton(topViewController: self, image: UIImage(named: "info"), target: self, action: #selector(about(_:)))
        }*/

        /*
        if let peripheral = Config.bleManager.connectedPeripherals().first {
            peripheral.readRssi()
        }*/
    }

    /*
    // MARK: - Actions
    @IBAction func about(_ sender: Any) {
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: AboutViewController.kIdentifier) else { return }
        
        self.present(viewController, animated: true, completion: nil)
    }*/
}

// MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource {
    enum CellType {
        case details
        case module
        case disconnect

        var reuseIdentifier: String {
            switch self {
            case .details: return "DetailsCell"
            case .module: return "ModuleCell"
            case .disconnect: return "DisconnectCell"
            }
        }
    }

    private func useDetailSection() -> Bool {
        return false
    }

    private func cellTypeFromIndexPath(_ indexPath: IndexPath) -> CellType {
         return useDetailSection() && indexPath.section == 0 ? .details : indexPath.row == menuItems.count ? .disconnect : .module
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return (useDetailSection() ? 1:0) + 1        // Details + Modules
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if useDetailSection() && section == 0 {
            return 1
        } else {
            return menuItems.count + 1 // + 1 disconnect
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellType = cellTypeFromIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellType.reuseIdentifier, for: indexPath)

        // Add cell data here instead of using willDisplay to avoid problems with automatic dimension calculation
        let localizationManager = LocalizationManager.shared

        switch cellType {
        case .details:
            let detailsCell = cell as! TitleTableViewCell
            detailsCell.titleLabel.text = localizationManager.localizedString("modules_subtitle")
            /*
             case .peripheral
             let peripheralCell = cell as! CommonTableViewCell
             if let peripheral = Config.bleManager.connectedPeripherals().first {
             // Fill peripheral data
             peripheralCell.titleLabel.text = peripheral.name ?? localizationManager.localizedString("scanner_unnamed")
             peripheralCell.iconImageView.image = RssiUI.signalImage(for: peripheral.rssi)
             }*/
        case .module:
            let moduleCell = cell as! CommonTableViewCell
            let menuItem = menuItems[indexPath.row]

            let titleStringId = menuItem.titleStringId
            moduleCell.titleLabel.text = localizationManager.localizedString(titleStringId)

            let subtitleStringId = menuItem.subtitleStringId
            moduleCell.subtitleLabel?.text = localizationManager.localizedString(subtitleStringId)

            moduleCell.iconImageView.backgroundColor = menuItem.color
            moduleCell.iconImageView.layer.borderColor = UIColor(named: "text_default")?.cgColor
            moduleCell.iconImageView.layer.borderWidth = 1
            moduleCell.iconImageView.layer.cornerRadius = 7
            moduleCell.iconImageView.layer.masksToBounds = true

        case .disconnect:
            let disconnectCell = cell as! CommonTableViewCell
            disconnectCell.titleLabel.text = localizationManager.localizedString("modules_disconnect_title")
            disconnectCell.subtitleLabel?.text = localizationManager.localizedString("modules_disconnect_subtitle")
        }

        return cell
    }
}

// MARK: UITableViewDelegate
extension HomeViewController: UITableViewDelegate {

    /*
     func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
     }*/

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let cellType = cellTypeFromIndexPath(indexPath)
        switch cellType {
        case .details:
            break
        case .module:
            if let module = Modules(rawValue: indexPath.row) {
                var storyboardId: String?
                switch module {
                case .color:
                    storyboardId = NeoPixelsViewController.kIdentifier
                case .light:
                    storyboardId = LightSensorViewController.kIdentifier
                case .button:
                    storyboardId = ButtonStatusViewController.kIdentifier
                case .tone:
                    storyboardId = ToneGeneratorViewController.kIdentifier
                case .accelerometer:
                    storyboardId = AccelerometerViewController.kIdentifier
                case .temperature:
                    storyboardId = TemperatureViewController.kIdentifier
                case .puppet:
                    storyboardId = PuppetViewController.kIdentifier
                }

                if let identifier = storyboardId, let viewController = storyboard?.instantiateViewController(withIdentifier: identifier) {

                    // Show viewController with completion block
                    CATransaction.begin()
                    self.show(viewController, sender: self)
                    CATransaction.setCompletionBlock({
                        // Flash neopixels with the module color
                        AdafruitBoard.shared.neopixelStartLightSequence(FlashLightSequence(baseColor: module.color), speed: 1, repeating: false, sendLightSequenceNotifications: false)
                    })
                    CATransaction.commit()
                }
            }

        case .disconnect:
            if let peripheral = Config.bleManager.connectedPeripherals().first {
                Config.bleManager.disconnect(from: peripheral, waitForQueuedCommands: true)
            }
        }
    }
}

/*
// MARK: UIScrollViewDelegate
extension HomeViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // NavigationBar Button Custom Animation
        if let customNavigationBar = navigationController?.navigationBar as? NavigationBarWithScrollAwareRightButton {
            customNavigationBar.updateRightButtonPosition()
        }
    }
}
 */
