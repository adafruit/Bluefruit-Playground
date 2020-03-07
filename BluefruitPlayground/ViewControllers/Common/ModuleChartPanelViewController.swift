//
//  ChartPanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import Charts

class ChartPanelViewController: ModulePanelViewController {
    // UI
    @IBOutlet weak var chartView: LineChartView!
    
    // Data
    private var isAutoScrollEnabled = true
    private var visibleInterval: TimeInterval = 20      // in seconds
    private var dataSet: LineChartDataSet?
    private var originTimestamp = CFAbsoluteTimeGetCurrent()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChart()
    }
    
    // MARK: - Data
    internal func dataSeriesValueToCharValue(_ value: Float) -> Double {
        return Double(value)
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
    }
    
    internal func reloadChartEntries(dataSeries: [SensorDataSeries<Float>.Entry]) {
        
        originTimestamp = dataSeries.first?.timestamp ?? CFAbsoluteTimeGetCurrent()
        let entries = chartEntries(dataSeries: dataSeries)
        
        // Add Dataset
        dataSet = LineChartDataSet(entries: entries, label: "")
        
        dataSet?.drawCirclesEnabled = false
        dataSet?.drawValuesEnabled = false
        dataSet?.lineWidth = 2
        dataSet?.setColor(UIColor.blue)
        //dataSet?.lineDashLengths = lineDashForPeripheral[identifier]!
        //DLog("color: \(color.hexString()!)")
        
        // Set dataset
        chartView.data = LineChartData(dataSet: dataSet)
    }
    
    private func notifyDataSetChanged() {
        let isViewVisible = self.viewIfLoaded?.window != nil  // https://stackoverflow.com/questions/2777438/how-to-tell-if-uiviewcontrollers-view-is-visible
        guard isViewVisible else { return }
        guard let dataSet = dataSet else { return }
        
        chartView.data?.notifyDataChanged()
        chartView.notifyDataSetChanged()
        chartView.setVisibleXRangeMaximum(visibleInterval)
        chartView.setVisibleXRangeMinimum(visibleInterval)
        
        if isAutoScrollEnabled {
            let xOffset = (dataSet.entries.last?.x ?? 0) - (visibleInterval-1)
            chartView.moveViewToX(xOffset)
        }
    }
    
    // MARK:- Utils
    private func chartEntries(dataSeries: [SensorDataSeries<Float>.Entry]) -> [ChartDataEntry] {
        let chartEntries = dataSeries.map { entry -> ChartDataEntry in
            let value = dataSeriesValueToCharValue(entry.value)
            return ChartDataEntry(x: entry.timestamp - originTimestamp, y: value)
        }
        return chartEntries
    }
    
    // MARK: - Actions
    func addEntry(_ entry: SensorDataSeries<Float>.Entry) {
        guard let dataSet = dataSet else { return }
        
        let value = dataSeriesValueToCharValue(entry.value)
        let newElement = ChartDataEntry(x: entry.timestamp - originTimestamp, y: value)
        _ = dataSet.append(newElement)
        
        notifyDataSetChanged()
    }
}
