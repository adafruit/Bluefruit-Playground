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
        
        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("lightsensor_chartpanel_title")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Reload data
        if let board = AdafruitBoardsManager.shared.currentBoard {
            // Load initial data
            reloadChartEntries(dataSeries: board.lightDataSeries)
        }
    }
    
    // MARK: - Actions
    func updateLastEntryAddedToDataSeries() {
        guard let entry = AdafruitBoardsManager.shared.currentBoard?.lightDataSeries.last else { return }
        addEntry(entry)
    }
}
