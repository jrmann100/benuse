//
//  BenuseApp.swift
//  Shared
//
//  Created by Jordan Mann on 5/23/21.
//

import SwiftUI
import WebView

func goHome() {
    UIControl().sendAction(#selector(NSXPCConnection.suspend),
                           to: UIApplication.shared, for: nil)
}

@main
struct BenuseApp: App {
    @State var home: Bool = true // should this be replaced with a generic boolean?
    @State var pane: HNPane = .story
    @State var hide: HNPane? = nil
    @StateObject var storyWVS = WebViewStore()
    @StateObject var commentsWVS = WebViewStore()
    @StateObject var storyNavD = WKNavD()
    @StateObject var commentsNavD = WKNavD()
    var currentURL: URL? {
        switch hide {
        case nil: return pane == .story ? storyWVS.url : commentsWVS.url
        case .comments: return storyWVS.url
        case .story: return commentsWVS.url
        }
    }
    
    func deepLink(deepLink: URL) { // when do we need .async()? seems to work as-is.
        print("Launching", deepLink.absoluteString)
        print("host is", deepLink.host!, deepLink.path)
        if deepLink.host! == "home" {
            hide = .comments
            pane = .story
            storyWVS.webView.load(URLRequest(url: URL(string: "https://news.ycombinator.com\(deepLink.path)")!))
        } else if deepLink.host! == "story" {
            let options = URLComponents(string: deepLink.absoluteString)!.queryItems!
            let id = options.first(where: { $0.name == "id" })!.value
            let someURL = options.first(where: { $0.name == "url" })?.value
            if someURL != nil {
                storyWVS.webView.load(URLRequest(url: URL(string: someURL!.removingPercentEncoding!)!))
            }
            let somePane = options.first(where: { $0.name == "pane" })?.value
            if somePane == HNPane.story.rawValue {
                pane = .story
            } else {
                pane = .comments // TODO: default behavior override setting
            }
            let someHide = options.first(where: { $0.name == "hide" })?.value
            if someHide == HNPane.comments.rawValue {
                hide = .comments
                pane = .story
            } else if someURL == nil {
                hide = .story
                pane = .comments
            } else {
                hide = nil
            }
            if hide != .comments {
                commentsWVS.webView.load(URLRequest(url: URL(string: "https://news.ycombinator.com/item?id=\(id!)")!))
            }
        }
        return home = false
    }
    
    @State var settings = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
                if home == true {
                    VStack {
//                        Spacer()
                        VStack {
                            Button(action: goHome) { Image(systemName: "apps.iphone.badge.plus")
                                .font(.system(size: 50))
                            }.padding(20)
                                .background(Color(UIColor.systemGray5)).clipShape(Circle())
                        }
                        Spacer().frame(height: 20)
                        Text("Add the Benuse widget\nto your home screen.").multilineTextAlignment(.center).font(.system(.title))
//                        Spacer()
//                        Button(action: { settings.toggle() }, label: {
//                            Image(systemName: "gearshape.fill")
//                            Text("Settings")
//                        }).font(.system(size: 20, weight: .heavy)).padding()
//                    }.sheet(isPresented: $settings) {
//                        SettingsV(open: $settings)
                    }
                } else {
                    VStack {
                        TabView(selection: $pane) {
                            ZStack {
                                if hide != nil { Text("No story available.") }
                                // this is a bad solution, but there's no good way to disable gestures dynamically. .simultaneousGesture(DragGesture()) is permanent
                                WebpageV(navD: storyNavD, wv: storyWVS.webView, hide: hide == .story)
                            }.tag(HNPane.story)
                            ZStack {
                                if hide != nil { Text("No comments available for this item.") }
                                WebpageV(navD: commentsNavD, wv: commentsWVS.webView, hide: hide == .comments)
                            }.tag(HNPane.comments)
                            
                        }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)).transition(.slide).animation(.easeInOut(duration: 1.2), value: pane)
                            .onAppear {
                                storyWVS.webView.navigationDelegate = storyNavD
                                commentsWVS.webView.navigationDelegate = commentsNavD
                            }
                        BottomMenuV(pane: $pane, hide: $hide, currentURL: currentURL)
                    }
                }
            }.onOpenURL(perform: deepLink)
        }
    }
    
    struct BottomMenuV: View {
        @Binding var pane: HNPane
        @Binding var hide: HNPane?
        let currentURL: URL?
        
        @State var share = false
        
        var body: some View {
            HStack {
                Spacer()
                Button(action: {
                    guard currentURL != nil else { return }
                    share.toggle()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.large)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                }
                Spacer()
                HStack {
                    Picker("", selection: $pane) {
                        if !(hide == .story) { Image(systemName: "newspaper").tag(HNPane.story) }
                        if !(hide == .comments) { Image(systemName: "text.bubble").tag(HNPane.comments) }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }.frame(maxWidth: .infinity)
                Spacer()
                
                Button(action: {
                    guard currentURL != nil else { return }
                    UIApplication.shared.open(currentURL!)
                }) {
                    Image(systemName: "safari")
                        .imageScale(.large)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                }
                Spacer()
            }.padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)).sheet(isPresented: $share, onDismiss: { share = false }) {
                ShareVC(activityItems: [currentURL!])
            }
        }
    }
}
