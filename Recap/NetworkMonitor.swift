// NetworkMonitor.swift – Real-time network connectivity tracking

import Combine
import Network
import SwiftUI

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected: Bool = true
    @Published var wasOffline:  Bool = false  // shows "back online" toast

    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "recap.network", qos: .utility)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let connected = path.status == .satisfied
                if !self.isConnected && connected {
                    self.wasOffline = true
                    // Auto-hide "back online" after 3s
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    self.wasOffline = false
                }
                self.isConnected = connected
            }
        }
        monitor.start(queue: queue)
    }
}

// MARK: – Reusable offline banner

struct OfflineBanner: View {
    @ObservedObject var network = NetworkMonitor.shared

    var body: some View {
        if !network.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 12, weight: .bold))
                Text("No internet connection")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color(hex: "#1C1B1A"))
            .clipShape(Capsule())
            .transition(.move(edge: .top).combined(with: .opacity))
        } else if network.wasOffline {
            HStack(spacing: 8) {
                Image(systemName: "wifi")
                    .font(.system(size: 12, weight: .bold))
                Text("Back online")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color.accentGreen)
            .clipShape(Capsule())
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
