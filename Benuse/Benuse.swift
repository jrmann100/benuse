import SwiftUI
import WidgetKit

// https://www.themobileentity.com/home/how-to-fetch-image-from-url-with-swiftui-the-easy-way
extension Image {
    func data(url: URL) -> Self {
        if let data = try? Data(contentsOf: url) {
            return Image(uiImage: UIImage(data: data)!)
                .resizable()
        }
        return resizable()
    }
}

struct Provider: TimelineProvider {
    let dummyStory = HNStory(_item: HNAPIStory(id: 0, type: HNAPIType.story, by: "jrmann100", time: 0, text: nil, kids: [], url: "https://jrmann.com", score: 299, title: "Show HN: Benuse - iOS HN Widget/Reader", descendants: 0), site: "Jordan's Projects", image: URL(string: "https://images.saymedia-content.com/.image/t_share/MTc2Mjg0OTI2Mzc3ODYyMzM0/reading-newspaper-as-a-habit.jpg")!)

    func placeholder(in context: Context) -> SimpleEntry {
        var items = [HNStory]()
        for _ in 1...familyCount(family: context.family) {
            items.append(dummyStory)
        }
        return SimpleEntry(date: Date(), items: items)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        var items = [HNStory]()
        for _ in 1...familyCount(family: context.family) {
            items.append(dummyStory)
        }
        completion(SimpleEntry(date: Date(), items: items))
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

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        getItems(completion: {
                     let entry = SimpleEntry(date: currentDate, items: $0)
                     let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                     completion(timeline)

                 },
                 count: familyCount(family: context.family))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let items: [HNStory]
}

struct SmallItemView: View {
    let story: HNStory
    let colorScheme: ColorScheme
    var body: some View { ZStack {
        Color(UIColor.systemGray5).edgesIgnoringSafeArea(.all)
        if story.image != nil {
            Image(systemName: "newspaper").data(url: story.image!).scaledToFill().frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .center).clipped().opacity(0.4)
        }
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "arrow.up")
                Text(String(story.score))
            }.opacity(0.8)
            Spacer()
            Text(story.title)
            Spacer()
            Text(story.site).font(.system(size: 12, weight: .semibold))
        }.padding()
    }
    .widgetURL(URL(string: "https://hacker-news.firebaseio.com/v0/item/\(story.id)")!)
    }
}

struct ItemView: View {
    let story: HNStory
    let colorScheme: ColorScheme
    func deepLink(showItem: Bool) -> URL {
        return URL(string: "benuse://\(story.id)/\(showItem ? "item" : "comments")\(story.url != nil ? "?url=" + story.url!.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! : "")")!
    }

    var body: some View {
        ZStack {
            if story.image != nil {
                Image(systemName: "newspaper").data(url: story.image!).scaledToFill().frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .center).clipped().opacity(0.5)
            }
            HStack {
                Link(destination: deepLink(showItem: story.url != nil), label: {
                    VStack(alignment: .leading) {
                        Text(story.site).font(.system(size: 13, weight: .semibold))
                        Spacer().frame(maxHeight: 5)
                        HStack {
                            Group {
                                Image(systemName: "arrow.up")
                                Text(String(story.score))
                            }.opacity(0.8).font(.system(size: 13))
                            Text(story.title).frame(maxWidth: .infinity).fixedSize(horizontal: false, vertical: true).lineLimit(2).font(.system(size: 14, weight: .bold)) // TODO: see how we feel about LineLimit and showing whole titles. Compact font would be nice.
                        }
                    }.onTapGesture(perform: {
                        // TODO: gray out visited links (could shuffle, but might want comments)
                    })
                    Link(destination: deepLink(showItem: false)) {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 30))
                    }
                })
            }.frame(maxHeight: 35).padding()
        }
    }
}

struct ItemsView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        // TODO: in .systemLarge, load top articles and
        // TODO: test "show/etc HN" links
        // TODO: translucency is not currently possible
        //       (it worked in Today widgets, so we'll see)
        if widgetFamily == .systemSmall {
            SmallItemView(story: entry.items[0], colorScheme: colorScheme)
        } else {
            ZStack {
                // TODO: header with title
                Color(UIColor.systemGray5).edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading) {
                    if widgetFamily == .systemLarge {
                        Link(destination: URL(string: "benuse://home")!) { Text("Hacker News").foregroundColor(.orange).font(.system(size: 17, weight: .heavy)).padding(EdgeInsets(top: 15, leading: 15, bottom: 5, trailing: 10)) }
                    }
                    ForEach(entry.items, id: \.self) { item in
                        ItemView(story: item, colorScheme: colorScheme)
                    }
                }
            }
        }
    }
}

@main
struct Benuse: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.benuse.hacker-news", provider: Provider()) { entry in
            ItemsView(entry: entry)
        }
        .configurationDisplayName("Hacker News")
        .description("Displays today's best articles.")
    }
}
