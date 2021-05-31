import WidgetKit
import SwiftUI

// https://www.themobileentity.com/home/how-to-fetch-image-from-url-with-swiftui-the-easy-way
extension Image {
    
    func data(url:URL) -> Self {
        
        if let data = try? Data(contentsOf: url) {
            
            return Image(uiImage: UIImage(data: data)!)
                
                .resizable()
            
        }
        
        return self
            
            .resizable()
        
    }
    
}

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

struct SmallItemView: View {
    let item: HNItem
    let colorScheme: ColorScheme
    var body: some View { ZStack {
        Color(UIColor.systemGray5).edgesIgnoringSafeArea(.all)
        if item.image != nil {
            Image(systemName: "newspaper").data(url: item.image!).scaledToFill().frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .center).clipped().opacity(0.4)
        }
        VStack(alignment: .leading){
            HStack {
                Image(systemName: "arrow.up")
                Text(String(item.score))
            }.opacity(0.8)
            Spacer()
            Text(item.title)
            Spacer()
            Text(item.site).font(.system(size: 12, weight: .semibold))
        }.padding()
    }
    .widgetURL(URL(string: urlForItem(id: item.id))!)
    }
}

struct ItemView: View {
    let item: HNItem
    let colorScheme: ColorScheme
    var body: some View {
        ZStack {
            if item.image != nil {
                Image(systemName: "newspaper").data(url: item.image!).scaledToFill().frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .center).clipped().opacity(0.5)
            }
            HStack {
                Link(destination: item.url) {
                    VStack(alignment: .leading) {
                        Text(item.site).font(.system(size: 13, weight: .semibold))
                        Spacer().frame(maxHeight: 5)
                        HStack {
                            Group {
                                Image(systemName: "arrow.up")
                                Text(String(item.score))
                            }.opacity(0.8).font(.system(size: 13))
                            Text(item.title).frame(maxWidth: .infinity).fixedSize(horizontal: false, vertical: true).lineLimit(3).font(.system(size: 14, weight: .bold)) // does lineLimit matter?
                        }
                    }.onTapGesture(perform: {
                        // Todo: gray out visited links (could shuffle, but might want comments)
                    })
                    Link(destination: URL(string: urlForItem(id: item.id))!) {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 30))
                    }
                }
            }.frame(maxHeight: 35).padding()
        }
    }
}

struct ItemsView : View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        // Todo: in .systemLarge, load top articles and
        // Todo: test "show/etc HN" links
        // Todo: translucency is not currently possible
        //       (it worked in Today widgets, so we'll see)
        if widgetFamily == .systemSmall {
            SmallItemView(item: entry.items[0], colorScheme: colorScheme)
        } else {
            ZStack {
                // Todo: header with title
                Color(UIColor.systemGray5).edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading) {
                    if (widgetFamily == .systemLarge) {
                        Text("Hacker News").foregroundColor(.orange).font(.system(size: 17, weight: .heavy)).padding(EdgeInsets(top: 15, leading: 15, bottom: 5, trailing: 10))
                    }
                    ForEach(entry.items, id: \.self) {item in
                        // Todo: domain name
                        ItemView(item: item, colorScheme: colorScheme)
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
