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
    
    func testGotData() {
        // Test whether receiving and parsing data from the github server works. 
        // performs an actual http request
        let readyExpectation = expectationWithDescription("got data")
        trends(language: "swift", timeline: TrendingTimeline.Today) { (result) -> () in
            switch result {
            case .Failure(let e):
                XCTAssert(false, e.errorString())
            case .Success(let s):
                //print("result: \(s)")
                readyExpectation.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(20, handler: { (e) -> Void in
            XCTAssertNil(e, "Error")
        })
    }
    
    func testParseData() {
        // uses the trending.html to make sure that the data is parsed correctly
        let dataPath = NSBundle(forClass: self.classForCoder).pathForResource("trending", ofType: "html")
        if let dataPath = dataPath,
            data = NSData(contentsOfFile: dataPath) {
                let result = OctoTrend.parseTrendsHTML(data)
                
                switch result {
                case .Failure(let e):
                    XCTAssert(false, e.errorString())
                case .Success(let s):
                    guard let firstRepo = s.first else { XCTAssert(false, "No Items"); return }
                    XCTAssertEqual(firstRepo.name, "Palleas/NaughtyKeyboard", "Did not parse name correctly")
                    XCTAssertEqual(firstRepo.developers.count, 2, "Did not parse developers correctly")
                    guard let firstDeveloper = firstRepo.developers.first else { XCTAssert(false, "No First Developer"); return }
                    XCTAssertEqual(firstDeveloper.name, "Palleas", "Did not parse developers correctly")
                    XCTAssertEqual(firstRepo.stars, 173, "Did not parse stars correctly")
                    XCTAssertEqual(firstRepo.text, "The Big List of Naughty Strings is a list of strings which have a high probability of causing issues when used as user-input data. This is a keyboard to help you test your app from your iOS device.", "Did not parse text correctly")
                    guard let lastRepo = s.last else { XCTAssert(false, "No Items"); return }
                    XCTAssertEqual(lastRepo.url.absoluteString, "https://github.com/remaerd/Keys", "Did not parse url correctly")
                    // The last repo has no "builders" listed, so it should correctly return the empty array here...
                    XCTAssertEqual(lastRepo.developers.count, 0, "Did not parse developer count correctly")
                    
                }
        } else {
            XCTAssert(false, "Could not find html data")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
