//
//  BenuseApp.swift
//  Shared
//
//  Created by Jordan Mann on 5/23/21.
//

import SwiftUI

@main
struct BenuseApp: App {
    @State var deepURL: URL? = nil
    var body: some Scene {
        WindowGroup {
            ContentView(deepURL: $deepURL)
            /*Text(isLoading ? "Opening article..." : "You can use the widget now.")*/.onOpenURL(perform: { url in
                /*UIApplication.shared.open(
                    URL(string: "https://news.ycombinator.com/item?\(url.query!)")!,
                    completionHandler: {
                        print("opened deep link success? \($0)")
                        sleep(1)
                        isLoading = false
                    })*/
                deepURL = URL(string: "https://news.ycombinator.com/item?\(url.query!)")!
                
            })
        }
    }
}
