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
        
        var titleStringId: String {
            switch self {
            case .color: return "modules_color_title"
            case .light: return "modules_light_title"
            case .button: return "modules_button_title"
            case .tone: return "modules_tone_title"
            case .accelerometer: return "modules_accelerometer_title"
            case .temperature: return "modules_temperature_title"
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
            }
        }
    }
    
    private let menuItems: [Modules] = [.color, .light, .button, .tone, .accelerometer, .temperature]
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI
        let topContentInsetForDetails: CGFloat = 20
        baseTableView.contentInset = UIEdgeInsets(top: topContentInsetForDetails, left: 0, bottom: 0, right: 0)
        
        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("modules_title")
    }
}


// MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2        // Details + Modules
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else {
            return menuItems.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = indexPath.section == 0 ? "DetailsCell" : "ModuleCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        // Add cell data here instead of using willDisplay to avoid problems with automatic dimension calculation
        let localizationManager = LocalizationManager.shared
        let isDetails = indexPath.section == 0
        
        if isDetails {
            let detailsCell = cell as! TitleTableViewCell
            detailsCell.titleLabel.text = localizationManager.localizedString("modules_subtitle")
        }
        else {
            let moduleCell = cell as! CommonTableViewCell
            let menuItem = menuItems[indexPath.row]
            
            let titleStringId = menuItem.titleStringId
            moduleCell.titleLabel.text = localizationManager.localizedString(titleStringId)
            
            let subtitleStringId = menuItem.subtitleStringId
            moduleCell.subtitleLabel?.text = localizationManager.localizedString(subtitleStringId)
            
            //moduleCell.setPanelBackgroundColor(menuItem.color)
            moduleCell.iconImageView.backgroundColor = menuItem.color
            moduleCell.iconImageView.layer.borderColor = UIColor(named: "text_default")?.cgColor
            moduleCell.iconImageView.layer.borderWidth = 1
            moduleCell.iconImageView.layer.cornerRadius = 7
            moduleCell.iconImageView.layer.masksToBounds = true
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

        let isDetails = indexPath.section == 0
        guard !isDetails else { return }
        
        guard let module = Modules(rawValue: indexPath.row) else { return }
        var storyboardId: String? = nil
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
        }
        
        if let identifier = storyboardId, let viewController = storyboard?.instantiateViewController(withIdentifier: identifier) {
            
            self.show(viewController, sender: self)
        }

    }
}
