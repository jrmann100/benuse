//
//  WebUtil.swift
//  Benuse (iOS)
//
//  Created by Jordan Mann on 8/15/21.
//

import SwiftUI
import WebKit
import WebView

enum WebViewState {
    case connecting
    case loading
    case loaded
}

class WKNavD: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var state: WebViewState = .loading
    func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // TODO: parse into and open benuse deep links
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url, true {
                // TODO: add setting for deep link behavior
                print("whoosh", url.absoluteString)
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
        self.state = .connecting
    }

    func webView(_: WKWebView, didCommit: WKNavigation!) {
        self.state = .loading
    }

    func webView(_: WKWebView, didFinish: WKNavigation!) {
        self.state = .loaded
    }
}

struct WebpageV: View {
    // TODO: swift 5 .refreshable()
    @ObservedObject var navD: WKNavD
    var wv: WKWebView
    var hide: Bool
    var width: Float {
        switch self.navD.state {
        case .connecting: return 0.2
        case .loading: return 0.5
        case .loaded: return 1
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                Color.blue.frame(width: CGFloat(width) * geometry.size.width).animation(.easeOut).opacity(navD.state == .loaded ? 0 : 1).animation(.easeInOut.delay(0.5))
            }.frame(height: 3)
            WebView(webView: wv).opacity(hide || navD.state == .connecting ? 0 : 1).animation(.linear(duration: 0.2).delay(0.1))
        }
    }
}

struct ShareVC: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareVC>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.completionWithItemsHandler = { _, _, _, _ in
            self.presentationMode.wrappedValue.dismiss()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareVC>) {}
}

struct SettingsV: View {
    @Binding var open: Bool
    var body: some View {
        NavigationView {
            VStack {
                Text("There are no settings yet!")
            }
            .navigationBarTitle(Text("Settings"), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                open = false
            }) {
                Text("Done").bold()
            })
        }
    }
}
