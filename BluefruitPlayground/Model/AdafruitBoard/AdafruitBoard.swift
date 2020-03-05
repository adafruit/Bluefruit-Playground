//
//  AdafruitBoard.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 26/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import FlexColorPicker

protocol AdafruitTemperatureDelegate: class {
    func cpbleTemperatureReceived(_ temperature: Float)
}

protocol AdafruitLightDelegate: class {
    func cpbleLightReceived(_ light: Float)
}

protocol AdafruitButtonsDelegate: class {
    func cpbleButtonsReceived(_ buttonsState: BlePeripheral.ButtonsState)
}

protocol AdafruitAccelerometerDelegate: class {
    func cpbleAccelerationReceived(_ acceleration: BlePeripheral.AccelerometerValue)
}

/**
 Manages the sensors for a connected Adafruit Board
 
 Use setupPeripheral to bind it to a connected BlePeripheral
 
 - Supported sensors:
    - neopixels
    - light
    - buttons
    - tone generator
    - accelerometer
    - temperature

 - Note: It only supports a single connected board (cannot be used on multiple connected boards simultaneously)

 */
class AdafruitBoard {
    // Constants
    private static let kLightSequenceFramesPerSecond = 10
    private static let kLightSequenceDefaultBrightness: CGFloat = 0.25
    public static let kLightSequenceDefaultSpeed: Double = 0.3
    
    // Singleton
    static let shared = AdafruitBoard()

    // Data structs
    enum BoardError: Error {
        case errorDiscoveringServices
    }

    enum BoardService: CaseIterable {
        case neopixels
        case light
        case buttons
        case toneGenerator
        case accelerometer
        case temperature
    }
    
    // Notifications
    enum NotificationUserInfoKey: String {
        case uuid = "uuid"
        case value = "value"
    }

    // Params
    weak var temperatureDelegate: AdafruitTemperatureDelegate?
    weak var lightDelegate: AdafruitLightDelegate?
    weak var buttonsDelegate: AdafruitButtonsDelegate?
    weak var accelerometerDelegate: AdafruitAccelerometerDelegate?

    // Data
    private var temperatureData = SensorDataSeries<Float>()
    private var lightData = SensorDataSeries<Float>()
    private var accelerometerData = SensorDataSeries<BlePeripheral.AccelerometerValue>()
    private weak var blePeripheral: BlePeripheral?

    private var currentLightSequenceAnimation: LightSequenceAnimation?
    public var neopixelCurrentLightSequenceAnimationSpeed: Double {
        get {
            return currentLightSequenceAnimation?.speed ?? 0
        }

        set {
            currentLightSequenceAnimation?.speed = newValue
        }
    }

    // MARK: - Lifecycle
    private init() {
        registerNotifications(enabled: true)
    }

    deinit {
        registerNotifications(enabled: false)
    }

    // MARK: - Setup
    
    /**
     Setup the singleton to use a BlePeripheral
     
        - parameters:
            - blePeripheral: a *connected* BlePeripheral
            - services: list of BoardServices that will be started. Use nil to select all the supported services
            - completion: completion handler
    */
    func setupPeripheral(blePeripheral: BlePeripheral, services: [BoardService]? = nil, completion: @escaping (Result<Void, Error>) -> Void) {

        DLog("Discovering services")
        let peripheralIdentifier = blePeripheral.identifier
        NotificationCenter.default.post(name: .willDiscoverServices, object: nil, userInfo: [NotificationUserInfoKey.uuid.rawValue: peripheralIdentifier])
        blePeripheral.discover(serviceUuids: nil) { error in
            // Check errors
            guard error == nil else {
                DLog("Error discovering services")
                DispatchQueue.main.async {
                    completion(.failure(BoardError.errorDiscoveringServices))
                }
                return
            }

            // Setup services
            let selectedServices = services != nil ? services! : BoardService.allCases   // If services is nil, select all services
            self.setupServices(blePeripheral: blePeripheral, services: selectedServices, completion: completion)
        }
    }
    
    private func setupServices(blePeripheral: BlePeripheral, services: [BoardService], completion: @escaping (Result<Void, Error>) -> Void) {
        
        // Set current peripheral
        self.blePeripheral  = blePeripheral
        
        // Setup services
        let servicesGroup = DispatchGroup()
        
        // Pixel Service
        if services.contains(.neopixels) {
            servicesGroup.enter()
            blePeripheral.adafruitNeoPixelsEnable { result in
                if case .success = result {
                    DLog("Pixels enabled")
                } else {
                    DLog("Warning: Pixels enable failed")
                }
                servicesGroup.leave()
            }
        }
        
        // Light Service: Enable receiving data
        if services.contains(.light) {
            servicesGroup.enter()
            blePeripheral.adafruitLightEnable(responseHandler: self.receiveLightData) { result in
                
                if case .success = result {
                    DLog("Light reading enabled")
                } else {
                    DLog("Warning: Light reading enable failed")
                }
                servicesGroup.leave()
            }
        }
        
        // Buttons Service: Enable receiving data
        if services.contains(.buttons) {
            servicesGroup.enter()
            blePeripheral.adafruitButtonsEnable(responseHandler: self.receiveButtonsData) { result in
                
                if case .success = result {
                    DLog("Buttons reading enabled")
                } else {
                    DLog("Warning: Buttons reading enable failed")
                }
                servicesGroup.leave()
            }
        }
        
        // ToneGenerator Service: Enable
        if services.contains(.toneGenerator) {
            servicesGroup.enter()
            blePeripheral.adafruitToneGeneratorEnable { result in
                
                if case .success = result {
                    DLog("ToneGenerator enabled")
                } else {
                    DLog("Warning: ToneGenerator enable failed")
                }
                servicesGroup.leave()
            }
        }
        
        // Accelerometer Service: Enable receiving data
        if services.contains(.accelerometer) {
            servicesGroup.enter()
            blePeripheral.adafruitAccelerometerEnable(responseHandler: self.receiveAccelerometerData, completion: { result in
                
                if case .success = result {
                    DLog("Accelerometer enabled")
                } else {
                    DLog("Warning: Accelerometer enable failed")
                }
                servicesGroup.leave()
            })
        }
        
        // Temperature Service: Enable receiving data
        if services.contains(.temperature) {
            servicesGroup.enter()
            blePeripheral.adafruitTemperatureEnable(responseHandler: self.receiveTemperatureData) { result in
                
                if case .success = result {
                    DLog("Temperature reading enabled")
                } else {
                    DLog("Warning: Temperature reading enable failed")
                }
                servicesGroup.leave()
            }
        }
        
        servicesGroup.notify(queue: DispatchQueue.main) {
            DLog("setupServices finished")
            completion(.success(()))
        }
    }

    // MARK: - Read Data
    func lightLastValue() -> Float? {
        return blePeripheral?.adafruitLightLastValue()
    }

    func temperatureLastValue() -> Float? {
        return blePeripheral?.adafruitTemperatureLastValue()
    }

    func buttonsReadState(completion: @escaping(Result<(BlePeripheral.ButtonsState, UUID), Error>) -> Void) {
        blePeripheral?.adafruitButtonsReadState(completion: { result in
            DispatchQueue.main.async {      // Send response in main thread
                completion(result)
            }
        })
    }

    func buttonsLastValue() -> BlePeripheral.ButtonsState? {
        return blePeripheral?.adafruitButtonsLastValue()
    }

    func accelerometerLastValue() -> BlePeripheral.AccelerometerValue? {
        return blePeripheral?.adafruitAccelerometerLastValue()
    }

    func lightDataSeries() -> [SensorDataSeries<Float>.Entry] {
        return lightData.values
    }

    func temperatureDataSeries() -> [SensorDataSeries<Float>.Entry] {
        return temperatureData.values
    }

    // MARK: - Receive Data
    private func receiveTemperatureData(response: Result<(Float, UUID), Error>) {
        switch response {
        case let .success(temperature, uuid):
            // Save value
            let entry = SensorDataSeries.Entry(value: temperature, timestamp: CFAbsoluteTimeGetCurrent())
            temperatureData.values.append(entry)
            //DLog("Temperature (ºC): \(temperature)")

            // Send to delegate
            if let temperatureDelegate = temperatureDelegate {
                DispatchQueue.main.async {      // Delegates are called in the main thread
                    temperatureDelegate.cpbleTemperatureReceived(temperature)
                }
            }

            // Send notification
            NotificationCenter.default.post(name: .didReceiveTemperatureData, object: nil, userInfo: [
                NotificationUserInfoKey.value.rawValue: temperature,
                NotificationUserInfoKey.uuid.rawValue: uuid
            ])

        case .failure(let error):
            DLog("Error receiving temperature data: \(error)")
        }
    }

    private func receiveLightData(response: Result<(Float, UUID), Error>) {
        switch response {
        case let .success(light, uuid):
            // Save value
            let entry = SensorDataSeries.Entry(value: light, timestamp: CFAbsoluteTimeGetCurrent())
            lightData.values.append(entry)
            //DLog("Light (lux): \(light)")

            // Send to delegate
            if let lightDelegate = lightDelegate {
                DispatchQueue.main.async {      // Delegates are called in the main thread
                    lightDelegate.cpbleLightReceived(light)
                }
            }

            // Send notification
            NotificationCenter.default.post(name: .didReceiveLightData, object: nil, userInfo: [
                NotificationUserInfoKey.value.rawValue: light,
                NotificationUserInfoKey.uuid.rawValue: uuid
            ])

        case .failure(let error):
            DLog("Error receiving light data: \(error)")
        }
    }

    private func receiveButtonsData(response: Result<(BlePeripheral.ButtonsState, UUID), Error>) {
        switch response {
        case let .success(buttonsState, uuid):
            DLog("Buttons: \(buttonsState.slideSwitch == .left ? "⬅️":"➡️") \(buttonsState.buttonA == .pressed ? "🔳":"🔲") \(buttonsState.buttonB == .pressed ? "🔳":"🔲") ")

            // Send to delegate
            if let buttonsDelegate = buttonsDelegate {
                DispatchQueue.main.async {      // Delegates are called in the main thread
                    buttonsDelegate.cpbleButtonsReceived(buttonsState)
                }
            }

            // Send notification
            NotificationCenter.default.post(name: .didReceiveButtonsData, object: nil, userInfo: [
                NotificationUserInfoKey.value.rawValue: buttonsState,
                NotificationUserInfoKey.uuid.rawValue: uuid
            ])

        case .failure(let error):
            DLog("Error receiving light data: \(error)")
        }
    }

    private func receiveAccelerometerData(response: Result<(BlePeripheral.AccelerometerValue, UUID), Error>) {
           switch response {
           case let .success(acceleration, uuid):
               // Save value
               let entry = SensorDataSeries.Entry(value: acceleration, timestamp: CFAbsoluteTimeGetCurrent())
               accelerometerData.values.append(entry)
               //DLog("Accelerometer x: \(acceleration.x), y: \(acceleration.y) z: \(acceleration.z)")

               // Send to delegate
               if let accelerometerDelegate = accelerometerDelegate {
                   DispatchQueue.main.async {      // Delegates are called in the main thread
                       accelerometerDelegate.cpbleAccelerationReceived(acceleration)
                   }
               }

               // Send notification
               NotificationCenter.default.post(name: .didReceiveAccelerometerData, object: nil, userInfo: [
                   NotificationUserInfoKey.value.rawValue: acceleration,
                   NotificationUserInfoKey.uuid.rawValue: uuid
               ])

           case .failure(let error):
               DLog("Error receiving accelerometer data: \(error)")
           }
       }

    // MARK: - Send Commands
    func toneGeneratorStartPlaying(frequency: UInt16) {
        blePeripheral?.adafruitToneGeneratorStartPlaying(frequency: frequency)
    }

    func toneGeneratorStopPlaying() {
           blePeripheral?.adafruitToneGeneratorStartPlaying(frequency: 0)
       }

    func neopixelSetAllPixelsColor(_ color: UIColor) {
        neopixelStopLightSequence()
        blePeripheral?.adafruitNeoPixelSetAllPixelsColor(color)
    }

    func neopixelSetPixelColor(_ color: UIColor, pixelMask: [Bool]) {
        neopixelStopLightSequence()
        blePeripheral?.adafruitNeoPixelSetColor(index: 0, color: color, pixelMask: pixelMask)
    }

    func neopixelStartLightSequence(_ lightSequenceGenerator: LightSequenceGenerator,
                                    framesPerSecond: Int = AdafruitBoard.kLightSequenceFramesPerSecond,
                                    speed: Double = AdafruitBoard.kLightSequenceDefaultSpeed,
                                    brightness: CGFloat = AdafruitBoard.kLightSequenceDefaultBrightness,
                                    repeating: Bool = true,
                                    sendLightSequenceNotifications: Bool = true) {
        neopixelStopLightSequence()

        currentLightSequenceAnimation = LightSequenceAnimation(lightSequenceGenerator: lightSequenceGenerator, framesPerSecond: framesPerSecond, repeating: repeating)
        currentLightSequenceAnimation!.speed = speed
        currentLightSequenceAnimation!.start(stopHandler: { [weak self] in
            self?.blePeripheral?.adafruitNeoPixelSetAllPixelsColor(.clear)
            }, frameHandler: { [weak self] pixelsBytes in
                guard let self = self else { return }
                guard let blePeripheral = self.blePeripheral else { return }

                let pixelBytesAdjustingBrightness = pixelsBytes.map {[
                    UInt8(CGFloat($0[0]) * brightness),
                    UInt8(CGFloat($0[1]) * brightness),
                    UInt8(CGFloat($0[2]) * brightness)
                    ]}

                let lightData = pixelBytesAdjustingBrightness.reduce(Data()) { (data, element) in
                    data + element.data
                }
                blePeripheral.adafruitNeoPixelsWriteData(offset: 0, pixelData: lightData)

                // Send notification
                if sendLightSequenceNotifications {
                    NotificationCenter.default.post(name: .didUpdateNeopixelLightSequence, object: nil, userInfo: [
                        NotificationUserInfoKey.value.rawValue: pixelsBytes,
                        NotificationUserInfoKey.uuid.rawValue: blePeripheral.identifier
                    ])
                }
        })
    }

    func neopixelStopLightSequence() {
        currentLightSequenceAnimation?.stop()
        currentLightSequenceAnimation = nil
    }

    // MARK: - BLE Notifications
    private weak var willdDisconnectFromPeripheralObserver: NSObjectProtocol?

    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            willdDisconnectFromPeripheralObserver = notificationCenter.addObserver(forName: .willDisconnectFromPeripheral, object: nil, queue: .main, using: {[weak self] _ in

                // Force clear neopixels on disconnect
                self?.neopixelSetAllPixelsColor(.clear)
            })

        } else {
            if let willdDisconnectFromPeripheralObserver = willdDisconnectFromPeripheralObserver {notificationCenter.removeObserver(willdDisconnectFromPeripheralObserver)}
        }
    }

}

// MARK: - Custom Notifications
extension Notification.Name {
    private static let kNotificationsPrefix = Bundle.main.bundleIdentifier!
    static let willDiscoverServices = Notification.Name(kNotificationsPrefix+".willDiscoverServices")
    static let didReceiveTemperatureData = Notification.Name(kNotificationsPrefix+".didReceiveTemperatureData")
    static let didReceiveLightData = Notification.Name(kNotificationsPrefix+".didReceiveLightData")
    static let didReceiveButtonsData = Notification.Name(kNotificationsPrefix+".didReceiveButtonsData")
    static let didReceiveAccelerometerData = Notification.Name(kNotificationsPrefix+".didReceiveAccelerometerData")
    static let didUpdateNeopixelLightSequence = Notification.Name(kNotificationsPrefix+".didUpdateNeopixelLightSequence")
}
