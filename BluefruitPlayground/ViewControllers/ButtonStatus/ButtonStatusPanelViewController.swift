//
//  ButtonStatusPanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 18/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class ButtonStatusPanelViewController: ModulePanelViewController {
    // Constants
    static let kIdentifier = "ButtonStatusPanelViewController"
    
    // UI
    @IBOutlet weak var switchLabel: UILabel!
    @IBOutlet weak var buttonALabel: UILabel!
    @IBOutlet weak var buttonBLabel: UILabel!
    
    @IBOutlet weak var switchImageView: UIImageView!
    @IBOutlet weak var buttonAStatusView: UIView!
    @IBOutlet weak var buttonBStatusView: UIView!

    // Data
    private var onColor: UIColor!
    private var offColor: UIColor!
    private var currentState = BlePeripheral.ButtonsState(slideSwitch: .left, buttonA: .released, buttonB: .released)
    private var isFirstTimeReceivingSwitchState = true
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the storyboard colors as on/off colors
        onColor = switchImageView.tintColor
        offColor = buttonAStatusView.tintColor
        
        // Init
        switchImageView.tintColor = offColor
            
        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("buttonstatus_panel_title")
        switchLabel.text = localizationManager.localizedString("buttonstatus_panel_switch")
        buttonALabel.text = localizationManager.localizedString("buttonstatus_panel_button_a")
        buttonBLabel.text = localizationManager.localizedString("buttonstatus_panel_button_b")
    }
    
    // MARK: - Animation
    private func animateState(view: UIView, isPressed: Bool) {
        if isPressed {
            animateDown(view: view)
        }
        else {
            animateUp(view: view)
        }
    }
    
    private func animateDown(view: UIView) {
        UIView.animate(withDuration: 0.2) {
            view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            view.tintColor = self.onColor
        }
    }
    
    private func animateUp(view: UIView) {
        UIView.animate(withDuration: 0.15) {
            view.transform = .identity
            view.tintColor = self.offColor
        }
    }
    
    // MARK: - Data
    func buttonsStateReceived(_ buttonsState: BlePeripheral.ButtonsState) {
        
        if buttonsState.slideSwitch != currentState.slideSwitch || isFirstTimeReceivingSwitchState {
            let isSwitchLeft = buttonsState.slideSwitch == .left
            switchImageView.image = UIImage(named: isSwitchLeft ? "status_left":"status_right")
            
            if !isFirstTimeReceivingSwitchState {
                animateState(view: switchImageView, isPressed: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.animateState(view: self.switchImageView, isPressed: false)
                }
            }
            isFirstTimeReceivingSwitchState = false
        }
        
        if buttonsState.buttonA != currentState.buttonA {
            animateState(view: buttonAStatusView, isPressed: buttonsState.buttonA == .pressed)
        }
        
        if buttonsState.buttonB != currentState.buttonB {
            animateState(view: buttonBStatusView, isPressed: buttonsState.buttonB == .pressed)
        }
        
        currentState =  buttonsState
    }
}
