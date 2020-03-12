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
    func adafruitTemperatureReceived(_ temperature: Float)
}

protocol AdafruitLightDelegate: class {
    func adafruitLightReceived(_ light: Float)
}

protocol AdafruitButtonsDelegate: class {
    func adafruitButtonsReceived(_ buttonsState: BlePeripheral.ButtonsState)
}

protocol AdafruitAccelerometerDelegate: class {
    func adafruitAccelerationReceived(_ acceleration: BlePeripheral.AccelerometerValue)
}

protocol AdafruitHumidityDelegate: class {
    func adafruitHumidityReceived(_ humidity: Float)
}

protocol AdafruitBarometricPressureDelegate: class {
    func adafruitBarometricPressureReceived(_ pressure: Float)
}

protocol AdafruitSoundDelegate: class {
    func adafruitSoundReceived(_ channelSamples: [Double])
}

protocol AdafruitGyroscopeDelegate: class {
    func adafruitGyroscopeReceived(_ gyroscope: BlePeripheral.GyroscopeValue)
}

protocol AdafruitQuaternionDelegate: class {
    func adafruitQuaternionReceived(_ quaternion: BlePeripheral.QuaternionValue)
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
 - humidity
 - barometric pressure
 - sound
 
 */
class AdafruitBoard {
    // Constants
    private static let kLightSequenceFramesPerSecond = 10
    private static let kLightSequenceDefaultBrightness: CGFloat = 0.25
    public static let kLightSequenceDefaultSpeed: Double = 0.3
    
    // Data structs
    enum BoardError: Error {
        case errorBoardNotConnected
        case errorDiscoveringServices
    }
    
    enum BoardService: CaseIterable {
        case neopixels
        case light
        case buttons
        case toneGenerator
        case accelerometer
        case temperature
        case humidity
        case barometricPressure
        case sound
        case gyroscope
        case quaternion
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
    weak var humidityDelegate: AdafruitHumidityDelegate?
    weak var barometricPressureDelegate: AdafruitBarometricPressureDelegate?
    weak var soundDelegate: AdafruitSoundDelegate?
    weak var gyroscopeDelegate: AdafruitGyroscopeDelegate?
    weak var quaternionDelegate: AdafruitQuaternionDelegate?

    // Data
    private(set) weak var blePeripheral: BlePeripheral?
    var model: BlePeripheral.AdafruitManufacturerData.BoardModel? {
        return blePeripheral?.adafruitManufacturerData()?.boardModel
    }
    
    private(set) var lightDataSeries = SensorDataSeries<Float>()
    private(set) var accelerometerDataSeries = SensorDataSeries<BlePeripheral.AccelerometerValue>()
    private(set) var temperatureDataSeries = SensorDataSeries<Float>()
    private(set) var humidityDataSeries = SensorDataSeries<Float>()
    private(set) var barometricPressureDataSeries = SensorDataSeries<Float>()
    private(set) var soundAmplitudeDataSeries = SensorDataSeries<Float>()
    private(set) var gyroscopeDataSeries = SensorDataSeries<BlePeripheral.GyroscopeValue>()
    private(set) var quaternionDataSeries = SensorDataSeries<BlePeripheral.QuaternionValue>()

    private var currentLightSequenceAnimation: LightSequenceAnimation?
    public var neopixelCurrentLightSequenceAnimationSpeed: Double {
        get {
            return currentLightSequenceAnimation?.speed ?? 0
        }
        
        set {
            currentLightSequenceAnimation?.speed = newValue
        }
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
        self.blePeripheral = blePeripheral
        
        // Setup services
        let servicesGroup = DispatchGroup()
        
        // Pixel Service
        if services.contains(.neopixels), let numPixels = blePeripheral.adafruitManufacturerData()?.boardModel?.neoPixelsNumPixels, numPixels > 0 {
            
            servicesGroup.enter()
            blePeripheral.adafruitNeoPixelsEnable(numPixels: numPixels) { result in
                if case .success = result {
                    DLog("NeoPixels enabled")
                } else {
                    DLog("Warning: NeoPixels enable failed")
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
        
        // Humidity Service: Enable receiving data
        if services.contains(.humidity) {
            servicesGroup.enter()
            blePeripheral.adafruitHumidityEnable(responseHandler: self.receiveHumidityData) { result in
                
                if case .success = result {
                    DLog("Humidity reading enabled")
                } else {
                    DLog("Warning: Humidity reading enable failed")
                }
                servicesGroup.leave()
            }
        }
        
        // Barometric Pressure Service: Enable receiving data
        if services.contains(.barometricPressure) {
            servicesGroup.enter()
            blePeripheral.adafruitBarometricPressureEnable(responseHandler: self.receiveBarometricPressureData) { result in
                
                if case .success = result {
                    DLog("Barometric Pressure reading enabled")
                } else {
                    DLog("Warning: Barometric Pressure reading enable failed")
                }
                servicesGroup.leave()
            }
        }
        
        // Sound Service: Enable receiving data
        if services.contains(.sound) {
            servicesGroup.enter()
            blePeripheral.adafruitSoundEnable(responseHandler: self.receiveSoundData) { result in
                
                if case .success = result {
                    DLog("Sound reading enabled")
                } else {
                    DLog("Warning: Sound reading enable failed")
                }
                servicesGroup.leave()
            }
        }
        
        
        
        // Gyroscope Service: Enable receiving data
        if services.contains(.gyroscope) {
            servicesGroup.enter()
            blePeripheral.adafruitGyroscopeEnable(responseHandler: self.receiveGyroscopeData) { result in
                
                if case .success = result {
                    DLog("Gyroscope reading enabled")
                } else {
                    DLog("Warning: Gyroscope reading enable failed")
                }
                servicesGroup.leave()
            }
        }
        
        // Quaternion Service: Enable receiving data
        if services.contains(.quaternion) {
            servicesGroup.enter()
            blePeripheral.adafruitQuaternionEnable(responseHandler: self.receiveQuaternionData) { result in
                
                if case .success = result {
                    DLog("Quaternion reading enabled")
                } else {
                    DLog("Warning: Quaternion reading enable failed")
                }
                servicesGroup.leave()
            }
        }
        
        // Wait for all finished
        servicesGroup.notify(queue: DispatchQueue.main) {
            DLog("setupServices finished")
            completion(.success(()))
        }
    }
    
    // MARK: - Sensor availability
    var isNeopixelsAvailable: Bool {
        return blePeripheral?.adafruitNeoPixelsIsEnabled() ?? false
    }
    
    var isLightAvailable: Bool {
        return blePeripheral?.adafruitLightIsEnabled() ?? false
    }
    
    var isButtonsAvailable: Bool {
        return blePeripheral?.adafruitButtonsIsEnabled() ?? false
    }
    
    var isToneGeneratorAvailable: Bool {
        return blePeripheral?.adafruitToneGeneratorIsEnabled() ?? false
    }
    
    var isAccelerometerAvailable: Bool {
        return blePeripheral?.adafruitAccelerometerIsEnabled() ?? false
    }
    
    var isTemperatureAvailable: Bool {
        return blePeripheral?.adafruitTemperatureIsEnabled() ?? false
    }
    
    var isHumidityAvailable: Bool {
        return blePeripheral?.adafruitHumidityIsEnabled() ?? false
    }
    
    var isBarometricPressureAvailable: Bool {
        return blePeripheral?.adafruitBarometricPressureIsEnabled() ?? false
    }
    
    var isSoundAvailable: Bool {
        return blePeripheral?.adafruitSoundIsEnabled() ?? false
    }

    var isGyroscopeAvailable: Bool {
        return blePeripheral?.adafruitGyroscopeIsEnabled() ?? false
    }

    var isQuaternionAvailable: Bool {
        return blePeripheral?.adafruitQuaternionIsEnabled() ?? false
    }

    // MARK: - Read Data
    func lightLastValue() -> Float? {
        return blePeripheral?.adafruitLightLastValue()
    }
    
    func buttonsReadState(completion: @escaping(Result<(BlePeripheral.ButtonsState, UUID), Error>) -> Void) {
        blePeripheral?.adafruitButtonsReadState() { result in
            DispatchQueue.main.async {      // Send response in main thread
                completion(result)
            }
        }
    }
    
    func buttonsLastValue() -> BlePeripheral.ButtonsState? {
        return blePeripheral?.adafruitButtonsLastValue()
    }
    
    func accelerometerLastValue() -> BlePeripheral.AccelerometerValue? {
        return blePeripheral?.adafruitAccelerometerLastValue()
    }
    
    func temperatureLastValue() -> Float? {
        return blePeripheral?.adafruitTemperatureLastValue()
    }
    
    func humidityLastValue() -> Float? {
        return blePeripheral?.adafruitHumidityLastValue()
    }
    
    func barometricPressureLastValue() -> Float? {
        return blePeripheral?.adafruitBarometricPressureLastValue()
    }
    
    func soundLastAmplitudesPerChannel() -> [Double]? {
        return blePeripheral?.adafruitSoundLastAmplitudePerChannel()
    }
    
    func soundLastAmplitude() -> Double? {
        return soundLastAmplitudesPerChannel()?.first
    }
    
    func gyroscopeLastValue() -> BlePeripheral.GyroscopeValue? {
        return blePeripheral?.adafruitGyroscopeLastValue()
    }

    func quaternionLastValue() -> BlePeripheral.QuaternionValue? {
        return blePeripheral?.adafruitQuaternionLastValue()
    }
    
    
    // MARK: - Receive Data
    private func receiveLightData(response: Result<(Float, UUID), Error>) {
        switch response {
        case let .success(light, uuid):
            // Save value
            let entry = SensorDataSeries.Entry(value: light, timestamp: CFAbsoluteTimeGetCurrent())
            lightDataSeries.addValue(entry)
            //DLog("Light (lux): \(light)")
            
            // Send to delegate
            if let lightDelegate = lightDelegate {
                DispatchQueue.main.async {      // Delegates are called in the main thread
                    lightDelegate.adafruitLightReceived(light)
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
            //DLog("Buttons: \(buttonsState.slideSwitch == .left ? "⬅️":"➡️") \(buttonsState.buttonA == .pressed ? "🔳":"🔲") \(buttonsState.buttonB == .pressed ? "🔳":"🔲") ")
            
            // Send to delegate
            if let buttonsDelegate = buttonsDelegate {
                DispatchQueue.main.async {      // Delegates are called in the main thread
                    buttonsDelegate.adafruitButtonsReceived(buttonsState)
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
        case let .success(value, uuid):
            // Save value
            let entry = SensorDataSeries.Entry(value: value, timestamp: CFAbsoluteTimeGetCurrent())
            accelerometerDataSeries.addValue(entry)
            //DLog("Accelerometer x: \(value.x), y: \(value.y) z: \(value.z)")
            
            // Send to delegate
            if let accelerometerDelegate = accelerometerDelegate {
                DispatchQueue.main.async {      // Delegates are called in the main thread
                    accelerometerDelegate.adafruitAccelerationReceived(value)
                }
            }
            
            // Send notification
            NotificationCenter.default.post(name: .didReceiveAccelerometerData, object: nil, userInfo: [
                NotificationUserInfoKey.value.rawValue: value,
                NotificationUserInfoKey.uuid.rawValue: uuid
            ])
            
        case .failure(let error):
            DLog("Error receiving accelerometer data: \(error)")
        }
    }
    
    private func receiveTemperatureData(response: Result<(Float, UUID), Error>) {
        switch response {
        case let .success(value, uuid):
            // Save value
            let entry = SensorDataSeries.Entry(value: value, timestamp: CFAbsoluteTimeGetCurrent())
            temperatureDataSeries.addValue(entry)
            //DLog("Temperature (ºC): \(temperature)")
            
            // Send to delegate
            if let temperatureDelegate = temperatureDelegate {
                DispatchQueue.main.async {      // Delegates are called in the main thread
                    temperatureDelegate.adafruitTemperatureReceived(value)
                }
            }
            
            // Send notification
            NotificationCenter.default.post(name: .didReceiveTemperatureData, object: nil, userInfo: [
                NotificationUserInfoKey.value.rawValue: value,
                NotificationUserInfoKey.uuid.rawValue: uuid
            ])
            
        case .failure(let error):
            DLog("Error receiving temperature data: \(error)")
        }
    }
    
    private func receiveHumidityData(response: Result<(Float, UUID), Error>) {
        switch response {
        case let .success(value, uuid):
            // Save value
            let entry = SensorDataSeries.Entry(value: value, timestamp: CFAbsoluteTimeGetCurrent())
            humidityDataSeries.addValue(entry)
            //DLog("Humidity: \(humidity)%")
            
            // Send to delegate
            if let humidityDelegate = humidityDelegate {
                DispatchQueue.main.async {      // Delegates are called in the main thread
                    humidityDelegate.adafruitHumidityReceived(value)
                }
            }
            
            // Send notification
            NotificationCenter.default.post(name: .didReceiveHumidityData, object: nil, userInfo: [
                NotificationUserInfoKey.value.rawValue: value,
                NotificationUserInfoKey.uuid.rawValue: uuid
            ])
            
        case .failure(let error):
            DLog("Error receiving humidity data: \(error)")
        }
    }
    
    private func receiveBarometricPressureData(response: Result<(Float, UUID), Error>) {
        switch response {
        case let .success(value, uuid):
            // Save value
            let entry = SensorDataSeries.Entry(value: value, timestamp: CFAbsoluteTimeGetCurrent())
            barometricPressureDataSeries.addValue(entry)
            //DLog("Pressure: \(pressure)hPa")
            
            // Send to delegate
            if let barometricPressureDelegate = barometricPressureDelegate {
                DispatchQueue.main.async {      // Delegates are called in the main thread
                    barometricPressureDelegate.adafruitBarometricPressureReceived(value)
                }
            }
            
            // Send notification
            NotificationCenter.default.post(name: .didReceiveBarometricPressureData, object: nil, userInfo: [
                NotificationUserInfoKey.value.rawValue: value,
                NotificationUserInfoKey.uuid.rawValue: uuid
            ])
            
        case .failure(let error):
            DLog("Error receiving pressure data: \(error)")
        }
    }
    
    private func receiveSoundData(response: Result<([Double], UUID), Error>) {
        switch response {
        case let .success(amplitudesPerChannel, uuid):
            // Save value
            if let amplitude = amplitudesPerChannel.first, !amplitude.isNaN {
                let entry = SensorDataSeries.Entry(value: Float(amplitude), timestamp: CFAbsoluteTimeGetCurrent())
                soundAmplitudeDataSeries.addValue(entry)
                //DLog("Amplitude: \(amplitude)dBFS")
            }
            
            // Send to delegate
            if let soundDelegate = soundDelegate {
                DispatchQueue.main.async {      // Delegates are called in the main thread
                    soundDelegate.adafruitSoundReceived(amplitudesPerChannel)
                }
            }
            
            // Send notification
            NotificationCenter.default.post(name: .didReceiveSoundData, object: nil, userInfo: [
                NotificationUserInfoKey.value.rawValue: amplitudesPerChannel,
                NotificationUserInfoKey.uuid.rawValue: uuid
            ])
            
        case .failure(let error):
            DLog("Error receiving sound data: \(error)")
        }
    }
    
    private func receiveGyroscopeData(response: Result<(BlePeripheral.GyroscopeValue, UUID), Error>) {
        switch response {
        case let .success(value, uuid):
            // Save value
            let entry = SensorDataSeries.Entry(value: value, timestamp: CFAbsoluteTimeGetCurrent())
            gyroscopeDataSeries.addValue(entry)
            DLog("Gyroscope x: \(value.x), y: \(value.y) z: \(value.z)")
                
            // Send to delegate
            if let gyroscopeDelegate = gyroscopeDelegate {
                DispatchQueue.main.async {      // Delegates are called in the main thread
                    gyroscopeDelegate.adafruitGyroscopeReceived(value)
                }
            }
            
            // Send notification
            NotificationCenter.default.post(name: .didReceiveGyroscopeData, object: nil, userInfo: [
                NotificationUserInfoKey.value.rawValue: value,
                NotificationUserInfoKey.uuid.rawValue: uuid
            ])
            
        case .failure(let error):
            DLog("Error receiving gyroscope data: \(error)")
        }
    }
    
    private func receiveQuaternionData(response: Result<(BlePeripheral.QuaternionValue, UUID), Error>) {
        switch response {
        case let .success(value, uuid):
            // Save value
            let entry = SensorDataSeries.Entry(value: value, timestamp: CFAbsoluteTimeGetCurrent())
            quaternionDataSeries.addValue(entry)
            //DLog("Quaternion qx: \(value.qx), qy: \(value.qy) qz: \(value.qz) qw: \(value.qw)")
            
            // Send to delegate
            if let quaternionDelegate = quaternionDelegate {
                DispatchQueue.main.async {      // Delegates are called in the main thread
                    quaternionDelegate.adafruitQuaternionReceived(value)
                }
            }
            
            // Send notification
            NotificationCenter.default.post(name: .didReceiveQuaternionData, object: nil, userInfo: [
                NotificationUserInfoKey.value.rawValue: value,
                NotificationUserInfoKey.uuid.rawValue: uuid
            ])
            
        case .failure(let error):
            DLog("Error receiving quaternion data: \(error)")
        }
    }
    
    // MARK: - Send Commands
    // MARK: Send Neopixel
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
    
    // MARK: Send ToneGenerator
    func toneGeneratorStartPlaying(frequency: UInt16) {
        blePeripheral?.adafruitToneGeneratorStartPlaying(frequency: frequency)
    }
    
    func toneGeneratorStopPlaying() {
        blePeripheral?.adafruitToneGeneratorStartPlaying(frequency: 0)
    }
}

// MARK: - Custom Notifications
extension Notification.Name {
    private static let kNotificationsPrefix = Bundle.main.bundleIdentifier!
    static let willDiscoverServices = Notification.Name(kNotificationsPrefix+".willDiscoverServices")
    
    static let didUpdateNeopixelLightSequence = Notification.Name(kNotificationsPrefix+".didUpdateNeopixelLightSequence")
    static let didReceiveLightData = Notification.Name(kNotificationsPrefix+".didReceiveLightData")
    static let didReceiveButtonsData = Notification.Name(kNotificationsPrefix+".didReceiveButtonsData")
    static let didReceiveAccelerometerData = Notification.Name(kNotificationsPrefix+".didReceiveAccelerometerData")
    static let didReceiveHumidityData = Notification.Name(kNotificationsPrefix+".didReceiveHumidityData")
    static let didReceiveTemperatureData = Notification.Name(kNotificationsPrefix+".didReceiveTemperatureData")
    static let didReceiveBarometricPressureData = Notification.Name(kNotificationsPrefix+".didReceiveBarometricPressureData")
    static let didReceiveSoundData = Notification.Name(kNotificationsPrefix+".didReceiveSoundData")
    static let didReceiveGyroscopeData = Notification.Name(kNotificationsPrefix+".didReceiveGyroscopeData")
    static let didReceiveQuaternionData = Notification.Name(kNotificationsPrefix+".didReceiveQuaternionData")
}
