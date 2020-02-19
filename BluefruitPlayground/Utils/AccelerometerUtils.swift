//
//  AccelerometerUtils.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 03/02/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import Foundation
import SceneKit

struct AccelerometerUtils {
    static func eulerAnglesFromAcceleration(_ acceleration: BlePeripheral.AccelerometerValue) -> SCNVector3 {
         // https://robotics.stackexchange.com/questions/6953/how-to-calculate-euler-angles-from-gyroscope-output
         let accelAngleX = atan2(acceleration.y, acceleration.z)
         let accelAngleY = atan2(-acceleration.x, sqrt(acceleration.y*acceleration.y + acceleration.z*acceleration.z))

         return SCNVector3(accelAngleX, accelAngleY, 0)
     }
}
