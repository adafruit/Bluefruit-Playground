//
//  HumidityPanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import Charts

class HumidityPanelViewController: ChartPanelViewController {
    // Constants
    static let kIdentifier = "HumidityPanelViewController"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init data
        if let board = AdafruitBoardsManager.shared.currentBoard {
            let dataSeries = board.humidityDataSeries()
            
            // Load initial data
            reloadChartEntries(dataSeries: dataSeries)
        }
        
        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("humidity_panel_title")
    }

    // MARK: - Actions
    func updateLastEntryAddedToDataSeries() {
        guard let entry = AdafruitBoardsManager.shared.currentBoard?.humidityDataSeries().last else { return }
        addEntry(entry)
    }
}
