//
//  AutoConnectViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 28/01/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit

class AutoConnectViewController: UIViewController {
    // Constants
    static let kNavigationControllerIdentifier = "AutoConnectNavigationController"

    // Config
    private static let kRssiRunningAverageFactor = 0.2

    // UI
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var scanManuallyButton: UIButton!
    @IBOutlet weak var problemButton: CornerShadowButton!
    @IBOutlet weak var wave0ImageView: UIImageView!
    @IBOutlet weak var wave1ImageView: UIImageView!
    @IBOutlet weak var wave2ImageView: UIImageView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var cpbContainerView: UIView!
    @IBOutlet weak var cpbImageView: UIImageView!
    @IBOutlet weak var actionsContainerView: UIStackView!

    // Data
    private let bleManager = Config.bleManager
    private var peripheralList = PeripheralList(bleManager: Config.bleManager)
    private var peripheralAutoConnect = PeripheralAutoConnect()
    private var selectedPeripheral: BlePeripheral? {
        didSet {
            if isViewLoaded {
                UIView.animate(withDuration: 0.3) {
                    self.actionsContainerView.alpha = self.selectedPeripheral == nil ? 1:0
                }
            }
        }
    }

    private let navigationButton = UIButton(type: .custom)
    private var isAnimating = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("autoconnect_title")

        scanManuallyButton.setTitle(localizationManager.localizedString("autoconnect_manual_action").uppercased(), for: .normal)
        problemButton.setTitle(localizationManager.localizedString("scanner_problems_action").uppercased(), for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.backBarButtonItem = nil     // Clear any custom back button

        if let customNavigationBar = navigationController?.navigationBar as? NavigationBarWithScrollAwareRightButton {
            customNavigationBar.setRightButton(topViewController: self, image: UIImage(named: "info"), target: self, action: #selector(troubleshooting(_:)))
        }

        // Disconnect if needed
        let connectedPeripherals = bleManager.connectedPeripherals()
        if connectedPeripherals.count == 1, let peripheral = connectedPeripherals.first {
            DLog("Disconnect from previously connected peripheral")
            // Disconnect from peripheral
            disconnect(peripheral: peripheral)
        }

        // UI
        updateStatusLabel()

        // Animations
        if !isAnimating {
            startAnimating()
        }

        // Ble Notifications
        registerNotifications(enabled: true)

        // Autoconnect
        peripheralAutoConnect.reset()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Update UI
        updateScannedPeripherals()

        // Start scannning
        BlePeripheral.rssiRunningAverageFactor = AutoConnectViewController.kRssiRunningAverageFactor     // Use running average for rssi
        if !bleManager.isScanning {
            bleManager.startScan()
        }

        // Remove saved peripheral for autoconnect
        Settings.autoconnectPeripheralIdentifier = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Stop scanning
        bleManager.stopScan()
        BlePeripheral.rssiRunningAverageFactor = 1       // Disable using running average for rssi

        // Clear peripherals
        peripheralList.clear()

        // Animations
        stopAnimating()

        // Ble Notifications
        registerNotifications(enabled: false)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ScannerViewController {
            // Go to scanner screen
            let backItem = UIBarButtonItem()
            backItem.title = LocalizationManager.shared.localizedString("autoconnect_backbutton")
            self.navigationItem.backBarButtonItem = backItem
        }
    }

    // MARK: - BLE Notifications
    private weak var didDiscoverPeripheralObserver: NSObjectProtocol?
    private weak var didUnDiscoverPeripheralObserver: NSObjectProtocol?
    private weak var willConnectToPeripheralObserver: NSObjectProtocol?
    private weak var didConnectToPeripheralObserver: NSObjectProtocol?
    private weak var didDisconnectFromPeripheralObserver: NSObjectProtocol?
    private weak var peripheralDidUpdateNameObserver: NSObjectProtocol?
    private weak var willDiscoverServicesObserver: NSObjectProtocol?

    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            didDiscoverPeripheralObserver = notificationCenter.addObserver(forName: .didDiscoverPeripheral, object: nil, queue: .main, using: {[weak self] _ in self?.updateScannedPeripherals()})
               didUnDiscoverPeripheralObserver = notificationCenter.addObserver(forName: .didUnDiscoverPeripheral, object: nil, queue: .main, using: {[weak self] _ in self?.updateScannedPeripherals()})
            willConnectToPeripheralObserver = notificationCenter.addObserver(forName: .willConnectToPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.willConnectToPeripheral(notification: notification)})
            didConnectToPeripheralObserver = notificationCenter.addObserver(forName: .didConnectToPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.didConnectToPeripheral(notification: notification)})
            didDisconnectFromPeripheralObserver = notificationCenter.addObserver(forName: .didDisconnectFromPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.didDisconnectFromPeripheral(notification: notification)})
            peripheralDidUpdateNameObserver = notificationCenter.addObserver(forName: .peripheralDidUpdateName, object: nil, queue: .main, using: {[weak self] notification in self?.peripheralDidUpdateName(notification: notification)})
            willDiscoverServicesObserver = notificationCenter.addObserver(forName: .willDiscoverServices, object: nil, queue: .main, using: {[weak self] notification in self?.willDiscoverServices(notification: notification)})

        } else {
            if let didDiscoverPeripheralObserver = didDiscoverPeripheralObserver {notificationCenter.removeObserver(didDiscoverPeripheralObserver)}
            if let didUnDiscoverPeripheralObserver = didUnDiscoverPeripheralObserver {notificationCenter.removeObserver(didUnDiscoverPeripheralObserver)}
            if let willConnectToPeripheralObserver = willConnectToPeripheralObserver {notificationCenter.removeObserver(willConnectToPeripheralObserver)}
            if let didConnectToPeripheralObserver = didConnectToPeripheralObserver {notificationCenter.removeObserver(didConnectToPeripheralObserver)}
            if let didDisconnectFromPeripheralObserver = didDisconnectFromPeripheralObserver {notificationCenter.removeObserver(didDisconnectFromPeripheralObserver)}
            if let peripheralDidUpdateNameObserver = peripheralDidUpdateNameObserver {notificationCenter.removeObserver(peripheralDidUpdateNameObserver)}
            if let willDiscoverServicesObserver = willDiscoverServicesObserver {notificationCenter.removeObserver(willDiscoverServicesObserver)}
        }
    }

    private func willConnectToPeripheral(notification: Notification) {
        guard let selectedPeripheral = selectedPeripheral, let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, selectedPeripheral.identifier == identifier else {
                 DLog("willConnect to an unexpected peripheral")
                 return
             }

        let localizationManager = LocalizationManager.shared
        updateStatusLabel()
        detailLabel.text = localizationManager.localizedString("scanner_connecting")
    }

    private func didConnectToPeripheral(notification: Notification) {
        guard let selectedPeripheral = selectedPeripheral, let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, selectedPeripheral.identifier == identifier else {
            DLog("didConnect to an unexpected peripheral")
            return
        }

        // Setup peripheral
        CPBBle.shared.setupPeripheral(blePeripheral: selectedPeripheral) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                DLog("setupPeripheral success")

                // Finished setup
                self.showPeripheralDetails()

            case .failure(let error):
                DLog("setupPeripheral error: \(error.localizedDescription)")
                let localizationManager = LocalizationManager.shared

                let alertController = UIAlertController(title: localizationManager.localizedString("dialog_error"), message: localizationManager.localizedString("uart_error_peripheralinit"), preferredStyle: .alert)
                let okAction = UIAlertAction(title: localizationManager.localizedString("dialog_ok"), style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)

                self.disconnect(peripheral: selectedPeripheral)
            }
        }
    }

    private func willDiscoverServices(notification: Notification) {
        detailLabel.text = LocalizationManager.shared.localizedString("scanner_discoveringservices")
    }

    private func didDisconnectFromPeripheral(notification: Notification) {
        let peripheral = bleManager.peripheral(from: notification)
        let currentlyConnectedPeripheralsCount = bleManager.connectedPeripherals().count
        guard let selectedPeripheral = selectedPeripheral, selectedPeripheral.identifier == peripheral?.identifier || currentlyConnectedPeripheralsCount == 0 else {        // If selected peripheral is disconnected or if there are no peripherals connected (after a failed dfu update)
            return
        }

        // Clear selected peripheral
        self.selectedPeripheral = nil

        // UI
        updateStatusLabel()
    }

    private func peripheralDidUpdateName(notification: Notification) {
        let name = notification.userInfo?[BlePeripheral.NotificationUserInfoKey.name.rawValue] as? String
        DLog("centralManager peripheralDidUpdateName: \(name ?? "<unknown>")")

        updateStatusLabel()
    }

    // MARK: - Connections
    private func connect(peripheral: BlePeripheral) {
        // Connect to selected peripheral
        selectedPeripheral = peripheral
        bleManager.connect(to: peripheral)
    }

    private func disconnect(peripheral: BlePeripheral) {
        selectedPeripheral = nil
        bleManager.disconnect(from: peripheral)
    }

    // MARK: - Actions
    @IBAction func troubleshooting(_ sender: Any) {
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: AboutViewController.kIdentifier) else { return }

        self.present(viewController, animated: true, completion: nil)
    }

    @IBAction func scanManually(_ sender: Any) {
        ScreenFlowManager.goToManualScan()
    }

    private func showPeripheralDetails() {
        // Save selected peripheral for autoconnect
        Settings.autoconnectPeripheralIdentifier = selectedPeripheral?.identifier

        ScreenFlowManager.gotoCPBModules()
    }

    // MARK: - UI
    private func refreshPeripherals() {
        bleManager.refreshPeripherals()
        //   reloadBaseTable()
    }

    private func updateScannedPeripherals() {
        // Update peripheralAutoconnect
        if let peripheral = peripheralAutoConnect.update(peripheralList: peripheralList) {
            // Connect to closest CPB
            connect(peripheral: peripheral)
        }
    }

    private func updateStatusLabel() {
        let localizationManager = LocalizationManager.shared

        let statusText: String
        if let selectedPeripheral = selectedPeripheral {
            statusText = "Device found:\n\(selectedPeripheral.name ?? localizationManager.localizedString("scanner_unnamed"))"

            // Animate found CPB
            UIView.animate(withDuration: 0.1, animations: {
                self.cpbContainerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { didFinish in
                if didFinish {
                    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [.curveEaseOut], animations: {
                        self.cpbContainerView.transform = .identity
                    }, completion: nil)

                    UIView.animate(withDuration: 0.3) {
                        self.cpbImageView.alpha = 1
                    }
                }
            }

        } else {
            UIView.animate(withDuration: 0.3) {
                self.cpbImageView.alpha = 0.2
            }
            statusText = localizationManager.localizedString("scanner_searching")
            detailLabel.text = " "
        }

        statusLabel.text = statusText
    }
}

// MARK: UIScrollViewDelegate
extension AutoConnectViewController {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        // NavigationBar Button Custom Animation
        if let customNavigationBar = navigationController?.navigationBar as? NavigationBarWithScrollAwareRightButton {
            customNavigationBar.updateRightButtonPosition()
        }
    }
}

// MARK: - Animations
extension AutoConnectViewController {

    private func stopAnimating() {
        isAnimating = false

        if isViewLoaded {
            let waveImageViews = [wave0ImageView, wave1ImageView]//, wave2ImageView]

            for waveImageView in waveImageViews {
                if let waveImageView = waveImageView {
                    waveImageView.layer.removeAllAnimations()
                    waveImageView.alpha = 0
                }
            }
        }
    }

    private func startAnimating() {
        isAnimating = true
        guard isViewLoaded else { return }

        let waveImageViews = [wave0ImageView, wave1ImageView]//, wave2ImageView]

        // Scanning animation
        let duration: Double = 8
        let initialScaleFactor: CGFloat = 0.60
        let finalScaleFactor: CGFloat = 1.10

        let initialAlphaFactor: CGFloat = 0.80
        let finalAlphaFactor: CGFloat = 0

        // -    Initial position
        let introMaxValueFactor: CGFloat = 0.7

        for (i, waveImageView) in waveImageViews.enumerated() {
            if let waveImageView = waveImageView {
                //DLog("intro: \(i)")

                let factor: CGFloat = CGFloat(i) / CGFloat(waveImageViews.count-1) * introMaxValueFactor
                let scaleFactor = (finalScaleFactor - initialScaleFactor) * factor + initialScaleFactor
                waveImageView.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)

                let alphaFactor = (finalAlphaFactor - initialAlphaFactor) * factor + initialAlphaFactor
                waveImageView.alpha = alphaFactor

                // DLog("\(i): factor: \(factor) scale: \(scaleFactor)")

                let introDuration = (1 - Double(factor)) * duration
                UIView.animate(withDuration: introDuration, delay: 0, options: [.curveEaseOut], animations: {
                    waveImageView.transform = CGAffineTransform(scaleX: finalScaleFactor, y: finalScaleFactor)
                    waveImageView.alpha = finalAlphaFactor
                }, completion: { _ in
                    // Ongoing
                    waveImageView.transform = CGAffineTransform(scaleX: initialScaleFactor, y: initialScaleFactor)
                    waveImageView.alpha = initialAlphaFactor

                    UIView.animate(withDuration: duration, delay: 0, options: [.repeat, .curveEaseOut], animations: {
                        waveImageView.transform = CGAffineTransform(scaleX: finalScaleFactor, y: finalScaleFactor)
                        waveImageView.alpha = finalAlphaFactor
                    }, completion: nil)
                })
            }
        }
    }
}
