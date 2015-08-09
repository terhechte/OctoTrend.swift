//
//  OctoTrend.swift
//  OctoTrend.swift
//
//  Created by Benedikt Terhechte on 03/08/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation
import Kanna
import Result

let kGithubTrendsURLTemplate = "https://github.com/trending?l=%@&since=%@"
let kGithubTrendsMetaSplit = "•"

struct User {
    let name: String
    let imageURL: NSURL
    let url: NSURL
}

struct Repository {
    let url: NSURL
    let name: String
    let developers: [User]
    let language: String
    let stars: Int
    let text: String
}

enum TrendingTimeline : String {
    case Today = "daily"
    case Week = "weekly"
    case Month = "monthly"
}

enum ParseError : ErrorType {
    case URLError
    case NetworkError(message: String)
    case HTMLParseError
    case HTMLSelectorError(selector: String)
    case StarError(message: String)
    
    func errorString() -> String {
        switch self {
        case .URLError:
            return "URLError"
        case .NetworkError(let e):
            return "NetworkError: \(e)"
        case .HTMLParseError:
            return "HTMLParseError"
        case .HTMLSelectorError(let s):
            return "HTMLSelectorError: \(s)"
        case .StarError(let m):
            return "StarError: \(m)"
        }
    }
}

extension Array {
    func optionalItem(index: Int) -> Array.Generator.Element? {
        if index > self.count {
            return nil
        }
        return self[index]
    }
}

extension Optional {
    func map<U>(@noescape f: (T) throws -> U) rethrows -> U? {
        if let t = self {
            return try f(t)
        } else {
            return nil
        }
    }
}

private func parseTrendsHTML(html: NSData) -> Result<[Repository], ParseError> {
    
    guard let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding)
        else {return Result(error: ParseError.HTMLParseError)}
    
    // FIXME: Move things from here into separate functions to have a cleaner implementation
    var repos: [Repository] = []
    for repo in doc.css("li.repo-list-item") {
        
        // Fetch the various properties from the html
        // FIXME: Abstract this away
        guard let name = repo.css("h3.repo-list-name").text
        else {return Result(error: ParseError.HTMLSelectorError(selector: "h3.repo-list-name"))}
        
        guard let desc = repo.css("p.repo-list-description").text
        else {return Result(error: ParseError.HTMLSelectorError(selector: "p.repo-list-description"))}
        
        
        guard let meta = repo.css("p.repo-list-meta").text
        else {return Result(error: ParseError.HTMLSelectorError(selector: "p.repo-list-meta"))}
        
        // Fixme, also need to parse the language from here
        let stars: Int?
        do {
            stars = try meta.componentsSeparatedByString(kGithubTrendsMetaSplit)
                .optionalItem(1)
                .map { (s: String) throws -> Int? in
                    let range = try NSRegularExpression(pattern: "([0-9]+)", options: [])
                        .rangeOfFirstMatchInString(s, options: [], range: NSMakeRange(0, s.characters.count))
                    return Int((s as NSString).substringWithRange(range))
                }
                .flatMap({$0})
        } catch let e {
            return Result(error: ParseError.StarError(message: "\(e)"))
        }
        
        guard let starNumber = stars else {
            return Result(error: ParseError.StarError(message: "Empty Stars Data"))
        }
        
        guard let urlElement = repo.at_css("h3.repo-list-name a")
            else {return Result(error: ParseError.HTMLSelectorError(selector: "h3.repo-list-name a"))}
        
        guard let urlPath = urlElement["href"]
            else {return Result(error: ParseError.HTMLSelectorError(selector: "h3.repo-list-name a[href]"))}
        
        guard let url = NSURL(string: urlPath)
            else {return Result(error: ParseError.HTMLSelectorError(selector: "h3.repo-list-name a[href]"))}
        
        //else {return Result(error: ParseError.HTMLSelectorError(selector: "h3.repo-list-name a"))}
        
//        var users: [User] = []
//        for user in repo.css("p.repo-list-meta a img") {
//            print(user)
//        }
        
        repos.append(Repository(url: url, name: name, developers: [], language: "", stars: starNumber, text: desc))
    }
    
    return Result(repos)
}

func trends(language language: String, timeline: TrendingTimeline,
    completion: (result: Result<[Repository], ParseError>) -> ()) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
        guard let url = NSURL(string: String(format: kGithubTrendsURLTemplate, language, timeline.rawValue))
            else { completion(result: Result(error: ParseError.URLError)); return}
        let request = NSURLRequest(URL: url)
        
        do {
            let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: nil)
            
            let result = parseTrendsHTML(data)
            completion(result: result)
        } catch let e {
            completion(result: Result(error: ParseError.NetworkError(message: "\(e)")))
        }
    }
}