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

public struct User {
    let name: String
    let imageURL: NSURL
    let url: NSURL
}

public struct Repository {
    let url: NSURL
    let name: String
    let developers: [User]
    let language: String
    let stars: Int
    let text: String
}

public enum TrendingTimeline : String {
    case Today = "daily"
    case Week = "weekly"
    case Month = "monthly"
}

public enum ParseError : ErrorType {
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

private extension Array {
    func optionalItem(index: Int) -> Array.Generator.Element? {
        if index > self.count {
            return nil
        }
        return self[index]
    }
}

private extension Optional {
    func map<U>(@noescape f: (T) throws -> U) rethrows -> U? {
        if let t = self {
            return try f(t)
        } else {
            return nil
        }
    }
}

private extension String {
    func trim() -> String {
        return (self as NSString).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    func removeWhitespace() -> String {
        // not only trim but remove every whitespace char from inside the string too
        return String(self.characters.filter({ (e: Character) -> Bool in
            if e == Character(" ") || e == Character("\n") {
                return false
            } else {
                return true
            }
        }))
    }
}

func parseTrendsHTML(html: NSData) -> Result<[Repository], ParseError> {
    
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
        let components = meta.componentsSeparatedByString(kGithubTrendsMetaSplit)
        let stars: Int?
        do {
            stars = try components.optionalItem(1)
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
        
        guard let language = components.optionalItem(0)
            else {return Result(error: ParseError.HTMLSelectorError(selector: "h3.repo-list-meta.language"))}
        
        guard let urlElement = repo.at_css("h3.repo-list-name a")
            else {return Result(error: ParseError.HTMLSelectorError(selector: "h3.repo-list-name a"))}
        
        guard let urlPath = urlElement["href"]
            else {return Result(error: ParseError.HTMLSelectorError(selector: "h3.repo-list-name a[href]"))}
        
        guard let url = NSURL(string: urlPath)
            else {return Result(error: ParseError.HTMLSelectorError(selector: "h3.repo-list-name a[href]"))}
        
        var users: [User] = []
        for user in repo.css("p.repo-list-meta a img") {
            if let name = user["title"],
                image = user["src"],
                imageURL = NSURL(string: image),
                url = NSURL(string: "http://github.com/\(name)") {
                    users.append(User(name: name, imageURL: imageURL, url: url))
            }
        }
        
        repos.append(Repository(url: url, name: name.removeWhitespace(), developers: users, language: language.trim(), stars: starNumber, text: desc.trim()))
    }
    
    return Result(repos)
}

public func trends(language language: String, timeline: TrendingTimeline,
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