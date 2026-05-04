// RecapApp.swift

import SwiftUI

@main
struct RecapApp: App {
    @StateObject private var notifications = NotificationManager.shared

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.984, green: 0.969, blue: 0.949, alpha: 1) // #FBF7F2
        let item = UITabBarItemAppearance()
        item.selected.iconColor = UIColor(Color.accentOrange)
        item.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.accentOrange)]
        item.normal.iconColor = UIColor(Color.textMuted)
        item.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textMuted)]
        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notifications)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    NotificationManager.shared.clearBadge()
                    Task { await NotificationManager.shared.refreshStatus() }
                }
        }
    }
}
