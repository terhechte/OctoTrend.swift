# OctoTrend.swift

## A Github Trending Parser written in Swift

### Status: Usable but buggy

This is a simple Swift Micro Framework that parses Github trends into a usable Swift structure.

Usage:

``` Swift
// Get the language trends for the Swift language for today.

trends(language: "swift", timeline: TrendingTimeline.Today) { (result) -> () in
    if let result = result.value {
        for repo in result {
            print("\(repo.name): \(repo.url)")
        }
    }
}
```

More details will follow.
