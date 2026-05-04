// ContentView.swift – Splash screen + app routing

import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    @State private var splashDone      = false
    @State private var phase: LaunchPhase = .splash
    @State private var splashOpacity   = 1.0
    @State private var welcomeOpacity  = 0.0
    @State private var welcomeOffset   = 24.0
    @State private var logoScale       = 0.85

    private enum LaunchPhase { case splash, welcome }

    var body: some View {
        ZStack {
            if !splashDone {
                ZStack {
                    // Splash layer
                    LinearGradient(
                        colors: [Color(hex: "#FFF2D6"), Color(hex: "#FFE2CC"), Color(hex: "#FCD6B6")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    .opacity(splashOpacity)

                    Text("Recapp")
                        .font(.system(size: 72, weight: .black))
                        .tracking(-2)
                        .foregroundColor(.textPrimary)
                        .scaleEffect(logoScale)
                        .opacity(splashOpacity)

                    // Welcome layer
                    LinearGradient(
                        colors: [Color(hex: "#FFF6E5"), Color(hex: "#FFE8D1"), Color(hex: "#FBF7F2")],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    .opacity(welcomeOpacity)

                    VStack(spacing: 0) {
                        // Logo pill
                        HStack {
                            Spacer()
                            HStack(spacing: 0) {
                                Text("Recapp")
                                    .font(.system(size: 15, weight: .black))
                                    .tracking(-0.3)
                                    .foregroundColor(.textPrimary)
                            }
                            .padding(.horizontal, 18).padding(.vertical, 9)
                            .background(Color.bgCard)
                            .overlay(Capsule().stroke(Color.borderCard, lineWidth: 1))
                            .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(.top, 80)

                        Spacer()

                        VStack(spacing: 14) {
                            Text("Recapp")
                                .font(.system(size: 64, weight: .black))
                                .tracking(-2)
                                .foregroundColor(.textPrimary)

                            Text("Start.  Enjoy.  Relive.")
                                .font(.system(size: 18, weight: .heavy))
                                .tracking(1)
                                .foregroundColor(.accentOrange)

                            // Category chips
                            HStack(spacing: 10) {
                                categoryChip(emoji: "☕", label: "Cafés",  bg: Color.accentYellowSoft)
                                categoryChip(emoji: "🌳", label: "Parks",  bg: Color.accentGreenSoft)
                                categoryChip(emoji: "🥳", label: "Nights", bg: Color.accentPinkSoft)
                            }
                            .padding(.top, 6)
                        }

                        Spacer()

                        VStack(spacing: 12) {
                            Button(action: handleContinue) {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .black))
                                    .foregroundColor(Color(hex: "#FFFDF7"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .shadow(color: Color(hex: "#231600").opacity(0.12), radius: 16, y: 8)
                            }
                            .padding(.horizontal, 28)

                            Text("Relive your memories")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textMuted)
                        }
                        .padding(.bottom, 42)
                    }
                    .opacity(welcomeOpacity)
                    .offset(y: welcomeOffset)
                }

            } else {
                if onboardingComplete {
                    TabView {
                        DashboardView()
                            .tabItem { Label("My Recaps", systemImage: "moon.stars.fill") }
                        FeedView()
                            .tabItem { Label("Feed", systemImage: "rectangle.stack.fill") }
                    }
                    .tint(.accentOrange)
                    .transition(.opacity)
                } else {
                    OnboardingView()
                        .transition(.opacity)
                }
            }
        }
        .onAppear(perform: startSplash)
        .animation(.easeInOut(duration: 0.35), value: splashDone)
    }

    private func categoryChip(emoji: String, label: String, bg: Color) -> some View {
        HStack(spacing: 6) {
            Text(emoji).font(.system(size: 16))
            Text(label)
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(bg)
        .clipShape(Capsule())
    }

    private func startSplash() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoScale = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeIn(duration: 0.36))  { splashOpacity = 0 }
            withAnimation(.easeOut(duration: 0.48)) { welcomeOpacity = 1; welcomeOffset = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { phase = .welcome }
        }
    }

    private func handleContinue() {
        withAnimation { splashDone = true }
    }
}

#Preview { ContentView() }
