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
    static func quaternionToEuler(quaternion q: BlePeripheral.QuaternionValue) -> (x: Float, y: Float, z: Float) {
        return quaternionToEuler(x: q.x, y: q.y, z: q.z, w: q.w)
    }
    
    static func quaternionToEuler(x: Float, y: Float, z: Float, w: Float) -> (x: Float, y: Float, z: Float) {
        let pitch = asin(min(1, max(-1, 2 * (w * y - z * x))))
        let yaw =  atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z))
        let roll =  atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y))
        
        return (pitch, yaw, roll)
    }
    
    static func quaternionRotated(quaternion q: BlePeripheral.QuaternionValue, angle: Float, axis: (x: Float, y: Float, z: Float)) -> BlePeripheral.QuaternionValue {
        let quaternion = simd_quatf(ix: q.x, iy: q.y, iz: q.z, r: q.w)
        let rotationYQuaternion = simd_quatf(angle: angle, axis: simd_float3(axis.x, axis.y, axis.z))
        let result =  quaternion * rotationYQuaternion
        
        let vector = result.vector
        return BlePeripheral.QuaternionValue(x: vector.x, y: vector.y, z: vector.z, w: vector.w)
    }
}
