// PrivacyPolicyView.swift – GDPR/AVG compliant privacy policy

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    ForEach(policySections, id: \.title) { section in
                        policySection(section)
                    }
                    footer
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Privacy Policy")
                .font(.system(size: 26, weight: .black))
                .foregroundColor(.textPrimary)
            Text("Last updated: April 2026")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textMuted)
            Text("Recap is committed to protecting your privacy. This policy explains what data we collect, why, and what rights you have.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
        }
    }

    private func policySection(_ section: PolicySection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.textPrimary)
            ForEach(section.items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.accentOrange)
                        .frame(width: 5, height: 5)
                        .padding(.top, 7)
                    Text(item)
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(3)
                }
            }
        }
        .padding(16)
        .background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderCard, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Contact")
                .font(.system(size: 15, weight: .black))
                .foregroundColor(.textPrimary)
            Text("Questions about your data? Contact us at privacy@recapapp.io")
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
            Text("Recap is registered in the Netherlands and complies with the AVG (GDPR).")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)
        }
        .padding(16)
        .background(Color.accentGreenSoft)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentGreen.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: – Policy content

private struct PolicySection {
    let title: String
    let items: [String]
}

private let policySections: [PolicySection] = [
    PolicySection(title: "What data we collect", items: [
        "Location data during an active Recap session — only while the app is in use or running in the background with your explicit permission.",
        "Photos from your camera roll taken during a session — only when you grant access.",
        "Profile information you enter: date of birth (age category only), country of origin, gender.",
        "Usage patterns: how often you use the app and how many recaps you create (aggregated, not linked to your identity).",
        "Aggregated location insights at city/region level — never your exact address or route.",
    ]),
    PolicySection(title: "What we do NOT collect", items: [
        "We do not share your live location with anyone.",
        "We do not sell your personal data to third parties.",
        "We do not track you outside of an active Recap session.",
        "We do not store your exact GPS coordinates on our servers — route data stays on your device.",
        "We do not use your photos for anything other than displaying them in your own recap.",
    ]),
    PolicySection(title: "How we use your data", items: [
        "To generate your personal recap timeline (locations, route, photos).",
        "To improve the app based on anonymous usage patterns.",
        "To send you notifications you have opted into (session reminders, weekly prompts).",
        "Aggregated, anonymised data may be used for trend analysis (e.g. popular areas at city level).",
    ]),
    PolicySection(title: "Data storage & security", items: [
        "Your recap data is stored locally on your device by default.",
        "If you create an account, data is synced to our secure cloud (Supabase, hosted in the EU).",
        "All data in transit is encrypted via HTTPS/TLS.",
        "We retain your data for as long as your account is active.",
        "You can delete all your data at any time from the Settings screen.",
    ]),
    PolicySection(title: "Your rights (AVG / GDPR)", items: [
        "Right of access: you can request a copy of all data we hold about you.",
        "Right to erasure: you can delete your account and all associated data at any time.",
        "Right to rectification: you can update your profile information at any time in Settings.",
        "Right to data portability: you can request an export of your data.",
        "Right to object: you can opt out of analytics and notifications at any time.",
        "To exercise any of these rights, contact us at privacy@recapapp.io or use the Delete Account option in Settings.",
    ]),
    PolicySection(title: "Children", items: [
        "Recap is intended for users aged 18 and over.",
        "We do not knowingly collect data from users under 18.",
        "If you believe a minor has created an account, contact us immediately.",
    ]),
]

#Preview { NavigationStack { PrivacyPolicyView() } }
