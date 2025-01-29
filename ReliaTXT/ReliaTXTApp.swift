//
//  ReliaTXTApp.swift
//  ReliaTXT
//
//  Created by Johnithan Foster on 1/28/25.
//

import SwiftUI

@main
struct ReliaTXTApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
