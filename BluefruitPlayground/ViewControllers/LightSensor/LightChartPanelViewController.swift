//
//  LightPanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 31/01/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit

class LightChartPanelViewController: ChartPanelViewController {
    // Constants
    static let kIdentifier = "LightPanelViewController"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init data
        if let board = AdafruitBoardsManager.shared.currentBoard {
            let dataSeries = board.lightDataSeries()
            
            // Load initial data
            reloadChartEntries(dataSeries: dataSeries)
        }
        
        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("lightsensor_chartpanel_title")
    }
    
    // MARK: - Actions
    func updateLastEntryAddedToDataSeries() {
        guard let entry = AdafruitBoardsManager.shared.currentBoard?.lightDataSeries().last else { return }
        addEntry(entry)
    }
}
