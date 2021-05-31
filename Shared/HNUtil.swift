//
//  HNUtil.swift
//  Benuse
//
//  Created by Jordan Mann on 5/29/21.
//

import Foundation
import Alamofire
import SwiftyJSON
import OpenGraph

struct HNItem: Hashable {
    
    let id: Int
    let by: String
    let title: String
    let score: Int
    let url: URL
    let site: String
    let image: URL?
    
    init(json: JSON, site: String? = nil, image: URL? = nil) {
        self.id = json["id"].intValue
        self.by = json["by"].stringValue
        self.title = json["title"].stringValue
        self.score = json["score"].intValue
        self.url = URL(string: json["url"].exists() ? json["url"].stringValue : urlForItem(id: id))!
        self.site = site ?? "Hacker News"
        self.image = image
    }
    
    init() {
        self.id = 0
        self.by = "jrmann100"
        self.title = "Benuse: iOS Widget Enhances Mobile HN Experience."
        self.score = 203
        self.url = URL(string: "https://jrmann.com")!
        self.site = "Jordan's Blog"
        self.image = URL(string: "https://images.saymedia-content.com/.image/t_share/MTc2Mjg0OTI2Mzc3ODYyMzM0/reading-newspaper-as-a-habit.jpg")!
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

func getItems(completion:@escaping (Array<HNItem>) -> (), count: Int = 10) {
    print("starting request")
    AF.request("https://hacker-news.firebaseio.com/v0/topstories.json").responseJSON { response in
        print("got response");
        
        switch response.result {
        case .failure(let error):
            print(error)
        case .success(let value):
            let best = Array(JSON(value).arrayValue.map{$0.intValue}[0...count - 1])
            let group = DispatchGroup()
            var items = Array<HNItem>()
            
            best.forEach { id in
                group.enter()
                getItem( completion: {item in
                    items.append(item)
                    group.leave()
                }, id: id)
            }
            
            group.notify(queue: .main) {
                print("Finished all requests.")
                completion(items)
            }
        }
    }
}

func getItem(completion:@escaping (HNItem) -> (), id: Int) {
    AF.request("https://hacker-news.firebaseio.com/v0/item/\(id).json").responseJSON {
        switch $0.result {
        case .failure(let error):
            print("Error fetching item \(id):", error)
        case .success(let value):
            let json = JSON(value)
            var site = "Hacker News"
            var image: URL? = nil
            if json["url"].exists() {
                OpenGraph.fetch(url: URL(string: json["url"].stringValue)!) { result in
                    switch result {
                    case .success(let og):
                        if og[.image] != nil {
                            image = URL(string: og[.image]!)!
                        }
                        if og[.siteName] != nil {
                            site = og[.siteName]!
                        } else if json["url"].exists() {
                            site = URL(string: json["url"].stringValue)!.host!
                        }
                        completion(HNItem(json: JSON(value), site: site, image: image))
                    case .failure(_):
                        completion(HNItem(json: JSON(value), site: URL(string: json["url"].stringValue)?.host))
                    }
                }
            } else {
                completion(HNItem(json: JSON(value)))
            }
        }
    }
}

func urlForItem(id: Int) -> String {
    "https://news.ycombinator.com/item?id=\(id)"
}
