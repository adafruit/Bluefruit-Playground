//
//  SoundPanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import Charts

class SoundPanelViewController: ChartPanelViewController {
    // Constants
    static let kIdentifier = "SoundPanelViewController"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init data
        if let board = AdafruitBoardsManager.shared.currentBoard {
            // Load initial data
            reloadChartEntries(dataSeries: board.soundDataSeries)
        }
        
        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("sound_panel_title")
    }

    // MARK: - Actions
    func updateLastEntryAddedToDataSeries() {
        guard let entry = AdafruitBoardsManager.shared.currentBoard?.barometricPressureDataSeries.last else { return }
        addEntry(entry)
    }
}
