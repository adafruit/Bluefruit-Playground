//
//  LightPanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 31/01/2020.
//  Copyright © 2020 Adafruit. All rights reserved.
//

import UIKit
import Charts

class LightChartPanelViewController: ModulePanelViewController {
    // Constants
    static let kIdentifier = "LightPanelViewController"
    
    // UI
    @IBOutlet weak var chartView: LineChartView!
    
    // Data
    private var isAutoScrollEnabled = true
    private var visibleInterval: TimeInterval = 20      // in seconds
    private var dataSet: LineChartDataSet!
    private var originTimestamp: CFAbsoluteTime!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChart()
        
        // Localization
        let localizationManager = LocalizationManager.shared
        titleLabel.text = localizationManager.localizedString("lightsensor_chartpanel_title")
        
    }
    
    // MARK: - Line Chart
    private func setupChart() {
        //chartView.delegate = self
        chartView.backgroundColor = .clear      // Fix for Charts 3.0.3 (overrides the default background color)
        
        chartView.dragEnabled = false
        chartView.isUserInteractionEnabled = false
        chartView.chartDescription?.enabled = false
        chartView.xAxis.granularityEnabled = true
        chartView.xAxis.granularity = 5
        chartView.rightAxis.enabled = false
        //        chartView.rightAxis.valueFormatter =
        //chartView.leftAxis.drawZeroLineEnabled = true
        //chartView.setExtraOffsets(left: 10, top: 10, right: 10, bottom: 0)
        chartView.legend.enabled = false
        chartView.noDataText = LocalizationManager.shared.localizedString("temperature_chart_nodata")
        
        // Timestamp
        let lightDataSeries = CPBBle.shared.lightDataSeries()
        originTimestamp = lightDataSeries.first?.timestamp ?? CFAbsoluteTimeGetCurrent()
        
        // Load initial data
        reloadChartEntries()
    }
    
    private func reloadChartEntries() {
        let lightDataSeries = CPBBle.shared.lightDataSeries()
        
        let chartEntries = lightDataSeries.map { entry -> ChartDataEntry in
            let lightReading = Double(entry.value)
            return ChartDataEntry(x: entry.timestamp - originTimestamp, y: lightReading)
        }
        
        // Add Dataset
        dataSet = LineChartDataSet(entries: chartEntries, label: "")
        
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 2
        dataSet.setColor(UIColor.blue)
        //dataSet.lineDashLengths = lineDashForPeripheral[identifier]!
        //DLog("color: \(color.hexString()!)")
        
        // Set dataset
        chartView.data = LineChartData(dataSet: dataSet)
    }
    
    private func notifyDataSetChanged() {
        let isViewVisible = self.viewIfLoaded?.window != nil  // https://stackoverflow.com/questions/2777438/how-to-tell-if-uiviewcontrollers-view-is-visible
        guard isViewVisible else { return }
        
        chartView.data?.notifyDataChanged()
        chartView.notifyDataSetChanged()
        chartView.setVisibleXRangeMaximum(visibleInterval)
        chartView.setVisibleXRangeMinimum(visibleInterval)
        
        if isAutoScrollEnabled {
            let xOffset = (dataSet.entries.last?.x ?? 0) - (visibleInterval-1)
            chartView.moveViewToX(xOffset)
        }
    }
    
    // MARK: - Actions
    func lightValueReceived() {
        guard let lastLightDataSeries = CPBBle.shared.lightDataSeries().last else { return }
        
        let light = Double(lastLightDataSeries.value)
        let entry = ChartDataEntry(x: lastLightDataSeries.timestamp - originTimestamp, y: light)
        let _ = dataSet.append(entry)
        
        notifyDataSetChanged()
    }
    
}
