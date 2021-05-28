//
//  BenuseApp.swift
//  Shared
//
//  Created by Jordan Mann on 5/23/21.
//

import SwiftUI

@main
struct BenuseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().onOpenURL(perform: { url in
                print("Deep link! url is \(url)")
                UIApplication.shared.open(URL(string: "https://news.ycombinator.com/item?\(url.query!)")!)
            })
        }
    }
}
