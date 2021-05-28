//
//  ContentView.swift
//  Shared
//
//  Created by Jordan Mann on 5/23/21.
//

import SwiftUI
import Foundation
import Alamofire
import SwiftyJSON

struct HNItem: Hashable {
    
    let id: Int
    let by: String
    let title: String
    let score: Int
    
    init(json: JSON) {
        self.id = json["id"].intValue
        self.by = json["by"].stringValue
        self.title = json["title"].stringValue
        self.score = json["score"].intValue
    }
    
    init() {
        self.id = -1
        self.by = "Placeholder Author"
        self.title = "Placeholder Title"
        self.score = -1
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
                
                AF.request("https://hacker-news.firebaseio.com/v0/item/\(id).json").responseJSON {
                    switch $0.result {
                    case .failure(let error):
                        print("Error fetching item \(id):", error)
                    case .success(let value):
                        print("Fetched item \(id)")
                        items.append(HNItem(json: JSON(value)))
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                print("Finished all requests.")
                completion(items)
            }
        }
    }
}

func getItem(completion:@escaping (HNItem) -> ()) {
    AF.request("https://hacker-news.firebaseio.com/v0/item/\(1).json").responseJSON {
        switch $0.result {
        case .failure(let error):
            print("Error fetching item \(1):", error)
        case .success(let value):
            print("Fetched item \(1)")
            completion(HNItem(json: JSON(value)))
        }
    }
}

struct ContentView: View {
    @State var items = Array<HNItem>()
    @State var otherItem = HNItem()
    var body: some View {

        if items.count == 0 {
            Text("it's loading").font(.title)
        }
        List{
            ForEach(items, id: \.id ) {item in
                Link(item.title, destination: URL(string: "https://news.ycombinator.com/item?id=\(String(item.id))")!)
            }
        }
        .onAppear() {
            getItems(completion:  { (items) in
                self.items = items
            }, count: 2)
            getItem {self.otherItem = $0}
        }
    }
}
