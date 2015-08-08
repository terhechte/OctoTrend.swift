//
//  OctoTrend_swiftTests.swift
//  OctoTrend.swiftTests
//
//  Created by Benedikt Terhechte on 03/08/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import XCTest
@testable import OctoTrend

class OctoTrend_swiftTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let readyExpectation = expectationWithDescription("got data")
        trends(language: "swift", timeline: TrendingTimeline.Today) { (result) -> () in
            print(result)
            readyExpectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(8, handler: { (e) -> Void in
            XCTAssertNil(e, "Error")
        })
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
