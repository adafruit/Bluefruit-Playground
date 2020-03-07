//
//  HumidityPanelViewController.swift
//  BluefruitPlayground
//
//  Created by Antonio García on 25/10/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import UIKit
import Charts

class HumidityPanelViewController: ModulePanelViewController {
    // Constants
    static let kIdentifier = "HumidityPanelViewController"

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
        titleLabel.text = localizationManager.localizedString("humidity_panel_title")
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
        if let board = AdafruitBoardsManager.shared.currentBoard {
            let dataSeries = board.humidityDataSeries()
            originTimestamp = dataSeries.first?.timestamp ?? CFAbsoluteTimeGetCurrent()
        }
        
        // Load initial data
        reloadChartEntries()
    }

    private func reloadChartEntries() {
        guard let board = AdafruitBoardsManager.shared.currentBoard else { return }

        let dataSeries = board.humidityDataSeries()

        let chartEntries = dataSeries.map { entry -> ChartDataEntry in
            let value = Double(entry.value)
            return ChartDataEntry(x: entry.timestamp - originTimestamp, y: value)
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
    func humidityValueReceived() {
        let board = AdafruitBoardsManager.shared.currentBoard
        guard let lastHumidityDataSeries = board?.humidityDataSeries().last else { return }

        let value = Double(lastHumidityDataSeries.value)
        let entry = ChartDataEntry(x: lastHumidityDataSeries.timestamp - originTimestamp, y: value)
        _ = dataSet.append(entry)

        notifyDataSetChanged()
    }
}
