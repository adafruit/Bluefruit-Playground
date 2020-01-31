//
//  ScannerViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 11/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import CoreBluetooth

class ScannerViewController: UIViewController {
    // Constants
    static let kNavigationControllerIdentifier = "ScannerNavigationController"
    
    // Config
    private static let kDelayToShowWait: TimeInterval = 1.0
    
    // UI
    @IBOutlet weak var baseTableView: UITableView!
    @IBOutlet weak var waitView: UIView!
    @IBOutlet weak var waitLabel: UILabel!
    @IBOutlet weak var problemsButton: UIButton!
    @IBOutlet weak var scanAutomaticallyButton: CornerShadowButton!
    @IBOutlet weak var actionsContainerView: UIStackView!
    
    // Data
    private let refreshControl = UIRefreshControl()
    private let bleManager = Config.bleManager
    private var peripheralList = PeripheralList(bleManager: Config.bleManager)
    
    private var selectedPeripheral: BlePeripheral? {
        didSet {
            if isViewLoaded {
                UIView.animate(withDuration: 0.3) {
                    self.actionsContainerView.alpha = self.selectedPeripheral == nil ? 1:0
                }
            }
        }
    }
    private var infoAlertController: UIAlertController?
    
    private var isBaseTableScrolling = false
    private var isScannerTableWaitingForReload = false

    private let navigationButton = UIButton(type: .custom)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI
        waitView.alpha = 0
        let topContentInsetForDetails: CGFloat = 20
        baseTableView.contentInset = UIEdgeInsets(top: topContentInsetForDetails, left: 0, bottom: 0, right: 0)
        
        // Setup table refresh
        refreshControl.addTarget(self, action: #selector(tableRefresh), for: UIControl.Event.valueChanged)
        baseTableView.addSubview(refreshControl)
        refreshControl.tintColor = waitLabel.textColor

        // Ble Notifications
        registerNotifications(enabled: true)
        
        // Localization
        let localizationManager = LocalizationManager.shared
        self.title = localizationManager.localizedString("scanner_title")
        
        waitLabel.text = localizationManager.localizedString("scanner_searching")
        problemsButton.setTitle(localizationManager.localizedString("scanner_problems_action").uppercased(), for: .normal)
        scanAutomaticallyButton.setTitle(localizationManager.localizedString("scanner_automatic_action").uppercased(), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.backBarButtonItem = nil     // Clear any custom back button
        
        if let customNavigationBar = navigationController?.navigationBar as? NavigationBarWithScrollAwareRightButton {
            customNavigationBar.setRightButton(topViewController: self, image: UIImage(named: "info"), target: self, action: #selector(about(_:)))
        }

        // Disconnect if needed
        let connectedPeripherals = bleManager.connectedPeripherals()
        if connectedPeripherals.count == 1, let peripheral = connectedPeripherals.first {
            DLog("Disconnect from previously connected peripheral")
            // Disconnect from peripheral
            disconnect(peripheral: peripheral)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Flush any pending state notifications
        didUpdateBleState()
        
        // Update UI
        updateScannedPeripherals()

        // Start scannning
        //bleManager.startScan(withServices: ScannerViewController.kServicesToScan)
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
                
        // Clear peripherals
        peripheralList.clear()
    }
    
    deinit {
        // Ble Notifications
        registerNotifications(enabled: false)
    }
    
    // MARK: - BLE Notifications
    private weak var didUpdateBleStateObserver: NSObjectProtocol?
    private weak var didDiscoverPeripheralObserver: NSObjectProtocol?
    private weak var willConnectToPeripheralObserver: NSObjectProtocol?
    private weak var didConnectToPeripheralObserver: NSObjectProtocol?
    private weak var didDisconnectFromPeripheralObserver: NSObjectProtocol?
    private weak var peripheralDidUpdateNameObserver: NSObjectProtocol?
    private weak var willDiscoverServicesObserver: NSObjectProtocol?

    
    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            didUpdateBleStateObserver = notificationCenter.addObserver(forName: .didUpdateBleState, object: nil, queue: .main, using: {[weak self] _ in self?.didUpdateBleState()})
            didDiscoverPeripheralObserver = notificationCenter.addObserver(forName: .didDiscoverPeripheral, object: nil, queue: .main, using: {[weak self] _ in self?.didDiscoverPeripheral()})
            willConnectToPeripheralObserver = notificationCenter.addObserver(forName: .willConnectToPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.willConnectToPeripheral(notification: notification)})
            didConnectToPeripheralObserver = notificationCenter.addObserver(forName: .didConnectToPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.didConnectToPeripheral(notification: notification)})
            didDisconnectFromPeripheralObserver = notificationCenter.addObserver(forName: .didDisconnectFromPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.didDisconnectFromPeripheral(notification: notification)})
            peripheralDidUpdateNameObserver = notificationCenter.addObserver(forName: .peripheralDidUpdateName, object: nil, queue: .main, using: {[weak self] notification in self?.peripheralDidUpdateName(notification: notification)})
            willDiscoverServicesObserver = notificationCenter.addObserver(forName: .willDiscoverServices, object: nil, queue: .main, using: {[weak self] notification in self?.willDiscoverServices(notification: notification)})

        } else {
            if let didUpdateBleStateObserver = didUpdateBleStateObserver {notificationCenter.removeObserver(didUpdateBleStateObserver)}
            if let didDiscoverPeripheralObserver = didDiscoverPeripheralObserver {notificationCenter.removeObserver(didDiscoverPeripheralObserver)}
            if let willConnectToPeripheralObserver = willConnectToPeripheralObserver {notificationCenter.removeObserver(willConnectToPeripheralObserver)}
            if let didConnectToPeripheralObserver = didConnectToPeripheralObserver {notificationCenter.removeObserver(didConnectToPeripheralObserver)}
            if let didDisconnectFromPeripheralObserver = didDisconnectFromPeripheralObserver {notificationCenter.removeObserver(didDisconnectFromPeripheralObserver)}
            if let peripheralDidUpdateNameObserver = peripheralDidUpdateNameObserver {notificationCenter.removeObserver(peripheralDidUpdateNameObserver)}
            if let willDiscoverServicesObserver = willDiscoverServicesObserver {notificationCenter.removeObserver(willDiscoverServicesObserver)}
        }
    }
    
    private func didUpdateBleState() {
        guard Config.isBleUnsupportedWarningEnabled else { return }
        guard let state = bleManager.centralManager?.state else { return }
        
        // Check if there is any error
        var errorMessageId: String?
        switch state {
        case .unsupported:
            errorMessageId = "bluetooth_unsupported"
        case .unauthorized:
            errorMessageId = "bluetooth_notauthorized"
        case .poweredOff:
            errorMessageId = "bluetooth_poweredoff"
        default:
            errorMessageId = nil
        }
        
        // Show alert if error found
        if let errorMessageId = errorMessageId {
            let localizationManager = LocalizationManager.shared
            let errorMessage = localizationManager.localizedString(errorMessageId)
            DLog("Error: \(errorMessage)")
            
            // Reload peripherals
            refreshPeripherals()
            
            // Show error
            let alertController = UIAlertController(title: localizationManager.localizedString("dialog_error"), message: errorMessage, preferredStyle: .alert)
            let okAction = UIAlertAction(title: localizationManager.localizedString("dialog_ok"), style: .default, handler: { (_) -> Void in
                if let navController = self.splitViewController?.viewControllers[0] as? UINavigationController {
                    navController.popViewController(animated: true)
                }
            })
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func didDiscoverPeripheral() {
        // Update current scanning state
        updateScannedPeripherals()
    }
    
    private func willConnectToPeripheral(notification: Notification) {
        guard let peripheral = bleManager.peripheral(from: notification) else { return }
        presentInfoDialog(title: LocalizationManager.shared.localizedString("scanner_connecting"), peripheral: peripheral)
    }
    
    private func didConnectToPeripheral(notification: Notification) {
        guard let selectedPeripheral = selectedPeripheral, let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, selectedPeripheral.identifier == identifier else {
            DLog("Connected to an unexpected peripheral")
            return
        }
        
        // Setup peripheral
        CPBBle.shared.setupPeripheral(blePeripheral: selectedPeripheral) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success():
                DLog("setupPeripheral success")
                
                // Finished setup
                self.dismissInfoDialog {
                    self.showPeripheralDetails()
                }
                
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
        infoAlertController?.message = LocalizationManager.shared.localizedString("scanner_discoveringservices")
    }

    private func didDisconnectFromPeripheral(notification: Notification) {
        let peripheral = bleManager.peripheral(from: notification)
        let currentlyConnectedPeripheralsCount = bleManager.connectedPeripherals().count
        
        guard let selectedPeripheral = selectedPeripheral, selectedPeripheral.identifier == peripheral?.identifier || currentlyConnectedPeripheralsCount == 0 else {        // If selected peripheral is disconnected or if there are no peripherals connected (after a failed dfu update)
            return
        }
        
        // Clear selected peripheral
        self.selectedPeripheral = nil
        
        // Dismiss any info open dialogs
        infoAlertController?.dismiss(animated: true, completion: nil)
        infoAlertController = nil
        
        // Reload table
        reloadBaseTable()
    }
    
    private func peripheralDidUpdateName(notification: Notification) {
        let name = notification.userInfo?[BlePeripheral.NotificationUserInfoKey.name.rawValue] as? String
        DLog("centralManager peripheralDidUpdateName: \(name ?? "<unknown>")")
        
        DispatchQueue.main.async {
            // Reload table
            self.reloadBaseTable()
        }
    }
    
    // MARK: - Connections
    private func connect(peripheral: BlePeripheral) {
        // Connect to selected peripheral
        selectedPeripheral = peripheral
        bleManager.connect(to: peripheral)
        reloadBaseTable()
    }
    
    private func disconnect(peripheral: BlePeripheral) {
        selectedPeripheral = nil
        bleManager.disconnect(from: peripheral)
        reloadBaseTable()
    }
    
    // MARK: - Actions
    @objc func tableRefresh() {
        refreshPeripherals()
        refreshControl.endRefreshing()
    }
    
    @IBAction func about(_ sender: Any) {
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: AboutViewController.kIdentifier) else { return }
    
        self.present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func scanAutomatically(_ sender: Any) {
        ScreenFlowManager.gotoAutoconnect()
    }
    
    private func showPeripheralDetails() {
        // Save selected peripheral for autoconnect
        Settings.autoconnectPeripheralIdentifier = selectedPeripheral?.identifier
        
        // Go to home screen
        ScreenFlowManager.gotoCPBModules()
    }
    
    // MARK: - UI
    private func refreshPeripherals() {
        bleManager.refreshPeripherals()
        reloadBaseTable()
    }
    
    private func updateScannedPeripherals() {
        
        // Reload table
        if isBaseTableScrolling {
            isScannerTableWaitingForReload = true
        } else {
            reloadBaseTable()
        }
    }
    
    private func reloadBaseTable() {
        isBaseTableScrolling = false
        isScannerTableWaitingForReload = false
        let filteredPeripherals = peripheralList.filteredPeripherals(forceUpdate: true)     // Refresh the peripherals
        baseTableView.reloadData()
        
        // Select the previously selected row
        if let selectedPeripheral = selectedPeripheral, let selectedRow = filteredPeripherals.firstIndex(of: selectedPeripheral) {
            baseTableView.selectRow(at: IndexPath(row: selectedRow + 1, section: 0), animated: false, scrollPosition: .none)
        }
        
        //
        updateDetailsCellOpacity()
    }
    
    private func presentInfoDialog(title: String, peripheral: BlePeripheral) {
        if infoAlertController != nil {
            infoAlertController?.dismiss(animated: true, completion: nil)
        }
        
        infoAlertController = UIAlertController(title: nil, message: title, preferredStyle: .alert)
        infoAlertController!.addAction(UIAlertAction(title: LocalizationManager.shared.localizedString("dialog_cancel"), style: .cancel, handler: { [weak self] _ in
            self?.bleManager.disconnect(from: peripheral)
        }))
        present(infoAlertController!, animated: true, completion:nil)
    }
    
    private func dismissInfoDialog(completion: (() -> Void)? = nil) {
        guard infoAlertController != nil else {
            completion?()
            return
        }
        
        infoAlertController?.dismiss(animated: true, completion: completion)
        infoAlertController = nil
    }
    
    private var wasWaitVisible = false
    private func updateWaitView() {
        let numPeripherals = peripheralList.filteredPeripherals(forceUpdate: false).count
        let isWaitVisible = numPeripherals == 0
        if wasWaitVisible != isWaitVisible {
            self.wasWaitVisible = isWaitVisible
            waitView.layer.removeAllAnimations()
            if isWaitVisible {
                UIView.animate(withDuration: 0.2, delay: ScannerViewController.kDelayToShowWait, options: [], animations: {
                    self.waitView.alpha = 1
                }, completion: nil)
            }
            else {
                self.waitView.alpha = 0
            }
        }
    }
    
    private func updateDetailsCellOpacity() {
        guard let detailsCell = baseTableView.visibleCells.first(where: { $0 is TitleTableViewCell }) else { return }
        
        guard let customNavigationBar = navigationController?.navigationBar as? NavigationBarWithScrollAwareRightButton else { return }

        let titleTableViewCell = detailsCell as! TitleTableViewCell
        titleTableViewCell.alpha = max(0, 2 - customNavigationBar.navigationBarScrollViewProgress)
    }
}

// MARK: - UITableViewDataSource
extension ScannerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Update wait prompt (wait 1 second to make it visible)
        updateWaitView()

        // Calculate num cells
        // (1 detail cell + num peripherals) if at least 1 peripheral is found
        let numPeripherals = peripheralList.filteredPeripherals(forceUpdate: false).count
        return numPeripherals > 0 ? 1 + numPeripherals : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isDetails = indexPath.row == 0
        
        let reuseIdentifier = isDetails ? "DetailsCell" : "PeripheralCell"
        return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
    }
}

// MARK: UITableViewDelegate
extension ScannerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let localizationManager = LocalizationManager.shared
        let isDetails = indexPath.row == 0
        
        if isDetails {
            let detailsCell = cell as! TitleTableViewCell
            
            detailsCell.titleLabel.text = localizationManager.localizedString("scanner_subtitle")
        }
        else {
            let peripheralCell = cell as! CommonTableViewCell
            let peripheralIndex = indexPath.row - 1
            let peripheral = peripheralList.filteredPeripherals(forceUpdate: false)[peripheralIndex]
            
            // Fill peripheral data
            peripheralCell.titleLabel.text = peripheral.name ?? localizationManager.localizedString("scanner_unnamed")
            peripheralCell.iconImageView.image = RssiUI.signalImage(for: peripheral.rssi)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let isDetails = indexPath.row == 0
        guard !isDetails else { return }
        
        let peripheralIndex = indexPath.row - 1
        let peripheral = peripheralList.filteredPeripherals(forceUpdate: false)[peripheralIndex]
        
        connect(peripheral: peripheral)
    }
}

// MARK: UIScrollViewDelegate
extension ScannerViewController {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isBaseTableScrolling = true
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isBaseTableScrolling = false

        if isScannerTableWaitingForReload {
            reloadBaseTable()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // NavigationBar Button Custom Animation
        if let customNavigationBar = navigationController?.navigationBar as? NavigationBarWithScrollAwareRightButton {
            customNavigationBar.updateRightButtonPosition()
        }

        // Move Refresh control when a large title is used
        if let height = navigationController?.navigationBar.frame.height {
        refreshControl.bounds = CGRect(x: refreshControl.bounds.origin.x, y: NavigationBarWithScrollAwareRightButton.navBarHeightLargeState - height, width: refreshControl.bounds.size.width, height: refreshControl.bounds.size.height)
        }
        
        // Hide details opacity when showing the refresh control
        updateDetailsCellOpacity()
    }
}
