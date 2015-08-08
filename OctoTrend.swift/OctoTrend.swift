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
let kGithubTrendsMetaSplit = "•"

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

private func parseTrendsHTML(html: NSData) -> [Repository]? {
    guard let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) else { return nil }
    
    // FIXME: Move things from here into separate functions to have a cleaner implementation
    var repos: [Repository] = []
    for repo in doc.css("li.repo-list-item") {
        if let name = repo.css("h3.repo-list-name").text,
            desc = repo.css("p.repo-list-description").text,
            meta = repo.css("p.repo-list-meta").text {
                let metaComponents = meta.componentsSeparatedByString(kGithubTrendsMetaSplit)
                if metaComponents.count != 3 { continue }
                do {
                    // This is impressively awful
                    let starString = metaComponents[1]
                    let exp = try NSRegularExpression(pattern: "[0-9]*", options: [])
                    let matches = exp.matchesInString(starString, options: [], range: NSMakeRange(0, starString.characters.count))
                    guard let match = matches.first else { continue }
                    let range = match.range
                    let stars = (starString as NSString).substringWithRange(range)
                    guard let starNumber = Int(stars) else { continue }
                    
                    print("starnumber:", starNumber)
                    
                    var users: [User] = []
                    for user in repo.css("p.repo-list-meta a img") {
                        print(user)
                    }
                } catch _ {
                    continue
                }
                let stars = metaComponents[1]
                
                print("\(name) - \(desc)")
        }
    }
    
    return []
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