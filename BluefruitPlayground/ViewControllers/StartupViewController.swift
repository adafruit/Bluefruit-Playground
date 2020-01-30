//
//  StartupViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 10/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

class StartupViewController: UIViewController {
    // Config
    private static let kMininumSplashDuration: TimeInterval = 0.5
    private static let kForcedNavigationControllerIdentifier: String? = nil//"NetworkTestViewController"
    private static let kMaxTimeToWaitForBleSupport: TimeInterval = 1.0
    
    private static let kServicesToReconnect = [BlePeripheral.kUartServiceUUID]
    private static let kReconnectTimeout = 2.0

    // UI
    @IBOutlet weak var restoreConnectionLabel: UILabel!
    
    
    // Data
    private let bleSupportSemaphore = DispatchSemaphore(value: 0)
    private var startTime: CFAbsoluteTime!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UI
        restoreConnectionLabel.alpha = 0
        
        // Localization
        restoreConnectionLabel.text = LocalizationManager.shared.localizedString("splash_restoringconnection")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

         startTime = CFAbsoluteTimeGetCurrent()
        
        // Check Ble support
        if Config.isBleUnsupportedWarningEnabled {
            let bleState = BleManager.shared.state
            DLog("Bluetooth support: \(bleState.rawValue)")
            if bleState == .unknown || bleState == .resetting {
                registerBleStateNotifications(enabled: true)
                
                let semaphoreResult = bleSupportSemaphore.wait(timeout: .now() + StartupViewController.kMaxTimeToWaitForBleSupport)
                if semaphoreResult == .timedOut {
                    DLog("Bluetooth support check time-out")
                }
                
                registerBleStateNotifications(enabled: false)
            }
        }

        checkBleSupport()
        
        registerConnectionNotifications(enabled: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        registerConnectionNotifications(enabled: false)
    }

    // MARK: - Notifications
    private var didUpdateBleStateObserver: NSObjectProtocol?
    
    private func registerBleStateNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            didUpdateBleStateObserver = notificationCenter.addObserver(forName: .didUpdateBleState, object: nil, queue: nil) { [weak self] notification in
                // Status received. Continue executing...
                self?.bleSupportSemaphore.signal()
             }
            
        } else {
            if let didUpdateBleStateObserver = didUpdateBleStateObserver {notificationCenter.removeObserver(didUpdateBleStateObserver)}
        }
    }

    private var didConnectToPeripheralObserver: NSObjectProtocol?
    private var didDisconnectFromPeripheralObserver: NSObjectProtocol?

    private func registerConnectionNotifications(enabled: Bool) {
        if enabled {
            didConnectToPeripheralObserver = NotificationCenter.default.addObserver(forName: .didConnectToPeripheral, object: nil, queue: .main, using: { [weak self] notification in self?.didConnectToPeripheral(notification)})
            didDisconnectFromPeripheralObserver = NotificationCenter.default.addObserver(forName: .didDisconnectFromPeripheral, object: nil, queue: .main, using: { [weak self] _ in self?.didDisconnectFromPeripheral()})
        }
        else {
            if let didConnectToPeripheralObserver = didConnectToPeripheralObserver {NotificationCenter.default.removeObserver(didConnectToPeripheralObserver)}
            if let didDisconnectFromPeripheralObserver = didDisconnectFromPeripheralObserver {NotificationCenter.default.removeObserver(didDisconnectFromPeripheralObserver)}
        }
    }
    
    
    // MARK: - Check Ble Support
    private func checkBleSupport() {
        alertIfBleNotSupported() { [weak self] in
            guard let self = self else { return }
            
            if let autoconnectPeripheralIdentifier = Settings.autoconnectPeripheralIdentifier {
                self.reconnecToPeripheral(withIdentifier: autoconnectPeripheralIdentifier)
            }
            else {
                self.gotoInitialScreen()
            }
        }
    }
    
    private func alertIfBleNotSupported(completion: @escaping (() -> Void)) {
        if BleManager.shared.state == .unsupported {
            let localizationManager = LocalizationManager.shared
            let alertController = UIAlertController(title: localizationManager.localizedString("dialog_error"), message: localizationManager.localizedString("startup_bluetooth_unsupported"), preferredStyle: .alert)
            let okAction = UIAlertAction(title: localizationManager.localizedString("dialog_ok"), style: .default) { action in
                completion()
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        else {
            completion()
        }
    }
    
    // MARK: - Reconnect previously connnected Ble Peripheral
    private func reconnecToPeripheral(withIdentifier identifier: UUID) {
        DLog("Reconnecting...")
    
        // Reconnect
        let isTryingToReconnect = BleManager.shared.reconnecToPeripherals(withIdentifiers: [identifier], withServices: StartupViewController.kServicesToReconnect, timeout: StartupViewController.kReconnectTimeout)
        
        if !isTryingToReconnect {
            DLog("isTryingToReconnect false. Go to next")
            connected(peripheral: nil)
        }
    }
    
    private func didConnectToPeripheral(_ notification: Notification) {
        // Setup Uart
        guard let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, let currentPeripheral = BleManager.shared.peripheral(with: identifier) else {
            DLog("Connected to an unknown peripheral")
            connected(peripheral: nil)
            return
        }
        
        connected(peripheral: currentPeripheral)
    }
    
    private func didDisconnectFromPeripheral() {
        // Autoconnect failed
        connected(peripheral: nil)
    }
    
    private func connected(peripheral: BlePeripheral?) {
        if let peripheral = peripheral {
            // Show restoring connection label
            UIView.animate(withDuration: 0.2) {
                self.restoreConnectionLabel.alpha = 1
            }
            
            // Setup peripheral
            CPBBle.shared.setupPeripheral(blePeripheral: peripheral) { [weak self] result in
                switch result {
                case .success():
                    ScreenFlowManager.restoreAndGoToCPBModules()
                    
                case .failure(let error):
                    DLog("Failed setup peripheral: \(error.localizedDescription)")
                    BleManager.shared.disconnect(from: peripheral)
                    
                    Settings.clearAutoconnectPeripheral()
                    self?.gotoInitialScreen()
                }
            }
        }
        else {
            Settings.clearAutoconnectPeripheral()
            gotoInitialScreen()
        }
    }
    
    // MARK: - Screen Flow
    private func gotoInitialScreen() {
        let viewControllerIdentifier = StartupViewController.kForcedNavigationControllerIdentifier ?? (Settings.areTipsEnabled && Config.isTutorialEnabled ? TipsViewController.kIdentifier : AutoConnectViewController.kNavigationControllerIdentifier)
        DLog("Start app with viewController: \(viewControllerIdentifier)")
        
        // Change splash screen to main screen
        if let rootViewController = self.storyboard?.instantiateViewController(withIdentifier: viewControllerIdentifier) {
            ScreenFlowManager.changeRootViewController(rootViewController: rootViewController) {
                // Start scannning
                //Config.bleManager.startScan()
            }
        }
        
    }
}
