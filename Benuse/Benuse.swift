import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        var items = Array<HNItem>()
        items.append(HNItem())
        items.append(HNItem())
        return SimpleEntry(date: Date(), items: items)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        var items = Array<HNItem>()
        items.append(HNItem())
        items.append(HNItem())
        completion(SimpleEntry(date: Date(), items: items))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        
        getItems(completion: {
                    let entry = SimpleEntry(date: currentDate, items: $0)
                    let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                    completion(timeline)},
                 count: 2)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let items: Array<HNItem>
}

struct HNItemView : View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            VStack{
                ForEach(entry.items, id: \.id ) {item in
                    HStack {
                        Link(destination: URL(string: item.url ?? "https://jrmann.com")!) {
                            HStack {
                                Group {
                                    Image(systemName: "arrow.up")
                                    Text(String(item.score))
                                }.foregroundColor(.gray)
                                Text(item.title).frame(maxWidth: .infinity)
                            }
                        }.onTapGesture(perform: {
                            //                            .foregroundColor(.gray)
                        })
                        Link(destination: URL(string: "https://news.ycombinator.com/item?id=\(String(item.id))")!) {
                            Image(systemName: "text.bubble.fill")
                                .font(.system(size: 30))
                        }
                    }.padding()
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
