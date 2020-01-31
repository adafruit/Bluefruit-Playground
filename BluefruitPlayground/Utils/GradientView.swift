//
//  GradientView.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 09/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

@IBDesignable
open class GradientView: UIView {
    @IBInspectable
    public var startColor: UIColor = .white {
        didSet {
            gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
            setNeedsDisplay()
        }
    }
    @IBInspectable
    public var endColor: UIColor = .white {
        didSet {
            gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    public var startPoint: CGPoint = CGPoint(x: 0, y: 0) {
        didSet {
            gradientLayer.startPoint  = startPoint
            setNeedsDisplay()
        }
    }

    @IBInspectable
    public var endPoint: CGPoint = CGPoint(x: 0, y: 1) {
        didSet {
            gradientLayer.endPoint  = endPoint
            setNeedsDisplay()
        }
    }
    
    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [self.startColor.cgColor, self.endColor.cgColor]
        return gradientLayer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
