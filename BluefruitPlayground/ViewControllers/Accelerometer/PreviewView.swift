//
//  PreviewView.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 04/02/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    /// Convenience wrapper to get layer as its statically known type.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
