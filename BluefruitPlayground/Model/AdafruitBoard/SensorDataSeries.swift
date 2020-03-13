//
//  SensorDataSeries.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 13/11/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import Foundation

class SensorDataSeries<T>: Sequence {
    // Config
    let kMaxNumItems = 1000
    
    // Data
    struct Entry {
        var value: T
        var timestamp: CFAbsoluteTime
    }

    private var lastInsertIndex = -1        // Last index where a value was inserted
    private var values = [Entry]()
    private let queue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).SensorDataSeries", attributes: .concurrent)
    
    init() {
        values.reserveCapacity(kMaxNumItems)
    }
    
    // Acccesors
    func addValue(_ value: Entry) {
        queue.async(flags: .barrier) {
            let insertIndex = (self.lastInsertIndex + 1) % self.kMaxNumItems
            if insertIndex == self.values.count {        // Array not full. Add value
                self.values.insert(value, at: insertIndex)
            }
            else {      // Array full, replace value
                self.values[insertIndex] = value
            }
            self.lastInsertIndex = insertIndex
        }
    }
    
    subscript(index: Int) -> Entry? {
        var result: Entry?
        queue.sync {
            guard self.values.startIndex..<self.values.endIndex ~= index else { return }
            result = values[internalIndex(index)]
        }
        return result
    }

    var first: Entry? {
        var result: Entry?
        queue.sync {
            let index = internalIndex(0)
            result = values.count > index ? values[index] : nil
        }
        return result
    }

    var last: Entry? {
        var result: Entry?
        queue.sync {
            let index = internalIndex(values.count-1)
            result = values.count > index ? values[index] : nil
        }
        return result
    }
    
    var count: Int {
        var result = 0
        queue.sync { result = self.values.count }
        return result
    }

    // MARK: - Utils
    private func internalIndex(_ index: Int) -> Int {
        let startIndex = lastInsertIndex - (values.count - 1)
        return mod((startIndex + index), kMaxNumItems)      // Use mod instead of %, because numerator could be negative
    }

    private func mod(_ a: Int, _ n: Int) -> Int {
        // From: https://stackoverflow.com/questions/41180292/negative-number-modulo-in-swift
        precondition(n > 0, "modulus must be positive")
        let r = a % n
        return r >= 0 ? r : r + n
    }

    // MARK: - IteratorProtocol
    func makeIterator() -> Iterator {
        return Iterator(self, queue: queue)
    }
  
    
    // MARK: -
    struct Iterator: IteratorProtocol {
        private let dataSeries: SensorDataSeries
        private var iteratorPosition = 0
        private var queue: DispatchQueue

        init(_ dataSeries: SensorDataSeries, queue: DispatchQueue) {
            self.dataSeries = dataSeries
            self.queue = queue
        }
        
        mutating func next() -> Entry? {
            var result: Entry?
            queue.sync {
                guard iteratorPosition < dataSeries.values.count else { return }
                defer { iteratorPosition = iteratorPosition + 1 }
                result = dataSeries.values[dataSeries.internalIndex(iteratorPosition)]
            }
            
            return result
        }
    }
}
