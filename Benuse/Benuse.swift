import SwiftUI
import WidgetKit

func deepLink(story: HNStory, showItem: Bool) -> URL {
    return URL(string: "benuse://\(story.id)/\(showItem ? "item" : "comments")\(story.url != nil ? "?url=" + story.url!.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! : "")")!
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

protocol ItemView: View {
    var story: HNStory { get }
    var colorScheme: ColorScheme { get }
}

extension ItemView {
    private func genImage(_ url: URL?) -> UIImage? {
        guard let url = url else { return nil }
        guard let data = (try? Data(contentsOf: url)) else { return nil }
        return UIImage(data: data)
    }

    var _uiImage: UIImage? {
        return genImage(story.image)
    }

    var image: Image? {
        guard let uiImage = _uiImage else { return nil }
        return Image(uiImage: uiImage).resizable()
    }
}

struct SmallItemView: ItemView {
    let story: HNStory
    @Environment(\.colorScheme) var colorScheme

//    private var _uiAverageColor: UIColor? {
//        guard _uiImage != nil else { return nil }
//        // https://www.hackingwithswift.com/example-code/media/how-to-read-the-average-color-of-a-uiimage-using-ciareaaverage
//        guard let inputImage = CIImage(image: _uiImage!) else { return nil }
//                let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
//
//                guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
//                guard let outputImage = filter.outputImage else { return nil }
//
//                var bitmap = [UInt8](repeating: 0, count: 4)
//        let context = CIContext(options: [.workingColorSpace: kCFNull!])
//                context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
//
//                return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
//    }
//
//    var averageColor: Color {
//        guard _uiAverageColor != nil else { return .black }
//        return Color(_uiAverageColor!)
//    }
//
//    var foregroundAverageColor: Color {
//        guard _uiAverageColor != nil else {return .white}
//        var hue: CGFloat = 0
//        var saturation: CGFloat = 0
//        var brightness: CGFloat = 0
//        _uiAverageColor?.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
//        return Color(UIColor(hue: 0, saturation: 0, brightness: brightness <= 0.5 ? 1 : 0, alpha: 1))
//    }
    
    var averageColor = Color(UIColor.systemGray)
    var foregroundAverageColor = Color.white

    var body: some View { GeometryReader { metrics in
        ZStack {
            (self.averageColor).edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
                    (self.image ?? Image(systemName: "newspaper"))
                        .resizable()
                        .scaledToFill()
                        .frame(width: metrics.size.width, height: metrics.size.height * 0.6)
                        .clipped()
                            LinearGradient(gradient: Gradient(colors: [.clear, self.averageColor]), startPoint: .top, endPoint: .bottom).frame(height: 80)
                            Text("↑ \(story.score)  \(story.site)")

                                .font(.system(size: 11))
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                }
                Text(story.title)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 10)
                    .frame(maxHeight: .infinity)
            }
            .widgetURL(deepLink(story: story, showItem: true))
            .foregroundColor(self.foregroundAverageColor)
        }
    }
    }
}

struct BigItemView: ItemView {
    let story: HNStory
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack (alignment: .center) {
                Link(destination: deepLink(story: story, showItem: story.url != nil)) {
                    VStack(alignment: .leading) {
                        Text(story.site).font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
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
                }
            if self.image != nil {
                    Link(destination: deepLink(story: story, showItem: false)) { // should this still link?
                        (self.image!)
                            .scaledToFill()
                            .frame(width: 50, height: 50, alignment: .center)
                            .clipped()
                            .cornerRadius(8)
                    }
            }
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
            SmallItemView(story: entry.items[0])
        } else {
            // TODO: different categories? top, ask, show?
            ZStack {
                Color("WidgetColor").edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 5) {
//                if widgetFamily == .systemLarge {
                    Link(destination: URL(string: "benuse://home")!) { Text("Hacker News").foregroundColor(.orange).font(.system(size: 17, weight: .heavy)) }
//                }
                ForEach(entry.items, id: \.self) { item in
                    BigItemView(story: item)
                }
            }.padding(EdgeInsets(top: 10, leading: 15, bottom: 0, trailing: 15))
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

struct Benuse_Previews: PreviewProvider {
    static let dummy = HNStory(_item: HNAPIStory(id: 0, type: HNAPIType.story, by: "jrmann100", time: 0, text: nil, kids: [], url: "https://jrmann.com", score: 299, title: "Benuse - Bringing Hacker News to the iOS home screen", descendants: 0), site: "Jordan's Projects", image: URL(string: "https://images.saymedia-content.com/.image/t_share/MTc2Mjg0OTI2Mzc3ODYyMzM0/reading-newspaper-as-a-habit.jpg")!)
    static var previews: some View {
                SmallItemView(story: dummy).previewContext(WidgetPreviewContext(family: .systemSmall))

    }
}
