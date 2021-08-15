//
//  BenuseApp.swift
//  Shared
//
//  Created by Jordan Mann on 5/23/21.
//

import SwiftUI
import WebView
import WebKit

func goHome() {
    UIControl().sendAction(#selector(NSXPCConnection.suspend),
                           to: UIApplication.shared, for: nil)
}

class WKNavD: NSObject, WKNavigationDelegate {
    func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("going?")
        // todo: parse into and open benuse deep links
        if navigationAction.navigationType == .linkActivated  {
            if let url = navigationAction.request.url, true {
                // todo: make customizable
                print("whoosh", url.absoluteString)
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            }
        } else {
            decisionHandler(.allow)
        }
    }
    func webView(_: WKWebView, didStartProvisionalNavigation: WKNavigation!){
        print("connecting...");
    }
    func webView(_: WKWebView, didCommit: WKNavigation!){
        print("loading...");
    }
    func webView(_: WKWebView, didFinish: WKNavigation!){
        print("loaded!");
    }
}

@main
struct BenuseApp: App {
    @State var home: Bool = true // should this be replaced with a generic boolean?
    @State var pane: HNPane = .story
    @State var hide: HNPane? = nil
    @StateObject var storyWVS = WebViewStore()
    @StateObject var commentsWVS = WebViewStore()
    @State var storyNavD = WKNavD()
    @State var commentsNavD = WKNavD()
    var currentURL: URL? {
        switch hide {
        case nil: return pane ~= .story ? storyWVS.url : commentsWVS.url
        case .comments: return storyWVS.url
        case .story: return commentsWVS.url
        }
    }
    
    func deepLink(deepLink: URL) { // might need .async() for everything??
        print("Launching", deepLink.absoluteString)
        print("host is", deepLink.host!, deepLink.path)
        if deepLink.host! == "home" {
            hide = .comments
            pane = .story
            storyWVS.webView.load(URLRequest(url: URL(string: "https://news.ycombinator.com\(deepLink.path)")!))
        }
        else if deepLink.host! == "story" {
            let options = URLComponents(string: deepLink.absoluteString)!.queryItems!
            let id = options.first(where: {$0.name == "id"})!.value
            let someURL = options.first(where: {$0.name == "url"})?.value
            if someURL != nil {
                storyWVS.webView.load(URLRequest(url: URL(string: someURL!.removingPercentEncoding!)!))
            }
            let somePane = options.first(where: {$0.name == "pane"})?.value
            if somePane == HNPane.story.rawValue {
                pane = .story
            } else {
                pane = .comments // todo: default behavior override setting??
            }
            let someHide = options.first(where: {$0.name == "hide"})?.value
            if someHide == HNPane.comments.rawValue {
                hide = .comments
                pane = .story
                print("hide is comments")
            } else if someURL == nil {
                hide = .story
                pane = .comments
                print("hide is story")
            } else {
                hide = nil
                print("hide is nigh")
            }
            if hide != .comments {
                commentsWVS.webView.load(URLRequest(url: URL(string: "https://news.ycombinator.com/item?id=\(id!)")!))
            }
        }
        return home = false
    }
    
    struct BottomMenuView: View {
        struct ActivityViewController: UIViewControllerRepresentable {
            var activityItems: [Any]
            var applicationActivities: [UIActivity]? = nil
            @Environment(\.presentationMode) var presentationMode
            
            func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
                let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
                controller.completionWithItemsHandler = { _, _, _, _ in
                    self.presentationMode.wrappedValue.dismiss()
                }
                return controller
            }
            
            func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
        }
        
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
                        if !(hide ~= .story) { Image(systemName: "newspaper").tag(HNPane.story)}
                        if !(hide ~= .comments) { Image(systemName: "text.bubble").tag(HNPane.comments) }
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
                ActivityViewController(activityItems: [currentURL!])
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
                if home == true {
                    VStack {
                        VStack {
                            Button(action: goHome) { Image(systemName: "apps.iphone.badge.plus")
                                .font(.system(size: 50))
                            }.padding(20)
                            .background(Color(UIColor.systemGray5)).clipShape(Circle())
                        }
                        Spacer().frame(height: 20)
                        Text("Add the Benuse widget\nto your home screen.").multilineTextAlignment(.center).font(.system(.title))
                    }
                } else {
                    VStack {
                        TabView(selection: $pane) {
                            ZStack {
                                if hide != nil {Text("No story available.") }
                                // this is a bad solution, but there's no good way to disable gestures dynamically. .simultaneousGesture(DragGesture()) is permanent
                                WebView(webView: storyWVS.webView).opacity(hide ~= .story ? 0 : 1) // todo: swift 5 .refreshable()
                            }.tag(HNPane.story)
                            ZStack {
                                if hide != nil { Text("No comments available for this item.") }
                                WebView(webView: commentsWVS.webView).opacity(hide ~= .comments ? 0 : 1)
                            }.tag(HNPane.comments)
                            
                        }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)).transition(.slide).animation(.easeInOut(duration: 1.2), value: pane)
                        .onAppear {
                            storyWVS.webView.navigationDelegate = storyNavD
                            commentsWVS.webView.navigationDelegate = commentsNavD
                        }
                        BottomMenuView(pane: $pane, hide: $hide, currentURL: currentURL)
                    }
                }
            }.onOpenURL(perform: deepLink)
        }
    }
}
