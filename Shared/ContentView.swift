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
    
    init?(json: JSON) {
        guard
            let id = json["id"].int,
            let by = json["by"].string,
            let title = json["title"].string,
            let score = json["score"].int
        else { return nil }
        self.id = id
        self.by = by
        self.title = title
        self.score = score
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
            let best = Array(JSON(value).arrayValue.map{$0.intValue}[0...count])
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
                        items.append(HNItem(json: JSON(value))!)
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

struct ContentView: View {
    @State var items = Array<HNItem>()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if items.count == 0 {
                    Text("it's loading").font(.title)
                } else {
                    ForEach(items, id: \.self ) {item in
                        Text(item.title)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
            }
            .onAppear() {
                getItems { (items) in
                    self.items = items
                }
            }
        }
    }
}
