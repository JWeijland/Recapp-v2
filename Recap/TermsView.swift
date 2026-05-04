// TermsView.swift – Terms & Conditions

import SwiftUI

struct TermsView: View {
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    ForEach(termsSections, id: \.title) { section in
                        termsSection(section)
                    }
                    footer
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Terms & Conditions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Terms & Conditions")
                .font(.system(size: 26, weight: .black))
                .foregroundColor(.textPrimary)
            Text("Last updated: April 2026")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textMuted)
            Text("By using Recap, you agree to these terms. Please read them carefully before proceeding.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
        }
    }

    private func termsSection(_ section: TermsSection) -> some View {
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
            Text("Questions?")
                .font(.system(size: 15, weight: .black))
                .foregroundColor(.textPrimary)
            Text("Contact us at legal@recapapp.io for any questions about these terms.")
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
            Text("Recap is registered in the Netherlands. These terms are governed by Dutch law.")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)
        }
        .padding(16)
        .background(Color.accentGreenSoft)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentGreen.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct TermsSection {
    let title: String
    let items: [String]
}

private let termsSections: [TermsSection] = [
    TermsSection(title: "Acceptance of Terms", items: [
        "By downloading, installing, or using Recap, you agree to be bound by these Terms & Conditions.",
        "If you do not agree to these terms, do not use the app.",
        "We may update these terms from time to time. Continued use of the app after changes constitutes acceptance.",
        "You must be at least 18 years old to use Recap.",
    ]),
    TermsSection(title: "Your Account", items: [
        "You are responsible for maintaining the confidentiality of your account credentials.",
        "You are responsible for all activity that occurs under your account.",
        "You must provide accurate and complete information when creating your account.",
        "You may not transfer your account to another person.",
        "We reserve the right to suspend or terminate accounts that violate these terms.",
    ]),
    TermsSection(title: "Acceptable Use", items: [
        "You may use Recap only for lawful, personal purposes.",
        "You may not use Recap to harass, abuse, or harm other users.",
        "You may not attempt to access other users' data without their consent.",
        "You may not reverse-engineer, decompile, or attempt to extract the source code of the app.",
        "You may not use the app to transmit spam, malware, or other harmful content.",
        "You may not misrepresent your identity or impersonate others.",
    ]),
    TermsSection(title: "User Content", items: [
        "You retain ownership of content you create within Recap (photos, recap titles, etc.).",
        "By using Recap, you grant us a limited licence to store and display your content to provide the service.",
        "We do not claim ownership of your photos or personal recap data.",
        "You are solely responsible for content you share publicly within the app.",
        "We reserve the right to remove content that violates these terms or applicable law.",
    ]),
    TermsSection(title: "Intellectual Property", items: [
        "Recap and all related branding, logos, and design are owned by Recap B.V.",
        "The app and its original content are protected by copyright and intellectual property law.",
        "You may not reproduce, distribute, or create derivative works from our intellectual property without permission.",
    ]),
    TermsSection(title: "Disclaimers & Liability", items: [
        "Recap is provided \"as is\" without warranties of any kind.",
        "We do not guarantee that the app will be available at all times or free from errors.",
        "We are not liable for any indirect, incidental, or consequential damages arising from your use of the app.",
        "Our total liability to you shall not exceed the amount you paid for the app in the past 12 months.",
        "Nothing in these terms limits liability that cannot be excluded under Dutch or EU law.",
    ]),
    TermsSection(title: "Termination", items: [
        "You may stop using Recap at any time and delete your account from the Settings screen.",
        "We may terminate or suspend your access to Recap at any time for violation of these terms.",
        "Upon termination, your right to use the app ceases immediately.",
        "Provisions of these terms that by their nature should survive termination will remain in effect.",
    ]),
    TermsSection(title: "Governing Law", items: [
        "These terms are governed by the laws of the Netherlands.",
        "Any disputes arising from these terms shall be subject to the exclusive jurisdiction of Dutch courts.",
        "For EU consumers, mandatory consumer protection provisions of your country of residence also apply.",
    ]),
]

#Preview { NavigationStack { TermsView() } }
