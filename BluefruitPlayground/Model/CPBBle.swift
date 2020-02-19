//
//  CPBBle.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 26/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import FlexColorPicker

protocol CPBBleTemperatureDelegate: class {
    func cpbleTemperatureReceived(_ temperature: Float)
}

protocol CPBBleLightDelegate: class {
    func cpbleLightReceived(_ light: Float)
}

protocol CPBBleButtonsDelegate: class {
    func cpbleButtonsReceived(_ buttonsState: BlePeripheral.ButtonsState)
}

protocol CPBBleAccelerometerDelegate: class {
    func cpbleAccelerationReceived(_ acceleration: BlePeripheral.AccelerometerValue)
}

class CPBBle {
    // Constants
    private static let kLightSequenceFramesPerSecond = 10
    private static let kLightSequenceDefaultBrightness: CGFloat = 0.25
    public static let kLightSequenceDefaultSpeed: Double = 0.3
    // Singleton
    static let shared = CPBBle()

    // Data structs
    enum CPBError: Error {
        case errorDiscoveringServices
    }

    // Notifications
    enum NotificationUserInfoKey: String {
        case uuid = "uuid"
        case value = "value"
    }

    // Params
    weak var temperatureDelegate: CPBBleTemperatureDelegate?
    weak var lightDelegate: CPBBleLightDelegate?
    weak var buttonsDelegate: CPBBleButtonsDelegate?
    weak var accelerometerDelegate: CPBBleAccelerometerDelegate?

    // Data
    private var temperatureData = CPBDataSeries<Float>()
    private var lightData = CPBDataSeries<Float>()
    private var accelerometerData = CPBDataSeries<BlePeripheral.AccelerometerValue>()
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
    func setupPeripheral(blePeripheral: BlePeripheral, completion: @escaping (Result<Void, Error>) -> Void) {
        DLog("Discovering services")
        let peripheralIdentifier = blePeripheral.identifier
        NotificationCenter.default.post(name: .willDiscoverServices, object: nil, userInfo: [NotificationUserInfoKey.uuid.rawValue: peripheralIdentifier])
        blePeripheral.discover(serviceUuids: nil) { error in
            // Check errors
            guard error == nil else {
                DLog("Error discovering services")
                DispatchQueue.main.async {
                    completion(.failure(CPBError.errorDiscoveringServices))
                }
                return
            }

            // Set current peripheral
            self.blePeripheral  = blePeripheral

            // Pixel Service
            blePeripheral.cpbPixelsEnable { result in
                if case .success = result {
                    DLog("Pixels enabled")
                } else {
                    DLog("Warning: Pixels enable failed")
                }

                // Temperature Service: Enable receiving data
                blePeripheral.cpbTemperatureEnable(responseHandler: self.receiveTemperatureData) { result in

                    if case .success = result {
                        DLog("Temperature reading enabled")
                    } else {
                        DLog("Warning: Temperature reading enable failed")
                    }

                    // Light Service: Enable receiving data
                    blePeripheral.cpbLightEnable(responseHandler: self.receiveLightData) { result in

                        if case .success = result {
                            DLog("Light reading enabled")
                        } else {
                            DLog("Warning: Light reading enable failed")
                        }

                        // Buttons Service: Enable receiving data
                        blePeripheral.cpbButtonsEnable(responseHandler: self.receiveButtonsData) { result in

                            if case .success = result {
                                DLog("Buttons reading enabled")
                            } else {
                                DLog("Warning: Buttons reading enable failed")
                            }

                            // ToneGeneator Service: Enable
                            blePeripheral.cpbToneGeneratorEnable { result in

                                if case .success = result {
                                    DLog("ToneGenerator enabled")
                                } else {
                                    DLog("Warning: ToneGenerator enable failed")
                                }

                                // Accelerometer Service: Enable receiving data
                                blePeripheral.cpbAccelerometerEnable(responseHandler: self.receiveAccelerometerData, completion: { result in

                                    if case .success = result {
                                        DLog("Accelerometer enabled")
                                    } else {
                                        DLog("Warning: Accelerometer enable failed")
                                    }

                                    // Finished enabling services
                                    DispatchQueue.main.async {
                                        completion(.success(()))
                                    }
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Read Data
    func lightLastValue() -> Float? {
        return blePeripheral?.cpbLightLastValue()
    }

    func temperatureLastValue() -> Float? {
        return blePeripheral?.cpbTemperatureLastValue()
    }

    func buttonsReadState(completion: @escaping(Result<(BlePeripheral.ButtonsState, UUID), Error>) -> Void) {
        blePeripheral?.cpbButtonsReadState(completion: { result in
            DispatchQueue.main.async {      // Send response in main thread
                completion(result)
            }
        })
    }

    func buttonsLastValue() -> BlePeripheral.ButtonsState? {
        return blePeripheral?.cpbButtonsLastValue()
    }

    func accelerometerLastValue() -> BlePeripheral.AccelerometerValue? {
        return blePeripheral?.cpbAccelerometerLastValue()
    }

    func lightDataSeries() -> [CPBDataSeries<Float>.Entry] {
        return lightData.values
    }

    func temperatureDataSeries() -> [CPBDataSeries<Float>.Entry] {
        return temperatureData.values
    }

    // MARK: - Receive Data
    private func receiveTemperatureData(response: Result<(Float, UUID), Error>) {
        switch response {
        case let .success(temperature, uuid):
            // Save value
            let entry = CPBDataSeries.Entry(value: temperature, timestamp: CFAbsoluteTimeGetCurrent())
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
            let entry = CPBDataSeries.Entry(value: light, timestamp: CFAbsoluteTimeGetCurrent())
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
               let entry = CPBDataSeries.Entry(value: acceleration, timestamp: CFAbsoluteTimeGetCurrent())
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
        blePeripheral?.cpbToneGeneratorStartPlaying(frequency: frequency)
    }

    func toneGeneratorStopPlaying() {
           blePeripheral?.cpbToneGeneratorStartPlaying(frequency: 0)
       }

    func neopixelSetAllPixelsColor(_ color: UIColor) {
        neopixelStopLightSequence()
        blePeripheral?.cpbPixelSetAllPixelsColor(color)
    }

    func neopixelSetPixelColor(_ color: UIColor, pixelMask: [Bool]) {
        neopixelStopLightSequence()
        blePeripheral?.cpbPixelSetColor(index: 0, color: color, pixelMask: pixelMask)
    }

    func neopixelStartLightSequence(_ lightSequenceGenerator: LightSequenceGenerator,
                                    framesPerSecond: Int = CPBBle.kLightSequenceFramesPerSecond,
                                    speed: Double = CPBBle.kLightSequenceDefaultSpeed,
                                    brightness: CGFloat = CPBBle.kLightSequenceDefaultBrightness,
                                    repeating: Bool = true,
                                    sendLightSequenceNotifications: Bool = true) {
        neopixelStopLightSequence()

        currentLightSequenceAnimation = LightSequenceAnimation(lightSequenceGenerator: lightSequenceGenerator, framesPerSecond: framesPerSecond, repeating: repeating)
        currentLightSequenceAnimation!.speed = speed
        currentLightSequenceAnimation!.start(stopHandler: { [weak self] in
            self?.blePeripheral?.cpbPixelSetAllPixelsColor(.clear)
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
                blePeripheral.cpbPixelsWriteData(offset: 0, pixelData: lightData)

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
