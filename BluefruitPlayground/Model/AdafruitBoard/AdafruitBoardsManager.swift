//
//  AdafruitBoardsManager.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 06/03/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import Foundation

/**
 - Note: At the moment It only supports a single connected board (cannot be used to manage multiple connected boards simultaneously)

 */
class AdafruitBoardsManager {
    // Singleton
    static let shared = AdafruitBoardsManager()
    
    // Data
    private(set) var currentBoard: AdafruitBoard?
    
    // MARK: - Lifecycle
    private init() {
        registerNotifications(enabled: true)
    }

    deinit {
        registerNotifications(enabled: false)
    }

    // MARK: - Start / Stop
    
    /**
    Setups a new Adafruit Board
    
    - Supported services:
       - neopixels
       - light
       - buttons
       - tone generator
       - accelerometer
       - temperature

    */
    func startBoard(connectedBlePeripheral blePeripheral: BlePeripheral, services: [AdafruitBoard.BoardService]? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard blePeripheral.state == .connected else {
            completion(.failure(AdafruitBoard.BoardError.errorBoardNotConnected))
            return
        }
        
        // Clear current board
        stopCurrentBoard()
        
        // Setup peripheral
        let adafruitBoard = AdafruitBoard()
        adafruitBoard.setupPeripheral(blePeripheral: blePeripheral, services: services) { [weak self] result in
            guard let self = self else { return }
            if case .success = result {
                self.currentBoard = adafruitBoard
            }
            completion(result)
        }
    }
    
    func stopCurrentBoard() {
        self.currentBoard = nil
    }
    
    // MARK: - BLE Notifications
    private weak var willdDisconnectFromPeripheralObserver: NSObjectProtocol?
    
    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            willdDisconnectFromPeripheralObserver = notificationCenter.addObserver(forName: .willDisconnectFromPeripheral, object: nil, queue: .main, using: {[weak self] notification in
                
                // Check that this notification is for the currentBoard
                guard let board = self?.currentBoard else { return }
                guard let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, identifier == board.blePeripheral?.identifier else { return }
                
                // Force clear neopixels on disconnect
                board.neopixelSetAllPixelsColor(.clear)
            })
            
        } else {
            if let willdDisconnectFromPeripheralObserver = willdDisconnectFromPeripheralObserver {notificationCenter.removeObserver(willdDisconnectFromPeripheralObserver)}
        }
    }
}
