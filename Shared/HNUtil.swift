//
//  HNUtil.swift
//  Benuse
//
//  Created by Jordan Mann on 5/29/21.
//

import Foundation
import Alamofire
import SwiftyJSON

struct HNItem: Hashable {
    
    let id: Int
    let by: String
    let title: String
    let score: Int
    let url: String?
    
    init(json: JSON) {
        self.id = json["id"].intValue
        self.by = json["by"].stringValue
        self.title = json["title"].stringValue
        self.score = json["score"].intValue
        self.url = json["url"].stringValue
        
    }
    
    init() {
        self.id = 0
        self.by = "jrmann100"
        self.title = "Hacker News Article"
        self.score = 1
        self.url = nil
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
            completion(HNItem(json: JSON(value)))
        }
    }
}
