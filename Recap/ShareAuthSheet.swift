import SwiftUI

struct ShareAuthSheet: View {
    @ObservedObject private var supabase = SupabaseManager.shared
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @Environment(\.dismiss) private var dismiss

    @State private var isLogin   = false
    @State private var email     = ""
    @State private var password  = ""
    @State private var isLoading = false
    @State private var errorMsg  = ""

    private var canProceed: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 6
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#FFF6E5"), Color(hex: "#FFE8D1"), Color(hex: "#FBF7F2")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#FF9F53"), Color(hex: "#FF7A2F")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                        Text("Deel je Recap")
                            .font(.system(size: 24, weight: .black))
                            .tracking(-0.5)
                            .foregroundColor(.textPrimary)
                        Text("Maak een account om je avond te delen met vrienden")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 36)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 36)

                    // Register / Log in toggle
                    HStack(spacing: 4) {
                        ForEach(["Registreren", "Inloggen"], id: \.self) { tab in
                            let active = (tab == "Registreren") == !isLogin
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isLogin = (tab == "Inloggen")
                                }
                            } label: {
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
                    .padding(.bottom, 16)

                    // Fields
                    VStack(spacing: 12) {
                        TextField("E-mailadres", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .shareAuthFieldStyle()

                        SecureField("Wachtwoord (min. 6 tekens)", text: $password)
                            .shareAuthFieldStyle()
                    }
                    .padding(.horizontal, 24)

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

                    Button(action: handleEmailAction) {
                        Group {
                            if isLoading {
                                ProgressView().tint(Color(hex: "#FFFDF7"))
                            } else {
                                Text(isLogin ? "Inloggen" : "Account aanmaken")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(Color(hex: "#FFFDF7"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            canProceed
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(hex: "#FF9F53"), Color(hex: "#FF7A2F")],
                                    startPoint: .leading, endPoint: .trailing
                                  ))
                                : AnyShapeStyle(Color.textPrimary.opacity(0.25))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: canProceed ? Color(hex: "#FF7A2F").opacity(0.3) : .clear,
                                radius: 10, y: 5)
                    }
                    .disabled(!canProceed || isLoading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") { dismiss() }
                        .foregroundColor(.textMuted)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: – Actions

    private func handleEmailAction() {
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
                onboardingComplete = true
                dismiss()
            } catch {
                errorMsg = error.localizedDescription
            }
            isLoading = false
        }
    }
}

private extension View {
    func shareAuthFieldStyle() -> some View {
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
