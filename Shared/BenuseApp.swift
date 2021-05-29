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
            ContentView(deepURL: $deepURL).onOpenURL(perform: { url in
                print("thas deep")
                deepURL = URL(string: "https://news.ycombinator.com/item?\(url.query!)")!
//                UIApplication.shared.open(
//                    URL(string: "https://news.ycombinator.com/item?\(url.query!)")!,
//                    completionHandler: {
//                        print("opened deep link success? \($0)")
//                    })
                
            })
        }
    }
}
