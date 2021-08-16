//
//  WidgetViews.swift
//
//
//  Created by Jordan Mann on 7/15/21.
//

import Foundation
import SwiftUI

protocol ItemView: View {
    var story: HNStory { get }
    var site: String? { get }
    var image: Image? { get }
    var colorScheme: ColorScheme { get }
}

struct SmallItemView: ItemView {
    let story: HNStory
    let site: String?
    let image: Image?

    @Environment(\.colorScheme) var colorScheme

    var averageColor = Color(UIColor.systemGray)
    // TODO: this is really hard to do performantly.
    // maybe take average color of bottom or corner pixels?

    var foregroundAverageColor = Color.white

    var body: some View { GeometryReader { metrics in
        EmptyView().onAppear {}
        ZStack(alignment: .top) {
            (self.averageColor).edgesIgnoringSafeArea(.all)
            ZStack(alignment: .bottom) {
                if image == nil {
                    LinearGradient(gradient: Gradient(colors: [.blue, .red]), startPoint: .topLeading, endPoint: .bottomTrailing) // TODO: random gradient
                } else {
                    image!
                        .resizable()
                        .scaledToFill()
                        .clipped()
                }
                LinearGradient(gradient: Gradient(colors: [.clear, self.averageColor]), startPoint: .top, endPoint: .bottom).frame(height: 60)
            }.frame(maxWidth: metrics.size.width, maxHeight: metrics.size.height * 0.6)
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text("↑ \(story.score)  \(site ?? "")")

                    .font(.system(size: 11))
                    .lineLimit(1).opacity(0.9)
                Text(story.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(3)
            }.padding([.bottom, .horizontal], 10).frame(alignment: .center)
        }
        .widgetURL(deepLink(story: story, show: .story))
        .foregroundColor(self.foregroundAverageColor)
    }
    }
}

struct BigItemView: ItemView {
    let story: HNStory
    let site: String?
    let image: Image?

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        HStack(alignment: .center) {
            Link(destination: deepLink(story: story, show: .story)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(site ?? "").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                    Spacer().frame(maxHeight: 5)
                    HStack {
                        Text("↑ \(story.score)").opacity(0.5).font(.system(size: 13)).frame(width: 50, alignment: .center).fixedSize(horizontal: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/, vertical: false)
                        Text(story.title).frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true).lineLimit(widgetFamily == .systemLarge ? 3 : 2).font(.system(size: 14, weight: .bold))
                        // TODO: see how we feel about LineLimit and showing whole titles.
                        // a ompact font would be nice.
                    }
                }.onTapGesture(perform: {
                    // TODO: gray out visited links
                    // (Apple News-esque shuffling annoys me a bit, but that's also an option.
                })
            }
            if self.image != nil {
                Link(destination: deepLink(story: story, show: .comments)) {
                    (self.image!)
                        .scaledToFill()
                        .frame(width: 50, height: 50, alignment: .center)
                        .clipped()
                        .cornerRadius(8)
                }
            }
        }.frame(maxHeight: .infinity)
    }
}

struct ItemsView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if widgetFamily == .systemSmall {
            let (story, site, image) = entry.items.first!
            SmallItemView(story: story, site: site, image: image)
        } else {
            ZStack(alignment: .top) {
                Color("WidgetBackground").edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 5) {
                    Link(destination: URL(string: "benuse://home/\(entry.feed.path)")!) {
                        Text(entry.feed.title)
                            .foregroundColor(entry.feed.color)
                            .font(.system(size: 17, weight: .heavy))
                    }
                    ForEach(entry.items, id: \.self.0.id) { story, site, image in
                        BigItemView(story: story, site: site, image: image)
                    }
                }.padding(EdgeInsets(top: 15, leading: 15, bottom: 10, trailing: 15))
            }
        }
    }
}
