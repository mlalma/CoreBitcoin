//
//  BTCPriceSourceTests.swift
//  CoreBitcoin
//
//  Created by Robert S Mozayeni on 4/20/15.
//  Copyright (c) 2015 Oleg Andreev. All rights reserved.
//

import Cocoa
import XCTest

class BTCPriceSourceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCoindesk() {
        let coindesk = BTCPriceSourceCoindesk()
        XCTAssert(coindesk.name.lowercased().contains("coindesk"), "should be named coindesk")
        let codes = coindesk.currencyCodes as! [String]
        XCTAssert(codes.contains("USD"), "should contain USD")
        XCTAssert(codes.contains("EUR"), "should contain EUR")
        
        validatePrice(result: try? coindesk.loadPrice(forCurrency: "USD"), min: 100, max: 100000)
        validatePrice(result: try? coindesk.loadPrice(forCurrency: "EUR"), min: 100, max: 100000)
    }
    
    func testWinkdex() {
        let winkdex = BTCPriceSourceWinkdex()
        XCTAssert(winkdex.name.lowercased().contains("wink"), "should be named properly")
        
        let codes = winkdex.currencyCodes as! [String]
        
        XCTAssert(codes.contains("USD"), "should contain USD")
        
        // Winkdex doesn't have API anymore
        //validatePrice(result: try? winkdex.loadPrice(forCurrency: "USD"), min: 100, max: 100000)
    }
    
    func testCoinbase() {
        let coinbase = BTCPriceSourceCoinbase()
        XCTAssert(coinbase.name.lowercased().contains("coinbase"), "should be named properly")
        let codes = coinbase.currencyCodes as! [String]
        XCTAssert(codes.contains("USD"), "should contain USD")
    }
    
    func testPaymium() {
        let paymium = BTCPriceSourcePaymium()
        XCTAssert(paymium.name.lowercased().contains("paymium"), "should be named properly")
        
        let codes = paymium.currencyCodes as! [String]
        
        XCTAssert(codes.contains("EUR"), "should contain EUR")
        validatePrice(result: try? paymium.loadPrice(forCurrency: "EUR"), min: 100, max: 100000)
        
    }
    
    
    func validatePrice(result: BTCPriceSourceResult?, min: Double, max: Double) {
        
        XCTAssert(result != nil, "result should not be nil")
        
        let number: NSDecimalNumber? = result?.averageRate
        //        println("price = \(number) \(result.currencyCode)")
        
        if result == nil || number == nil {
            return
        }
        
        XCTAssert(result!.date != nil , "date should not be nil")
        XCTAssert(number != nil, "averageRate should not be nil")
        XCTAssert(number!.doubleValue >= min, "Must be over minimum value")
        XCTAssert(number!.doubleValue <= max, "Must be under max value")
    }
    
    
}
