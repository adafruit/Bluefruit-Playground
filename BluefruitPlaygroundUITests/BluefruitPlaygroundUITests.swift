//
//  BluefruitPlaygroundUITests.swift
//  BluefruitPlaygroundUITests
//
//  Created by Antonio García on 14/12/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

import XCTest

class BluefruitPlaygroundUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSnapshots() {
        /*
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
*/
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let app = XCUIApplication()
        let scrollViewsQuery = app.scrollViews
        let elementsQuery = scrollViewsQuery.otherElements
        
        sleep(2)        // Wait for the intro animation
        snapshot("01a_Welcome")
        
        elementsQuery.buttons["LET'S GET STARTED..."].tap()
        snapshot("01b_PowerUp")

        elementsQuery.buttons["NEXT"].tap()
        snapshot("01c_Discover")
        elementsQuery.buttons["BEGIN PAIRING"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Simulated Peripheral"].tap()

        snapshot("02_Modules")

        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Control LED color & animation"]/*[[".cells.staticTexts[\"Control LED color & animation\"]",".staticTexts[\"Control LED color & animation\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        let element = scrollViewsQuery.children(matching: .other).element
        element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .button).element.tap()
        snapshot("03_Neopixels_LightSequence")
        
        elementsQuery.staticTexts["Light Sequence"].swipeLeft()
        element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .button).element(boundBy: 2).tap()
        
        snapshot("04a_Neopixels_ColorPalette")
        
        elementsQuery.staticTexts["Color Palette"].swipeLeft()
        element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.tap()
        
        snapshot("04b_Neopixels_ColorWheel")
        
        app.navigationBars["NeoPixels"].buttons["Modules"].tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["View continuous light sensor readings"]/*[[".cells.staticTexts[\"View continuous light sensor readings\"]",".staticTexts[\"View continuous light sensor readings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("05_LightSensor")
        app.navigationBars["Light Sensor"].buttons["Modules"].tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Button Status"]/*[[".cells.staticTexts[\"Button Status\"]",".staticTexts[\"Button Status\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("06_ButtonStatus")
        app.navigationBars["Button Status"].buttons["Modules"].tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Turn CPB into a musical instrument"]/*[[".cells.staticTexts[\"Turn CPB into a musical instrument\"]",".staticTexts[\"Turn CPB into a musical instrument\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("07_ToneGenerator")
        app.navigationBars["Tone Generator"].buttons["Modules"].tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Accelerometer"]/*[[".cells.staticTexts[\"Accelerometer\"]",".staticTexts[\"Accelerometer\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("08_Accelerometer")
        app.navigationBars["Accelerometer"].buttons["Modules"].tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["View current temperature readings"]/*[[".cells.staticTexts[\"View current temperature readings\"]",".staticTexts[\"View current temperature readings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("09_Temperature")
        app.navigationBars["Temperature"].buttons["Modules"].tap()
        tablesQuery.staticTexts["Puppets"].tap()
        snapshot("10_Puppets")

                
    }

    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
