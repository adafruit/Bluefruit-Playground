//
//  ButtonStatusViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 18/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class ButtonStatusViewController: ModuleViewController {
    // Constants
    static let kIdentifier = "ButtonStatusViewController"

    // Data
    private var buttonsStatePanelViewController: ButtonStatusPanelViewController!
    private var buttonsState: BlePeripheral.ButtonsState?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add panels
        buttonsStatePanelViewController = (addPanelViewController(storyboardIdentifier: ButtonStatusPanelViewController.kIdentifier) as! ButtonStatusPanelViewController)

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("buttonstatus_title")
        moduleHelpMessage = localizationManager.localizedString("buttonstatus_help")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Initial value
        self.buttonsState = AdafruitBoard.shared.buttonsLastValue()
        updateValueUI()

        // Set delegate
        AdafruitBoard.shared.buttonsDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove delegate
        AdafruitBoard.shared.buttonsDelegate = nil
    }

    // MARK: - UI
    private func updateValueUI() {
        if let buttonsState = self.buttonsState {
            buttonsStatePanelViewController.buttonsStateReceived(buttonsState)
        }
    }
}

// MARK: - CPBBleButtonsDelegate
extension ButtonStatusViewController: AdafruitButtonsDelegate {
    func cpbleButtonsReceived(_ buttonsState: BlePeripheral.ButtonsState) {
        self.buttonsState = buttonsState
        updateValueUI()
    }
}
