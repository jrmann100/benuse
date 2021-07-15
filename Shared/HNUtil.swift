//
//  HNUtil.swift
//  Benuse
//
//  Created by Jordan Mann on 5/29/21.
//

import Foundation

enum HNPane: String {
    case story = "story"
    case comments = "comments"
}

enum HNAPIType: String, Codable {
    case job
    case story
    case comment
    case poll
    case pollopt
}

struct HNStory: Codable, Identifiable, Hashable {
    let id: Int // The story's unique id.
    let type: HNAPIType
    let by: String // The username of the story's author.
    let time: Int // Creation date of the story, in Unix Time.
    let text: String? // The story text. HTML.
    let kids: [Int]? // The ids of the story's comments, in ranked display order.
    let url: String? // The URL of the story.
    let score: Int // The story's score.
    let title: String // The title of the story. HTML.
    let descendants: Int? // The total comment count.
}

func getStory(storyID: Int, completion: @escaping (HNStory) -> ()) {
    let url = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(storyID).json")!
    URLSession.shared.dataTask(with: url) { data, _, _ in
        print("✅ \(storyID)")
        let story = try! JSONDecoder().decode(HNStory.self, from: data!)
        guard story.type ~= .story || story.type ~= .job else {
            print("Error: API item type is not a story or job!")
            return // will not complete... how to throw past?
        }
        DispatchQueue.main.async { completion(story) }
    }.resume()
}

func getItems(count: Int = 10, path: String = "topstories", completion: @escaping ([HNStory]) -> ()) {
    print("Hello. I am now fetching \(count) items.")
    let url = URL(string: "https://hacker-news.firebaseio.com/v0/\(path).json?orderBy=%22%24key%22&limitToFirst=\(count)")!
    URLSession.shared.dataTask(with: url) { data, _, _ in
        let storyIDs = (try! JSONDecoder().decode([Int].self, from: data!))[0 ... count - 1]
        var stories = [HNStory]()
        let initStories = DispatchGroup()
        print("📋 \(storyIDs)")
        storyIDs.forEach { storyID in
            initStories.enter()
            getStory(storyID: storyID) { story in
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
