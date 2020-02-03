//
//  ScreenFlowManager.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 10/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit

struct ScreenFlowManager {
    
    // Data
    private static var wasManualScanningLastUsed = !Config.isAutomaticConnectionEnabled        // Last scanning method used
    
    // MARK: - Go to app areas
    public static func gotoAutoconnect() {
        let bluetoothErrorDisplayed = updateStatusViewControllerIfBluetoothStateIsNotReady()
        guard !bluetoothErrorDisplayed else { return }
        
        guard let window = UIApplication.shared.keyWindow else { return }
        let isAlreadyInAutoconnect = (window.rootViewController as? UINavigationController)?.topViewController is AutoConnectViewController
        guard !isAlreadyInAutoconnect else { return }
        
        let isInManualScan = (window.rootViewController as? UINavigationController)?.topViewController is ScannerViewController
        let transition: UIView.AnimationOptions = isInManualScan ? .transitionFlipFromLeft : .transitionCrossDissolve
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let rootNavigationViewController = mainStoryboard.instantiateViewController(withIdentifier: AutoConnectViewController.kNavigationControllerIdentifier)
        changeRootViewController(rootViewController: rootNavigationViewController, animationOptions: transition)
    }
    
    public static func goToManualScan() {
        let bluetoothErrorDisplayed = updateStatusViewControllerIfBluetoothStateIsNotReady()
        guard !bluetoothErrorDisplayed else { return }
        
        guard let window = UIApplication.shared.keyWindow else { return }
        let isAlreadyInManualScan = (window.rootViewController as? UINavigationController)?.topViewController is ScannerViewController
        guard !isAlreadyInManualScan else { return }
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let rootNavigationViewController = mainStoryboard.instantiateViewController(withIdentifier: ScannerViewController.kNavigationControllerIdentifier)
        changeRootViewController(rootViewController: rootNavigationViewController, animationOptions: .transitionFlipFromRight)
    }
    
    public static func restoreAndGoToCPBModules() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let rootNavigationViewController = mainStoryboard.instantiateViewController(withIdentifier: HomeViewController.kNavigationControllerIdentifier)
        
        changeRootViewController(rootViewController: rootNavigationViewController)  {
            CPBBle.shared.neopixelStartLightSequence(FlashLightSequence(baseColor: .lightGray), speed: 1, repeating: false, sendLightSequenceNotifications: false)
        }
    }
    
    public static func gotoCPBModules() {
        guard let window = UIApplication.shared.keyWindow else { return }
        ScreenFlowManager.wasManualScanningLastUsed = (window.rootViewController as? UINavigationController)?.topViewController is ScannerViewController
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let rootNavigationViewController = mainStoryboard.instantiateViewController(withIdentifier: HomeViewController.kNavigationControllerIdentifier)
        changeRootViewController(rootViewController: rootNavigationViewController) {
            CPBBle.shared.neopixelStartLightSequence(FlashLightSequence(baseColor: .white), speed: 1, repeating: false, sendLightSequenceNotifications: false)
        }
    }
    
    // MARK: - Change Root View Controller
    public static func changeRootViewController(rootViewController: UIViewController, animationOptions: UIView.AnimationOptions? = [.transitionCrossDissolve], completionHandler: (() -> Void)? = nil ) {
        guard let window = UIApplication.shared.keyWindow else { return }

        if let animationOptions = animationOptions {
            window.rootViewController = rootViewController
//            rootViewController.view.layoutIfNeeded()
            UIView.transition(with: window, duration: 0.3, options: animationOptions, animations: {
            }, completion: { completed in
                completionHandler?()
            })
        }
        else {
            window.rootViewController = rootViewController
            completionHandler?()
        }
    }
    
    // MARK: - Monitor Bluetooth State and automatically change rootViewController
    private static weak var didDisconnectFromPeripheralObserver: NSObjectProtocol?
    private static weak var didUpdateBleStateObserver: NSObjectProtocol?
    
    public static func enableBleStateManagement() {
        let notificationCenter = NotificationCenter.default
        
        if didDisconnectFromPeripheralObserver == nil {
            
            didDisconnectFromPeripheralObserver = notificationCenter.addObserver(forName: .didDisconnectFromPeripheral, object: nil, queue: .main, using: { _ in
                guard let window = UIApplication.shared.keyWindow else { return }
                
                // Don't show on startup
                let topViewController = (window.rootViewController as? UINavigationController)?.topViewController ?? window.rootViewController
                guard !(topViewController is StartupViewController) else { return }
                
                // Show disconnection alert
                let localizationManager = LocalizationManager.shared
                let alertController = UIAlertController(title: nil, message: localizationManager.localizedString("scanner_peripheraldisconnected"), preferredStyle: .alert)
                let okAction = UIAlertAction(title: localizationManager.localizedString("dialog_ok"), style: .default) { _ in
               
                    if ScreenFlowManager.wasManualScanningLastUsed {
                        goToManualScan()
                    }
                    else {
                        gotoAutoconnect()
                    }
                }
                alertController.addAction(okAction)
                window.rootViewController?.present(alertController, animated: true, completion: nil)
            })
        }
        
        if didUpdateBleStateObserver == nil {
            didUpdateBleStateObserver = notificationCenter.addObserver(forName: .didUpdateBleState, object: nil, queue: .main) { _ in
                guard let window = UIApplication.shared.keyWindow else { return  }

                let topViewController = (window.rootViewController as? UINavigationController)?.topViewController ?? window.rootViewController
                let isAllowedToShowBluetoothDialogBasedOnCurrentRootViewController = !(topViewController is TipsViewController)  // Don't show bluetooth errroes while showing tips
                guard isAllowedToShowBluetoothDialogBasedOnCurrentRootViewController else { return  }
                
                let _ = updateStatusViewControllerIfBluetoothStateIsNotReady()
            }
        }
    }
    
    public static func disableBleStateManagement() {
        let notificationCenter = NotificationCenter.default
        if let didDisconnectFromPeripheralObserver = didDisconnectFromPeripheralObserver {notificationCenter.removeObserver(didDisconnectFromPeripheralObserver)
            self.didDisconnectFromPeripheralObserver = nil
        }
         if let didUpdateBleStateObserver = didUpdateBleStateObserver {notificationCenter.removeObserver(didUpdateBleStateObserver)
            self.didUpdateBleStateObserver = nil
        }
    }
    
    private static func updateStatusViewControllerIfBluetoothStateIsNotReady() -> Bool {        // Returns true if the rootViewController was changed to BluetoothStatusViewController
        guard let window = UIApplication.shared.keyWindow else { return false }
        
        let bluetoothState = Config.bleManager.state
        let shouldShowBluetoothDialog = bluetoothState == .poweredOff || bluetoothState == .unauthorized || (bluetoothState == .unsupported && Config.isBleUnsupportedWarningEnabled)
        
        let topViewController = (window.rootViewController as? UINavigationController)?.topViewController ?? window.rootViewController
        let isShowingEnableBluetoothDialog = topViewController is BluetoothStatusViewController
        
        var viewControllerIdentifier: String? = nil
        if shouldShowBluetoothDialog && !isShowingEnableBluetoothDialog {
            viewControllerIdentifier = BluetoothStatusViewController.kIdentifier
        }
        else if !shouldShowBluetoothDialog && isShowingEnableBluetoothDialog {
            let defaultConnectViewControllerIdentifier = Config.isAutomaticConnectionEnabled ?  AutoConnectViewController.kNavigationControllerIdentifier : ScannerViewController.kNavigationControllerIdentifier
                   
            viewControllerIdentifier = defaultConnectViewControllerIdentifier
        }
        
        if let viewControllerIdentifier = viewControllerIdentifier {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let rootNavigationViewController = mainStoryboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
            changeRootViewController(rootViewController: rootNavigationViewController)
            return true
        }
        else {
            return false
        }
    }
}
