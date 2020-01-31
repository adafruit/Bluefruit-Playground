//
//  ToneGeneratorViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class ToneGeneratorViewController: UIViewController {
    // Constants
    static let kIdentifier = "ToneGeneratorViewController"
    
    private static let kWhiteFrequencies: [Double] = [    // https://piano-music-theory.com/tag/middle-c/
        261.63,
        293.66,
        329.63,
        349.23,
        392,
        440,
        
        493.88,
        523.25,
        587.33,
        659.26,
        698.46,
        783.99,
    ]
    
    private static let kBlackFrequencies: [Double] = [      // https://newt.phys.unsw.edu.au/jw/notes.html
        277.18,
        311.13,
        
        369.99,
        415.30,
        466.16,
        
        554.37,
        622.25,
        
        739.99,
    ]

    // UI
    @IBOutlet weak var keysContainerView: UIView!
    @IBOutlet weak var whiteKeysStackView: UIStackView!
    @IBOutlet weak var speakerImageView: UIImageView!
    
    // Data
    private var tonesPlaying = Set<Int>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // UI
        let whiteKeyButtons = whiteKeysStackView.getAllSubviewsWithClass() as [UIButton]
        for button in whiteKeyButtons {
            button.layer.cornerRadius = 4
            button.layer.masksToBounds = true
            button.setBackgroundColor(color: .white, forState: .normal)     // Force normal color or the text will change position when the key is pressed
            button.setBackgroundColor(color: .lightGray, forState: .highlighted)
            button.addTarget(self, action: #selector(keyDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(keyUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        }
        
        let blackKeyViews = keysContainerView.subviews
        for view in blackKeyViews {
            if let button = view as? UIButton {
                button.roundCorners([.bottomLeft, .bottomRight], radius: 10)
                button.setBackgroundColor(color: .darkGray, forState: .highlighted)
                button.addTarget(self, action: #selector(keyDown(_:)), for: .touchDown)
                button.addTarget(self, action: #selector(keyUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            }
        }

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("tonegenerator_title")
    }
    
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           
           // Navigationbar setup
           if let customNavigationBar = navigationController?.navigationBar as? NavigationBarWithScrollAwareRightButton {
               customNavigationBar.setRightButton(topViewController: self, image: UIImage(named: "help"), target: self, action: #selector(help(_:)))
           }
       }
    
    // MARK: - Actions
    @objc private func keyDown(_ sender: UIButton) {
        let tag = sender.tag
        tonesPlaying.insert(tag)
        
        // UI Animation
        UIView.animate(withDuration: 0.2) {
            self.speakerImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        
        // Play
        if let frequency = frequencyForKeyTag(tag) {
            CPBBle.shared.toneGeneratorStartPlaying(frequency: UInt16(round(frequency)))
        }
    }
    
    @objc private func keyUp(_ sender: UIButton) {
        let tag = sender.tag
        tonesPlaying.remove(tag)
        
        // UI Animation
        if tonesPlaying.isEmpty {
            UIView.animate(withDuration: 0.15) {
                self.speakerImageView.transform = .identity
            }
        }
        
        // Play
        if let existingKeyTag = tonesPlaying.first, let frequency = frequencyForKeyTag(existingKeyTag) {
            CPBBle.shared.toneGeneratorStartPlaying(frequency: UInt16(round(frequency)))
        }
        else {
            CPBBle.shared.toneGeneratorStopPlaying()
        }
    }
    
    private func frequencyForKeyTag(_ tag: Int) -> Double? {
        var frequency: Double? = nil
        if tag >= 100 && tag < 200 {        // is white note
            let noteIndex = tag - 100
            if noteIndex < ToneGeneratorViewController.kWhiteFrequencies.count {
                frequency = ToneGeneratorViewController.kWhiteFrequencies[noteIndex]
            }
        }
        else if tag >= 200 && tag < 300 {     // is black note
            let noteIndex = tag - 200
            if noteIndex < ToneGeneratorViewController.kBlackFrequencies.count {
                frequency = ToneGeneratorViewController.kBlackFrequencies[noteIndex]
            }
        }
        
        return frequency
    }
    
    @IBAction func help(_ sender: Any) {
        guard let navigationController = storyboard?.instantiateViewController(withIdentifier: HelpViewController.kIdentifier) as? UINavigationController, let helpViewController = navigationController.topViewController as? HelpViewController else { return }
        helpViewController.message = LocalizationManager.shared.localizedString("tonegenerator_help")
        
        self.present(navigationController, animated: true, completion: nil)
    }
}
