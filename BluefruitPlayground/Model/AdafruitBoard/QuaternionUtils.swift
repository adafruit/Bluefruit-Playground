//
//  QuaternionUtils.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 03/02/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import Foundation
import SceneKit

struct QuaternionUtils {
    static func quaternionToEuler(quaternion q: BlePeripheral.QuaternionValue) -> SCNVector3 {        
        let eurlerAngles = quaternionToEuler(x: q.qx, y: q.qy, z: q.qz, w: q.qw)
        return SCNVector3(eurlerAngles.x, eurlerAngles.y, eurlerAngles.z)
    }
    
    static func quaternionToEuler(x: Float, y: Float, z: Float, w: Float) -> (x: Float, y: Float, z: Float) {
        let pitch = asin(min(1, max(-1, 2 * (w * y - z * x))))
        let yaw =  atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z))
        let roll =  atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y))
        
        return (pitch, yaw, roll)
    }
}
