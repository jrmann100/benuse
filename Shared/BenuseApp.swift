//
//  BenuseApp.swift
//  Shared
//
//  Created by Jordan Mann on 5/23/21.
//

import SwiftUI
import WebView

// struct WebView : UIViewRepresentable {
//
//    let request: URLRequest
//
//    func makeUIView(context: Context) -> WKWebView  {
//        return WKWebView()
//    }
//
//    func updateUIView(_ uiView: WKWebView, context: Context) {
//        uiView.load(request)
//    }
//
// }

enum HNSelectedView {
    case item, comments
}

func goHome() {
    UIControl().sendAction(#selector(NSXPCConnection.suspend),
                           to: UIApplication.shared, for: nil)
}

@main
struct BenuseApp: App {
    @State var url: URL?
    @State var id: String?
    @State var selectedTab: HNSelectedView = .item
    @StateObject var itemWVS = WebViewStore()
    @StateObject var commentsWVS = WebViewStore()
    
    func deepLink(deepLink: URL) {
        print("Launching", deepLink.host! + deepLink.path)
        if deepLink.host! == "home" {
            return UIApplication.shared.open(URL(string: "https://news.ycombinator.com")!)
        }
        id = deepLink.host!
        let urlString = URLComponents(string: deepLink.absoluteString)?.queryItems?.first(where: { $0.name == "url" })?.value
        url = urlString != nil ? URL(string: urlString!) : nil // maybe I want to hide the tab
        if deepLink.path == "/item" {
            selectedTab = .item
        } else if deepLink.path == "/comments" {
            selectedTab = .comments
        } else {
            // deep link is malformed.
        }
        if url != nil { itemWVS.webView.load(URLRequest(url: url!)) }
        commentsWVS.webView.load(URLRequest(url: URL(string: "https://news.ycombinator.com/item?id=\(deepLink.host!)")!))
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
        
        let selectedTab: Binding<HNSelectedView>
        let id: String
        let url: URL?
        
        @State var share = false
        
        var body: some View {
            HStack {
                Spacer()
                Button(action: {
                    share.toggle()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.large)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                }
                Spacer()
                HStack {
                    Picker("", selection: selectedTab) {
                        if url != nil {
                            Image(systemName: "newspaper").tag(HNSelectedView.item)
                        }
                        Image(systemName: "text.bubble").tag(HNSelectedView.comments)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }.frame(maxWidth: .infinity)
                Spacer()
                
                Button(action: {
                    UIApplication.shared.open(selectedTab.wrappedValue == .item ? url! : URL(string: "https://news.ycombinator.com/item?id=\(id)")!)
                }) {
                    Image(systemName: "safari")
                        .imageScale(.large)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                }
                Spacer()
            }.padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)).sheet(isPresented: $share, onDismiss: { share = false }) {
                ActivityViewController(activityItems: [url])
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
                if id == nil {
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
                        TabView(selection: $selectedTab) {
                            VStack {
                                WebView(webView: itemWVS.webView)
                            }.tag(HNSelectedView.item)
                            VStack {
                                WebView(webView: commentsWVS.webView)
                            }.tag(HNSelectedView.comments)
                            
                        }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)).animation(.easeInOut(duration: 1.2)).transition(.slide)
                        BottomMenuView(selectedTab: $selectedTab, id: id!, url: url)
                    }
                }
            }.onOpenURL(perform: deepLink)
        }
    }
}
