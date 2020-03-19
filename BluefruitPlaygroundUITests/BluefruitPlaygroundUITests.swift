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
    
    func testSnapsthotsClue() {
        
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        
        sleep(1)        // Wait for the intro animation
        snapshot("01a_Welcome")
        elementsQuery.buttons["LET'S GET STARTED..."].tap()
        
        snapshot("01b_PowerUp")
        elementsQuery.buttons["NEXT"].tap()
        
        snapshot("01c_Discover")
        elementsQuery.buttons["FIND DEVICES"].tap()
        
        let tablesQuery = app.tables
        
        // CLUE
        snapshot("01d_Scanner")
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["CLUE"]/*[[".cells.staticTexts[\"CLUE\"]",".staticTexts[\"CLUE\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("02_CLUE_Modules")
        
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["NeoPixels"]/*[[".cells.staticTexts[\"NeoPixels\"]",".staticTexts[\"NeoPixels\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(1)
        snapshot("03_CLUE_Neopixels_LightSequence")
        elementsQuery.staticTexts["Light Sequence"].swipeLeft()
        snapshot("04a_CLUE_Neopixels_ColorPalette")
        elementsQuery.staticTexts["Color Palette"].swipeLeft()
        snapshot("04b_CLUE_Neopixels_ColorWheel")
        app.navigationBars["NeoPixels"].buttons["Modules"].tap()

        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Light Sensor"]/*[[".cells.staticTexts[\"Light Sensor\"]",".staticTexts[\"Light Sensor\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("05a_CLUE_LightSensor")
        elementsQuery.staticTexts["Luminance Reading"].swipeLeft()
        snapshot("05b_CLUE_LightSensor_Chart")
        app.navigationBars["Light Sensor"].buttons["Modules"].tap()

        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Button Status"]/*[[".cells.staticTexts[\"Button Status\"]",".staticTexts[\"Button Status\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("06_CLUE_ButtonStatus")
        app.navigationBars["Button Status"].buttons["Modules"].tap()
        
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Tone Generator"]/*[[".cells.staticTexts[\"Tone Generator\"]",".staticTexts[\"Tone Generator\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("07_CLUE_ToneGenerator")
        app.navigationBars["Tone Generator"].buttons["Modules"].tap()
        
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Orientation"]/*[[".cells.staticTexts[\"Orientation\"]",".staticTexts[\"Orientation\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("08_CLUE_Orientation")
        app.navigationBars["Orientation"].buttons["Modules"].tap()
        
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Temperature"]/*[[".cells.staticTexts[\"Temperature\"]",".staticTexts[\"Temperature\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("09_CLUE_Temperature")
        app.navigationBars["Temperature"].buttons["Modules"].tap()

        /*
        let buttonStatusStaticText = tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Button Status"]/*[[".cells.staticTexts[\"Button Status\"]",".staticTexts[\"Button Status\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        buttonStatusStaticText.swipeUp()        // Swipe up to see more modules
        */
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Humidity"]/*[[".cells.staticTexts[\"Humidity\"]",".staticTexts[\"Humidity\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("10_CLUE_Humidity")
        app.navigationBars["Humidity"].buttons["Modules"].tap()
        
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Pressure"]/*[[".cells.staticTexts[\"Pressure\"]",".staticTexts[\"Pressure\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("11_CLUE_Pressure")
        app.navigationBars["Pressure"].buttons["Modules"].tap()
        
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Puppets"]/*[[".cells.staticTexts[\"Puppets\"]",".staticTexts[\"Puppets\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        sleep(2)        // Wait for the puppet animation
        snapshot("12_Puppets")
        app.navigationBars["Puppets"].buttons["Modules"].tap()
        
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Disconnect"]/*[[".cells.staticTexts[\"Disconnect\"]",".staticTexts[\"Disconnect\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.alerts.scrollViews.otherElements.buttons["OK"].tap()
        
        // CPB
        XCUIApplication().tables/*@START_MENU_TOKEN@*/.staticTexts["CPB"]/*[[".cells.staticTexts[\"CPB\"]",".staticTexts[\"CPB\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["NeoPixels"]/*[[".cells.staticTexts[\"NeoPixels\"]",".staticTexts[\"NeoPixels\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("03_CPB_Neopixels_LightSequence")
        elementsQuery.staticTexts["Light Sequence"].swipeLeft()
        snapshot("04a_CPB_Neopixels_ColorPalette")
        elementsQuery.staticTexts["Color Palette"].swipeLeft()
        snapshot("04b_CPB_Neopixels_ColorWheel")
        app.navigationBars["NeoPixels"].buttons["Modules"].tap()
        
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Light Sensor"]/*[[".cells.staticTexts[\"Light Sensor\"]",".staticTexts[\"Light Sensor\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("05a_CPB_LightSensor")
        elementsQuery.staticTexts["Luminance Reading"].swipeLeft()
        snapshot("05b_CPB_LightSensor_Chart")
        app.navigationBars["Light Sensor"].buttons["Modules"].tap()
        
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Button Status"]/*[[".cells.staticTexts[\"Button Status\"]",".staticTexts[\"Button Status\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("06_CPB_ButtonStatus")
        app.navigationBars["Button Status"].buttons["Modules"].tap()
  
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Accelerometer"]/*[[".cells.staticTexts[\"Accelerometer\"]",".staticTexts[\"Accelerometer\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        snapshot("08_CPB_Accelerometer")
        app.navigationBars["Accelerometer"].buttons["Modules"].tap()
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
