//
//  BenuseApp.swift
//  Shared
//
//  Created by Jordan Mann on 5/23/21.
//

import SwiftUI

@main
struct BenuseApp: App {
    @State var isLoading = false
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
                VStack {
                    if isLoading {
                        ProgressView().scaleEffect(x: 2, y: 2, anchor: .center).frame(minHeight: 50)
                    } else {
                        Image(systemName: "apps.iphone.badge.plus")
                            .font(.system(size: 50))
                    }
                    Spacer().frame(height: 20)
                    Text(isLoading ? "Opening article..." : "Add the Benuse widget\nto your home screen.").onOpenURL(perform: { url in
                        print("Thas deep:", url.absoluteString)
                        isLoading = true
                        UIApplication.shared.open(
                            url,
                            completionHandler: {
                                print("opened deep link success? \($0)")
                                sleep(1)
                                isLoading = false
                            })
                        
                    }).multilineTextAlignment(.center).font(.system(.title))
                }
            }
        }
    }
}
