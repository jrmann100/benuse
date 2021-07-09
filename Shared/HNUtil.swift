//
//  HNUtil.swift
//  Benuse
//
//  Created by Jordan Mann on 5/29/21.
//

import Foundation
import OpenGraph

import Foundation

enum HNAPIType: String, Codable {
    case job
    case story
    case comment
    case poll
    case pollopt
}

struct HNAPIStory: Codable, Identifiable, Hashable {
    let id: Int // The story's unique id.
    let type: HNAPIType
    let by: String // The username of the story's author.
    let time: Int // Creation date of the story, in Unix Time.
    let text: String? // The story text. HTML.
    let kids: [Int]? // The ids of the story's comments, in ranked display order.
    let url: String? // The URL of the story.
    let score: Int // The story's score.
    let title: String // The title of the story. HTML.
    let descendants: Int // The total comment count.
}

struct HNStory: Hashable {
    static func == (lhs: HNStory, rhs: HNStory) -> Bool {
        return lhs.id == rhs.id
    }

    let _item: HNAPIStory
    var id: Int { _item.id }
    var score: Int { _item.score }
    var title: String { _item.title }
    var url: URL? { _item.url != nil ? URL(string: _item.url!)! : nil }
    let site: String
    let image: URL?
}

func getStory(storyID: Int, completion: @escaping (HNAPIStory) -> ()) {
    let url = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(storyID).json")!
    URLSession.shared.dataTask(with: url) { data, _, _ in
        print("now I got the story \(storyID)")
        let story = try! JSONDecoder().decode(HNAPIStory.self, from: data!)
        guard story.type ~= .story else {
            print("Error: API item type is not a string!")
            return // will not complete... how to throw past?
        }
        DispatchQueue.main.async { completion(story) }
    }.resume()
}

func createStory(storyID: Int, completion: @escaping (HNStory) -> ()) {
    var image: URL?
    var site = "Hacker News"
    getStory(storyID: storyID) { apiStory in
        if apiStory.url != nil {
            OpenGraph.fetch(url: URL(string: apiStory.url!)!) { res in
                guard case let .success(og) = res else { return }
                if og[.image] != nil {
                    image = URL(string: og[.image]!)!
                }
                if og[.siteName] != nil {
                    site = og[.siteName]!
                } else if apiStory.url != nil {
                    site = URL(string: apiStory.url!)!.host!
                }
                DispatchQueue.main.async { completion(HNStory(_item: apiStory, site: site, image: image)) }
            }
        } else {
            DispatchQueue.main.async { completion(HNStory(_item: apiStory, site: site, image: image)) }
        }
    }
}

func getItems(completion: @escaping ([HNStory]) -> (), count: Int = 10) {
    let url = URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json")!
    URLSession.shared.dataTask(with: url) { data, _, _ in
        let storyIDs = (try! JSONDecoder().decode([Int].self, from: data!))[0 ... count - 1]
        var stories = [HNStory]()
        let initStories = DispatchGroup()

        storyIDs.forEach { storyID in
            initStories.enter()
            createStory(storyID: storyID) { story in
                stories.append(story)
                initStories.leave()
            }
        }

        initStories.notify(queue: .main) {
            print("Collected stories.")
            DispatchQueue.main.async { completion(stories) }
        }
    }.resume()
}
