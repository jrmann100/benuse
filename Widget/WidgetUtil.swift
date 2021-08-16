//
//  WidgetUtil.swift
//  Benuse (iOS)
//
//  Created by Jordan Mann on 7/15/21.
//

import Foundation
import OpenGraph
import SwiftUI

func deepLink(story: HNStory, show pane: HNPane) -> URL {
    var components = URLComponents()
    components.scheme = "benuse"
    components.host = "story"
    components.path = "/"
    components.queryItems = [URLQueryItem]()
    components.queryItems!.append(URLQueryItem(name: "id", value: String(story.id)))
    if story.url != nil { components.queryItems!.append(URLQueryItem(name: "url", value: story.url!.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))) }
    components.queryItems!.append(URLQueryItem(name: "pane", value: pane.rawValue))
    if story.type ~= .job { components.queryItems!.append(URLQueryItem(name: "hide", value: HNPane.comments.rawValue)) }
    return components.url!
}

// Loading via OpenGraph is a bit of a struggle because there is no
// way to load widget content asynchronously and the library I'm using
// doesn't support timeouts.
func loadOG(story: HNStory, completion: @escaping (String?, Image?) -> Void) {
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) { // to demonstrate the above issue

    var site: String?, image: Image?

    guard story.url != nil else {
        site = "Hacker News"
        return completion(site, image)
    }

    site = URL(string: story.url!)!.host!

    OpenGraph.fetch(url: URL(string: story.url!)!) { res in
        guard case let .success(og) = res else { return completion(site, image) }
        print("📸 \(story.id)")
        site = og[.siteName] ?? site
        guard og[.image] != nil else { return completion(site, image) }
        guard let imageURL = URL(string: og[.image]!) else { return completion(site, image) }
        guard let data = (try? Data(contentsOf: imageURL)) else { return completion(site, image) }
        guard let uiImage = UIImage(data: data) else { return completion(site, image) }
        image = Image(uiImage: uiImage).resizable()
        return completion(site, image)
    }
//        }
}

struct HNFeed {
    let title: String
    let apiPath: String
    let path: String
    let color: Color
}

func getHNFeed(_ feed: Feed) -> HNFeed {
    switch feed {
    case .unknown: return getHNFeed(Feed.top)
    case .ask: return HNFeed(title: "Ask HN", apiPath: "askstories", path: "ask", color: .red)
    case .best: return HNFeed(title: "Best Stories", apiPath: "beststories", path: "best", color: .yellow)
    case .job: return HNFeed(title: "YC Jobs", apiPath: "jobstories", path: "jobs", color: .green)
    case .new: return HNFeed(title: "New Stories", apiPath: "newstories", path: "newest", color: .blue)
    case .show: return HNFeed(title: "Show HN", apiPath: "showstories", path: "show", color: .purple)
    case .top: return HNFeed(title: "Hacker News", apiPath: "topstories", path: "", color: .orange)
    }
}
