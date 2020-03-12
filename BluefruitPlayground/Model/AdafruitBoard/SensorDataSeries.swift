//
//  SensorDataSeries.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

struct SensorDataSeries<T>: Sequence, IteratorProtocol {
    // Config
    let kMaxNumItems = 1000
    
    // Data
    struct Entry {
        var value: T
        var timestamp: CFAbsoluteTime
    }

    private var insertIndex = -1
    private var values = [Entry]()
    private var valuesLock = NSLock()
    
    init() {
        values.reserveCapacity(kMaxNumItems)
    }
    
    // Acccesors
    mutating func addValue(_ value: Entry) {
        valuesLock.lock(); defer { valuesLock.unlock() }
        insertIndex = (insertIndex + 1) % kMaxNumItems
        if insertIndex == values.count {
            values.insert(value, at: insertIndex)
        }
        else {
            values[insertIndex] = value
        }
    }
    
    subscript(index: Int) -> Entry {
        return values[internalIndex(index)]
    }

    var first: Entry? {
        valuesLock.lock(); defer { valuesLock.unlock() }
        guard values.count > 0 else { return nil }
        return self[0]
    }
    
    var last: Entry? {
        valuesLock.lock(); defer { valuesLock.unlock() }
        guard values.count > 0 else { return nil }
        return self[values.count-1]
    }

    // MARK: - Utils
    private func internalIndex(_ index: Int) -> Int {
        let startIndex = insertIndex - (values.count - 1)
        return mod((startIndex + index), kMaxNumItems)      // Use mod instead of %, because numerator could be negative
    }
    
    private func mod(_ a: Int, _ n: Int) -> Int {
        // From: https://stackoverflow.com/questions/41180292/negative-number-modulo-in-swift
        precondition(n > 0, "modulus must be positive")
        let r = a % n
        return r >= 0 ? r : r + n
    }

    // MARK: - IteratorProtocol
    private var iteratorPosition = 0
    mutating func makeIterator() -> SensorDataSeries<T> {
        iteratorPosition = 0
        return self
    }
    
    mutating func next() -> Entry? {
        guard iteratorPosition < values.count else { return nil }
        defer { iteratorPosition = iteratorPosition + 1 }
        return self[internalIndex(iteratorPosition)]
    }
}
