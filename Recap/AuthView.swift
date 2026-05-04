// AuthView.swift – Login + Register screen

import SwiftUI

struct AuthView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    @State private var isLogin   = true
    @State private var email     = ""
    @State private var password  = ""
    @State private var isLoading = false
    @State private var errorMsg  = ""

    private var canProceed: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 6
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FFF6E5"), Color(hex: "#FFE8D1"), Color(hex: "#FBF7F2")],
                startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    Text("Recapp")
                        .font(.system(size: 40, weight: .black))
                        .tracking(-1)
                        .foregroundColor(.textPrimary)
                    Text("Relive your memories")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textMuted)
                }
                .padding(.bottom, 48)

                // Login / Register toggle
                HStack(spacing: 4) {
                    ForEach(["Log in", "Register"], id: \.self) { tab in
                        let active = (tab == "Log in") == isLogin
                        Button { withAnimation(.easeInOut(duration: 0.2)) { isLogin = (tab == "Log in") } } label: {
                            Text(tab)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(active ? .textPrimary : .textMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(active ? Color.bgCard : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(4)
                .background(Color.bgCard.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // Fields
                VStack(spacing: 12) {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .authFieldStyle()

                    SecureField("Password (min. 6 characters)", text: $password)
                        .authFieldStyle()
                }
                .padding(.horizontal, 24)

                // Error message
                if !errorMsg.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 13))
                        Text(errorMsg)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.accentPink)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }

                Spacer()

                // Demo skip
                Button {
                    onboardingComplete = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                        Text("Skip for Demo")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.accentOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, 24)

                // Action button
                Button(action: handleAction) {
                    Group {
                        if isLoading {
                            ProgressView().tint(Color(hex: "#FFFDF7"))
                        } else {
                            Text(isLogin ? "Log in" : "Create Account")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(Color(hex: "#FFFDF7"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canProceed ? Color.textPrimary : Color.textPrimary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .disabled(!canProceed || isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func handleAction() {
        guard canProceed, !isLoading else { return }
        isLoading = true
        errorMsg  = ""
        Task {
            do {
                if isLogin {
                    try await supabase.signIn(email: email, password: password)
                } else {
                    try await supabase.signUp(email: email, password: password)
                }
            } catch {
                errorMsg = error.localizedDescription
            }
            isLoading = false
        }
    }
}

private extension View {
    func authFieldStyle() -> some View {
        self
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.textPrimary)
            .tint(.accentOrange)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.bgCard)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderInput, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview { AuthView() }
