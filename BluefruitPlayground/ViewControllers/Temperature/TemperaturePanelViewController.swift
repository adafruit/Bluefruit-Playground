//
//  TemperaturePanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import Charts

class TemperaturePanelViewController: ChartPanelViewController {
    // Constants
    static let kIdentifier = "TemperaturePanelViewController"
    
    // Params
    var isCelsius = true {
        didSet {
            if self.isViewLoaded {
                reloadChartEntries()
                //notifyDataSetChanged()
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init data
        reloadChartEntries()
        
        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("temperature_panel_title")
    }
    
    
    override func dataSeriesValueToChartValue(_ value: Float) -> Double {
        let temperatureCelsius = Double(value)
        let temperature = isCelsius ? temperatureCelsius : (temperatureCelsius * 1.8 + 32)
        return temperature
    }
    
    private func reloadChartEntries() {
        guard let board = AdafruitBoardsManager.shared.currentBoard else { return }
        
        // Load initial data
        reloadChartEntries(dataSeries: board.temperatureDataSeries)
    }
    
    
    // MARK: - Actions
    func updateLastEntryAddedToDataSeries() {
        guard let entry = AdafruitBoardsManager.shared.currentBoard?.temperatureDataSeries.last else { return }
        addEntry(entry)
    }
}
