//
//  ViewController.swift
//  CPX+BLE
//
//  Created by Trevor B on 8/14/19.
//  Copyright © 2019 Adafruit Industries LLC. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    
   
    override func viewDidLoad() {
        super.viewDidLoad()

        print("Test")
        
    }
 
    @IBAction func unwindToMain(_sender: UIStoryboardSegue){}
    
}




@IBDesignable
class CustomUILabel: UISlider {
    
    @IBInspectable var label_Rotation: Double = 0 {
        didSet {
            rotateLabel(labelRotation: label_Rotation)
            self.layoutIfNeeded()
        }
    }
    
    func rotateLabel(labelRotation: Double)  {
        self.transform = CGAffineTransform(rotationAngle: CGFloat((Double.pi * 2) + labelRotation))
    }
}


@IBDesignable
class DesignableView: UIView {
}

@IBDesignable
class DesignableButton: UIButton {
}

@IBDesignable
class DesignableLabel: UILabel {
}


extension UIView {

    
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }


    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }


}



