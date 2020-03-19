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
        let yaw = atan2(2 * (w * z + x * y), 1 - 2 * (y * y + z * z))
        let roll = atan2(2 * (w * x + y * z), 1 - 2 * (x * x + y * y))
        
        return (pitch, yaw, roll)
    }
    
    static func quaternionRotated(quaternion q: BlePeripheral.QuaternionValue, angle: Float, axis: (x: Float, y: Float, z: Float)) -> BlePeripheral.QuaternionValue {
        let quaternion = simd_quatf(ix: q.x, iy: q.y, iz: q.z, r: q.w)
        let rotationYQuaternion = simd_quatf(angle: angle, axis: simd_float3(axis.x, axis.y, axis.z))
        let result =  quaternion * rotationYQuaternion
        
        let vector = result.vector
        return BlePeripheral.QuaternionValue(x: vector.x, y: vector.y, z: vector.z, w: vector.w)
    }
    
    
    /**
     Decompose the rotation on to 2 parts.
     1. Twist - rotation around the "direction" vector
     2. Swing - rotation around axis that is perpendicular to "direction" vector
     The rotation can be composed back by
     rotation = swing * twist
     
     has singularity in case of swing_rotation close to 180 degrees rotation.
     if the input quaternion is of non-unit length, the outputs are non-unit as well
     otherwise, outputs are both unit
     
     Singularity appears if rotation close to 180 deg, and rotation axis is orthogonal to "direction" vector. There is a infinity decompositions in this case. It can be checked if magnitude of unnormalized twist close to zero. Than you can select one of possible , valid twist
     */
    static func swing_twist_decomposition( rotation: simd_quatf, direction: simd_float3) -> (twist: simd_quatf, swing: simd_quatf) {
        // Based on: https://stackoverflow.com/questions/3684269/component-of-a-quaternion-rotation-around-an-axis/22401169#22401169
        
        let ra = simd_float3(rotation.axis.x, rotation.axis.y, rotation.axis.z)     // rotation axis
        let p = simd_project(ra, direction)  // return projection v1 on to v2  (parallel component)
        
        let twist = simd_quatf(angle: rotation.angle, axis: p)
        
        let twistNormalized = twist.normalized
        let swing = rotation * twistNormalized.conjugate
        
        return (twist, swing)
    }
    
    static func twist_decomposition( rotation: simd_quatf, direction: simd_float3) -> simd_quatf {
        // Based on: https://stackoverflow.com/questions/3684269/component-of-a-quaternion-rotation-around-an-axis/22401169#22401169
        
        let ra = simd_float3(rotation.axis.x, rotation.axis.y, rotation.axis.z)     // rotation axis
        let p = simd_project(ra, direction)  // return projection v1 on to v2  (parallel component)
        
        let twist = simd_quatf(angle: rotation.angle, axis: p)
        let twistNormalized = twist.normalized
        return twistNormalized
    }

    
    static func isQuaternionValid(_ quaternion: simd_quatf) -> Bool {
        let vector = quaternion.vector
        return vector.x.isFinite && vector.y.isFinite && vector.z.isFinite && vector.w.isFinite
    }
}
