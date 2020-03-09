//
//  NeopixelsBoardViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 07/03/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit


protocol NeopixelsBoardViewControllerDelegate: class {
    func neopixelBoardSelectionChanged()
}

/**
 Common functionality for boards with neopixels
 Takes care of the basic setup of the neopixels
 */
class NeopixelsBoardViewController: UIViewController {
    // Constants
    private static let kSelectedBorderWidth: CGFloat = 3
    private static let kUnselectedButtonAlpha: CGFloat = 0.02       // Not 0 because it is automatically hidden by the OS and breaks interaction
    
    // UI
    @IBOutlet weak var neopixelsContainerView: UIView!
    @IBOutlet weak var neopixelsContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var neopixelViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsContainerView: UIView?            // Selection will be disabled if this is nil

    // Params
    weak var delegate: NeopixelsBoardViewControllerDelegate?

    // Data
    private var currentScale: CGFloat = 0
    private var isFirstTime = true
    private var numNeopixels: Int {
        return self.neopixelsContainerView.subviews.count
    }
    
    var isSelectionEnabled: Bool {          // Selection is enabled if buttonsContainerView is defined
        return buttonsContainerView != nil
    }
    private(set) var isNeopixelSelected: [Bool] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isNeopixelSelected = [Bool](repeating: false, count: numNeopixels)
        
        // Make neopixels round
        for neopixelView in neopixelsContainerView.subviews {
            neopixelView.layer.cornerRadius = neopixelViewWidthConstraint.constant / 2
            neopixelView.layer.masksToBounds = true
            //neopixelView.layer.borderColor = UIColor.yellow.cgColor
        }
        
        // Init neopixels color
        for neopixelView in self.neopixelsContainerView.subviews {
            neopixelView.backgroundColor = .clear
        }
        //neopixelsReset(animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Create a button for each neopixel
        if isFirstTime {
            createButtons()
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            
            isFirstTime = false
        }
        
        // Notifications
        registerNotifications(enabled: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Notifications
        registerNotifications(enabled: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update Neopixels scale to match the aspect fit circuit image
        let originalSize = neopixelsContainerWidthConstraint.constant
        let minDimension = min(self.view.bounds.width, self.view.bounds.height)
        let scale = minDimension / originalSize
        currentScale = scale
        
        let halfOriginalSize = originalSize/2
        var transform = CGAffineTransform(translationX: -halfOriginalSize, y: -halfOriginalSize)        // Move pivot to top-left
        transform = transform.scaledBy(x: scale, y: scale)      // Scale
        transform = transform.translatedBy(x: halfOriginalSize, y: halfOriginalSize)    // Revert pivot
        transform = transform.translatedBy(x: (self.view.bounds.width - minDimension) / (2 * scale), y: (self.view.bounds.height - minDimension) / (2 * scale))     // Center in circuit image
        
        neopixelsContainerView.transform = transform
        
        // Update buttons position. Buttons should be position over the neopixel but they should have at least 44points size to be touchable
        if let buttonsContainerView = buttonsContainerView {
            buttonsContainerView.transform = transform
            let selectedWidth = NeopixelsBoardViewController.kSelectedBorderWidth / scale
            for (i, button) in buttonsContainerView.subviews.enumerated() where neopixelsContainerView.subviews.count > i {
                button.center = neopixelsContainerView.subviews[i].center
                button.layer.borderWidth = selectedWidth
            }
        }
    }
    
    // MARK: - Notifications
    private var didUpdateNeopixelLightSequenceObserver: NSObjectProtocol?
    
    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            didUpdateNeopixelLightSequenceObserver = notificationCenter.addObserver(forName: .didUpdateNeopixelLightSequence, object: nil, queue: nil) { [weak self] notification in
                guard let self = self else { return }
                
                // Get current colors
                guard let pixelsBytes = notification.userInfo?[AdafruitBoard.NotificationUserInfoKey.value.rawValue] as? [[UInt8]] else { return }
                
                // Pixel Bytes are GRB
                let pixelColors = pixelsBytes.map { UIColor(red: CGFloat($0[1])/255.0, green: CGFloat($0[0])/255.0, blue: CGFloat($0[2])/255.0, alpha: 1.0) }
                
                // Update UI colors (on main thread)
                DispatchQueue.main.async {
                    for (i, neopixelView) in self.neopixelsContainerView.subviews.enumerated() where i < pixelColors.count {
                        neopixelView.backgroundColor = pixelColors[i]
                    }
                }
            }
        } else {
            if let didUpdateNeopixelLightSequenceObserver = didUpdateNeopixelLightSequenceObserver {notificationCenter.removeObserver(didUpdateNeopixelLightSequenceObserver)}
        }
    }
    
    // MARK: - UI
    private func createButtons() {
        guard let buttonsContainerView = buttonsContainerView else { return }
        
        for i in 0..<numNeopixels {
            let button = UIButton(type: .custom)
            button.tag = i
            button.setTitle(nil, for: .normal)
            
            let size = 37 / currentScale
            button.frame = CGRect(x: 0, y: 0, width: size, height: size)
            button.addTarget(self, action: #selector(neopixelTapped(_:)), for: .touchUpInside)
            //button.addTarget(self, action: #selector(neopixelDoubleTapped(_:event:)), for: .touchDownRepeat)
            
            button.layer.borderColor = UIColor.yellow.cgColor
            //button.backgroundColor = UIColor.green
            button.alpha = NeopixelsBoardViewController.kUnselectedButtonAlpha     // Start unselected
            
            buttonsContainerView.addSubview(button)
        }
    }
    
    private func animateCurrentNeopixelSelection() {
        for i in 0..<numNeopixels {
            updateNeopixelSelection(neopixelId: i, isSelected: isNeopixelSelected[i], animated: true)
        }
    }
    
    public func updateNeopixelSelection(neopixelId: Int, isSelected: Bool, animated: Bool) {
        guard let buttonsContainerView = buttonsContainerView else { return }
        guard neopixelId < buttonsContainerView.subviews.count else { return }
        
        let selectedView = buttonsContainerView.subviews[neopixelId]
        
        if animated {
            // Pre-animation state
            selectedView.transform = isSelected ? CGAffineTransform(scaleX: 1.2, y: 1.2):.identity
            
            // Animate
            UIView.animate(withDuration: 0.2, animations: {
                selectedView.transform = isSelected ? .identity:CGAffineTransform(scaleX: 1.2, y: 1.2)
                selectedView.alpha = isSelected ? 1:NeopixelsBoardViewController.kUnselectedButtonAlpha
            }) { (_) in
                selectedView.transform = .identity
            }
        } else {
            selectedView.alpha = isSelected ? 1:NeopixelsBoardViewController.kUnselectedButtonAlpha
        }
    }
    
    // MARK: - Actions
    func setNeopixelsColor(_ color: UIColor, onlySelected: Bool, animated: Bool, baseColor: UIColor? = nil) {
        
        let board = AdafruitBoardsManager.shared.currentBoard
        if onlySelected {
            board?.neopixelSetPixelColor(color, pixelMask: isNeopixelSelected)
        } else {
            board?.neopixelSetAllPixelsColor(color)
        }
        
        // UI Animation
        UIView.animate(withDuration: animated ? 0.1: 0) {
            // Base color is the color withouth the brightness. Used in the circuit representation to show the colors more vividly
            for (i, neopixelView) in self.neopixelsContainerView.subviews.enumerated() {
                if i < self.isNeopixelSelected.count && (!onlySelected || self.isNeopixelSelected[i]) {
                    neopixelView.backgroundColor = baseColor ?? color
                }
            }
        }
    }
    
    func neopixelSelectAll(animated: Bool) {
        for i in 0..<numNeopixels {
            isNeopixelSelected[i] = true
            updateNeopixelSelection(neopixelId: i, isSelected: true, animated: animated)
        }
    }
    
    func neopixelClear() {
        for i in 0..<numNeopixels {
            isNeopixelSelected[i] = false
            updateNeopixelSelection(neopixelId: i, isSelected: false, animated: true)
        }
    }
    
    func neopixelsReset(animated: Bool) {
        setNeopixelsColor(.clear, onlySelected: false, animated: animated)
    }
    
    func showSelectionAnimated(_ show: Bool) {
        guard let buttonsContainerView = buttonsContainerView else { return }

        if buttonsContainerView.alpha != 1 && show {
            animateCurrentNeopixelSelection()
        }
        //neopixelsContainerView.alpha = show ? 1:0
        buttonsContainerView.alpha = show ? 1:0
    }
    
    @objc private func neopixelTapped(_ sender: UIButton) {
        guard sender.tag < isNeopixelSelected.count else { return }
        DLog("neopixel \(sender.tag) tapped")
        
        isNeopixelSelected[sender.tag] = !isNeopixelSelected[sender.tag]
        updateNeopixelSelection(neopixelId: sender.tag, isSelected: isNeopixelSelected[sender.tag], animated: true)
        delegate?.neopixelBoardSelectionChanged()
    }
    
    /*
     @objc private func neopixelDoubleTapped(_ sender: UIButton, event: UIEvent) {
     guard sender.tag < isNeopixelSelected.count else { return }
     DLog("taps: \(event.allTouches?.first?.tapCount ?? -1)")
     guard let touch = event.allTouches?.first, touch.tapCount == 2 else { return }
     DLog("neopixel \(sender.tag) double tapped")
     
     for i in 0..<isNeopixelSelected.count {
     isNeopixelSelected[i] = i == sender.tag
     }
     animateCurrentNeopixelSelection()
     delegate?.neopixelBoardSelectionChanged()
     }*/
    
}
