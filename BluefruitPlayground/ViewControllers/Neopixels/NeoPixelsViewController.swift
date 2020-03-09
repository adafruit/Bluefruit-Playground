//
//  NeoPixelsViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 12/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

// Note: canCancelContentTouch set to false on baseScrollView because FlexiColor
class NeoPixelsViewController: ModuleViewController {
    // Constants
    static let kIdentifier = "NeoPixelsViewController"

    // UI
    @IBOutlet weak var boardContainerView: UIView!
    @IBOutlet weak var selectAllButton: UIButton!
    @IBOutlet weak var unselectAllButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!

    // Data
    private var neopixelBoardViewController: NeopixelsBoardViewController?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add main view
        self.neopixelBoardViewController = addBoardViewController()
        
        // Add panels
        _ = addPanelViewController(storyboardIdentifier: NeopixelsLightSequenceViewController.kIdentifier)

        let colorPaletteViewController = addPanelViewController(storyboardIdentifier: NeopixelsColorPaletteViewController.kIdentifier) as! NeopixelsColorPaletteViewController
        colorPaletteViewController.delegate = self

        let colorWheelViewController = addPanelViewController(storyboardIdentifier: NeopixelsColorWheelViewController.kIdentifier) as! NeopixelsColorWheelViewController
        colorWheelViewController.delegate = self

        // UI Initial state
        showSelectionButtons(false)
        neopixelBoardViewController?.showSelectionAnimated(false)
        neopixelBoardViewController?.neopixelSelectAll(animated: false)

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("neopixels_title")

        var textStringId: String? 
        if let model = AdafruitBoardsManager.shared.currentBoard?.model {
            switch model {
            case .circuitPlaygroundBluefruit:
                textStringId = "neopixels_help_cpb"
            case .clue_nRF52840:
                textStringId = "neopixels_help_clue"
            default:
                textStringId = nil
            }
        }
        
        moduleHelpMessage = textStringId == nil ? nil : localizationManager.localizedString(textStringId!)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        neopixelBoardViewController?.neopixelsReset(animated: false)
    }

    // MARK: - UI
    private func addBoardViewController() -> NeopixelsBoardViewController? {
        guard let model = AdafruitBoardsManager.shared.currentBoard?.model else { return nil }
        
        let storyboardIdentifier: String?
        switch model {
        case .circuitPlaygroundBluefruit:
            storyboardIdentifier = CPBBoardViewController.kIdentifier
        case .clue_nRF52840:
            storyboardIdentifier = ClueBackBoardViewController.kIdentifier
        default:
            storyboardIdentifier = nil
        }
        
        guard let identifier = storyboardIdentifier, let viewController = storyboard?.instantiateViewController(withIdentifier: identifier) as? NeopixelsBoardViewController else { return nil }
        
        ChildViewControllersManagement.addChildViewController(viewController, contentView: boardContainerView, parentViewController: self)
        
        return viewController
    }
    
    // MARK: - Actions
    @IBAction func neopixelsSelectAll(_ sender: Any) {
        neopixelBoardViewController?.neopixelSelectAll(animated: true)
    }

    @IBAction func neopixelsClear(_ sender: Any) {
        neopixelBoardViewController?.neopixelClear()
    }

    @IBAction func neopixelsReset(_ sender: Any) {
        neopixelBoardViewController?.neopixelsReset(animated: true)
    }

    private func selectColor(_ color: UIColor, baseColor: UIColor) {
        // Update board
        neopixelBoardViewController?.setNeopixelsColor(color, onlySelected: true, animated: true, baseColor: baseColor)
    }

    // MARK: - Page Management
    override func onPageChanged(_ page: Int) {
        super.onPageChanged(page)

        let areNeopixelsVisible = page != 0
        UIView.animate(withDuration: 0.2) {
            self.showSelectionButtons(areNeopixelsVisible)
        }
        self.neopixelBoardViewController?.showSelectionAnimated(areNeopixelsVisible)
    }

    private func showSelectionButtons(_ show: Bool) {
        guard !show || neopixelBoardViewController?.isSelectionEnabled ?? false else { return }     // Don't show if isSelectionEnabled is false
        
        selectAllButton.alpha = show ? 1:0
        unselectAllButton.alpha = show ? 1:0
    }
}

// MARK: - NeopixelsColorPaletteViewControllerDelegate
extension NeoPixelsViewController: NeopixelsColorPaletteViewControllerDelegate {
    func colorPaletteColorSelected(color: UIColor, baseColor: UIColor) {
        selectColor(color, baseColor: baseColor)
    }
}

// MARK: - NeopixelColorWheelViewControllerDelegate
extension NeoPixelsViewController: NeopixelColorWheelViewControllerDelegate {
    func colorWheelColorSelected(color: UIColor, baseColor: UIColor) {
        selectColor(color, baseColor: baseColor)
    }
}
