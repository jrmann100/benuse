import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        var items = Array<HNItem>()
        for _ in 1...familyCount(family: context.family) {
            items.append(HNItem())
        }
        return SimpleEntry(date: Date(), items: items)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        var items = Array<HNItem>()
        for _ in 1...familyCount(family: context.family) {
            items.append(HNItem())
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
                    completion(timeline)},
                 count: familyCount(family: context.family))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let items: Array<HNItem>
}

struct HNItemView : View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        // Todo: in .systemLarge, load top articles and
        // Todo: test "show/etc HN" links
        if (widgetFamily == .systemSmall) {
            ZStack {
                Color(UIColor.systemGray5).edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading){
                    HStack {
                    Image(systemName: "arrow.up")
                    Text(String(entry.items[0].score))
                    }.foregroundColor(.gray)
                    Spacer()
                    Text(entry.items[0].title)
                }.padding()
            }
            .widgetURL(URL(string: urlForItem(id: entry.items[0].id))!)
        } else {
            ZStack {
                // Todo: header with title
                Color(UIColor.systemGray5).edgesIgnoringSafeArea(.all)
                VStack {
                    ForEach(entry.items, id: \.id ) {item in
                        // Todo: domain name
                        HStack {
                            Link(destination: URL(string: item.url ?? urlForItem(id: item.id))!) {
                                HStack {
                                    Group {
                                        Image(systemName: "arrow.up")
                                        Text(String(item.score))
                                    }.foregroundColor(.gray)
                                    Text(item.title).frame(maxWidth: .infinity)
                                }
                            }.onTapGesture(perform: {
                                // Todo: gray out visited links (could shuffle, but might want comments)
                            })
                            Link(destination: URL(string: urlForItem(id: item.id))!) {
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: 30))
                            }
                        }.padding()
                    }
                }
            }
        }
    }
}

@main
struct Benuse: Widget {
    let kind: String = "Benuse"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HNItemView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}
