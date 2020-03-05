//
//  SensorDataSeries.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

struct SensorDataSeries<T> {
    struct Entry {
        var value: T
        var timestamp: CFAbsoluteTime
    }

    var values = [Entry]()
}
