//
//  PuppetPanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 03/02/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit
import ReplayKit

protocol PuppetPanelViewControllerDelegate: class {
    func puppetPanelSwitchCamera()
    func puppetPanelSwitchScreenMode()
    func puppetPanelSwitchRecording()
    func puppetPanelFullScreen()
}

class PuppetPanelViewController: ModulePanelViewController {
    // Constants
    static let kIdentifier = "PuppetPanelViewController"
    
    // UI
    @IBOutlet weak var recordButton: UIButton!
    
    // Params
    weak var delegate: PuppetPanelViewControllerDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("puppet_panel_title")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateRecordButtonUI()
    }
    
    // MARK: - UI
    func updateRecordButtonUI() {
        recordButton.isEnabled = RPScreenRecorder.shared().isAvailable
    }
    
    // MARK: - Actions
    @IBAction func switchCamera(_ sender: Any) {
        delegate?.puppetPanelSwitchCamera()
    }
    
    @IBAction func switchScreenMode(_ sender: Any) {
        delegate?.puppetPanelSwitchScreenMode()
    }
    
    @IBAction func switchRecording(_ sender: Any) {
        delegate?.puppetPanelSwitchRecording()
    }
    
    @IBAction func fullScreen(_ sender: Any) {
        delegate?.puppetPanelFullScreen()
    }
}

