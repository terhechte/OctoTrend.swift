//
//  OctoTrend.swift
//  OctoTrend.swift
//
//  Created by Benedikt Terhechte on 03/08/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation
import Kanna

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