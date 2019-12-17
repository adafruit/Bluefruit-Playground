//
//  CornerShadowButton.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 12/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

@IBDesignable
class CornerShadowButton: UIButton {
    
    // Params
    @IBInspectable var cornerRadius: CGFloat = 8 { didSet{updateLayerProperties()} }
    @IBInspectable var fillColor = UIColor(named: "main")! { didSet{updateLayerProperties()} }
    @IBInspectable var shadowColor = UIColor.darkGray { didSet{updateLayerProperties()} }
    @IBInspectable var shadowOffset = CGSize(width: 2, height: 2) { didSet{updateLayerProperties()} }
    @IBInspectable var shadowRadius: CGFloat = 2 { didSet{updateLayerProperties()} }
    @IBInspectable var shadowOpacity: Float = 0.8 { didSet{updateLayerProperties()} }
    
    // Data
    private var shadowLayer: CAShapeLayer?
    private var originalFillColor: UIColor!
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        originalFillColor = fillColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if shadowLayer == nil {
            shadowLayer = CAShapeLayer()
            updateLayerProperties()
            layer.insertSublayer(shadowLayer!, at: 0)
        }
    }
    
    private func updateLayerProperties() {
        guard let shadowLayer = shadowLayer else { return }
        
        shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        shadowLayer.fillColor = fillColor.cgColor

        shadowLayer.shadowColor = shadowColor.cgColor
        shadowLayer.shadowPath = shadowLayer.path
        shadowLayer.shadowOffset = shadowOffset
        shadowLayer.shadowOpacity = shadowOpacity
        shadowLayer.shadowRadius = shadowRadius
    }
    
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                fillColor = originalFillColor.lighter()
            }
            else {
                fillColor = originalFillColor
            }
        }
    }
    
}

