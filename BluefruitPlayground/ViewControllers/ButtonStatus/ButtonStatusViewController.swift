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

    // UI
    @IBOutlet weak var boardContainerView: UIView!

    // Data
    private var buttonsStatePanelViewController: ButtonStatusPanelViewController!
    private var buttonsState: BlePeripheral.ButtonsState?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add main view
        addBoardView()
        
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
        let board = AdafruitBoardsManager.shared.currentBoard
        self.buttonsState = board?.buttonsLastValue()
        updateValueUI()

        // Set delegate
        board?.buttonsDelegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove delegate
        let board = AdafruitBoardsManager.shared.currentBoard
        board?.buttonsDelegate = nil
    }


    // MARK: - UI
    private func addBoardView() {
        guard let model = AdafruitBoardsManager.shared.currentBoard?.model else { return }
        
        let storyboardIdentifier: String?
        switch model {
        case .circuitPlaygroundBluefruit:
            storyboardIdentifier = CPBBoardViewController.kIdentifier
        case .clue_nRF52840:
            storyboardIdentifier = ClueFrontBoardViewController.kIdentifier
        default:
            storyboardIdentifier = nil
        }
        
        guard let identifier = storyboardIdentifier, let viewController = storyboard?.instantiateViewController(withIdentifier: identifier) else { return }

        ChildViewControllersManagement.addChildViewController(viewController, contentView: boardContainerView, parentViewController: self)
    }
    
    private func updateValueUI() {
        if let buttonsState = self.buttonsState {
            buttonsStatePanelViewController.buttonsStateReceived(buttonsState)
        }
    }

}

// MARK: - CPBBleButtonsDelegate
extension ButtonStatusViewController: AdafruitButtonsDelegate {
    func adafruitButtonsReceived(_ buttonsState: BlePeripheral.ButtonsState) {
        self.buttonsState = buttonsState
        updateValueUI()
    }
}
