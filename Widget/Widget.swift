import Intents
import SwiftUI
import WidgetKit

struct Provider: IntentTimelineProvider {
    var dummyItem: (HNStory, String?, Image?) {
        var dummyImage: Image? {
            // todo: change dummy image to benuse icon
            guard let dummyImageURL = URL(string: "https://images.saymedia-content.com/.image/t_share/MTc2Mjg0OTI2Mzc3ODYyMzM0/reading-newspaper-as-a-habit.jpg") else { return nil }
            guard let dummyImageData = (try? Data(contentsOf: dummyImageURL)) else { return nil }
            guard let dummyUIImage = UIImage(data: dummyImageData) else { return nil }
            let dummyImage = Image(uiImage: dummyUIImage).resizable()
            return dummyImage
        }

        return (HNStory(id: 0, type: HNAPIType.story, by: "jrmann100", time: 0, text: nil, kids: [], url: "https://jrmann.com", score: 299, title: "Show HN: Benuse - iOS HN Widget/Reader", descendants: 0), "Be Nuse", dummyImage)
    }

    func placeholder(in context: Context) -> StoriesEntry {
        var items = [(HNStory, String?, Image?)]()
        for _ in 1...familyCount(family: context.family) {
            items.append(dummyItem)
        }
        return StoriesEntry(feed: getHNFeed(Feed.unknown), date: Date(), configuration: ConfigurationIntent(), items: items)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (StoriesEntry) -> Void) {
        var items = [(HNStory, String?, Image?)]()
        for _ in 1...familyCount(family: context.family) {
            items.append(dummyItem)
        }
        completion(StoriesEntry(feed: getHNFeed(Feed.unknown), date: Date(), configuration: configuration, items: items))
    }

    func familyCount(family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall: return 1
        case .systemMedium: return 2
        case .systemLarge: return 4
        @unknown default:
            fatalError("Widget size not implemented.")
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<StoriesEntry>) -> Void) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let feed = getHNFeed(configuration.feed)
        getItems(count: familyCount(family: context.family), path: feed.apiPath) { stories in
            var items = [(HNStory, String?, Image?)]()
            let itemsReady = DispatchGroup()
            stories.forEach { story in
                itemsReady.enter()
                loadOG(story: story) { site, image in
                    items.append((story, site, image))
                    itemsReady.leave()
                }
            }
            itemsReady.notify(queue: .main) {
                let entry = StoriesEntry(feed: feed, date: currentDate, configuration: configuration, items: items)
                let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                completion(timeline)
            }
        }
    }
}

struct StoriesEntry: TimelineEntry {
    let feed: HNFeed
    let date: Date
    let configuration: ConfigurationIntent
    let items: [(HNStory, String?, Image?)]
}

@main
struct Benuse: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "com.benuse.hacker-news", intent: ConfigurationIntent.self, provider: Provider()) { entry in
            ItemsView(entry: entry)
        }
        .configurationDisplayName("Hacker News")
        .description("Displays recent articles. Edit the widget to select a feed.")
    }
}

struct Benuse_Previews: PreviewProvider {
    static let dummy = HNStory(id: 0, type: HNAPIType.story, by: "jrmann100", time: 0, text: nil, kids: [], url: "https://jrmann.com", score: 299, title: "Show HN - Benuse, a HN iOS Widget Reader", descendants: 0)
    static var previews: some View {
        BigItemView(story: dummy, site: "Jordan's Projects", image: Image(uiImage: UIImage(data: try! Data(contentsOf: URL(string: "https://images.saymedia-content.com/.image/t_share/MTc2Mjg0OTI2Mzc3ODYyMzM0/reading-newspaper-as-a-habit.jpg")!))!).resizable()).padding().previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
