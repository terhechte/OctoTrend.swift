//
//  OctoTrend.swift
//  OctoTrend.swift
//
//  Created by Benedikt Terhechte on 03/08/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation
import Kanna

let kGithubTrendsURLTemplate = "https://github.com/trending?l=%@&since=%@"

struct User {
    let name: String
    let imageURL: NSURL
    let url: NSURL
}

enum Stars {
    case Day(count: Int)
    case Week(count: Int)
    case Month(count: Int)
}

struct Repository {
    let url: NSURL
    let name: String
    let developers: [User]
    let language: String
    let stars: Stars
    let text: String
    let starred: Bool
}

enum TrendingTimeline : String {
    case Today = "daily"
    case Week = "weekly"
    case Month = "monthly"
}
func trends(language language: String, timeline: TrendingTimeline,
    completion: (result: [Repository]?) -> ()) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
        guard let url = NSURL(string: String(format: kGithubTrendsURLTemplate, language, timeline.rawValue))
            else { completion(result: nil); return }
        let request = NSURLRequest(URL: url)
        
        do {
            let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: nil)
            
            completion(result: parseTrendsHTML(data))
        } catch _ {
            completion(result: nil)
        }
    }
}