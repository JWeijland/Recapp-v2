// FeedRecapDetailSheet.swift – View-only scattered deck for feed posts

import SwiftUI

struct FeedRecapDetailSheet: View {
    let post: FeedPost
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        authorHeader

                        if let night = post.nightData {
                            ScatteredDeckPreview(night: night, showTitle: true)
                                .padding(.horizontal, 16)
                        } else {
                            placeholderDeck
                        }

                        postMeta

                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(post.nightTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#C8C0B4"))
                    }
                }
            }
        }
    }

    // MARK: – Author header

    private var authorHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: post.avatarHex).opacity(0.18))
                    .frame(width: 46, height: 46)
                Circle()
                    .strokeBorder(Color(hex: post.avatarHex).opacity(0.25), lineWidth: 1.5)
                    .frame(width: 46, height: 46)
                Text(post.initials)
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(Color(hex: post.avatarHex))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(post.username)
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.textPrimary)
                Text(post.timeAgo)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.accentPink)
                Text("\(post.likes)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textSecondary)
                Image(systemName: "bubble.left")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                    .padding(.leading, 6)
                Text("\(post.commentsCount)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: – Placeholder when no nightData

    private var placeholderDeck: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(hex: "#F0EBE0"))
            .frame(width: CardMetrics.totalW, height: CardMetrics.totalH)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundColor(Color.accentOrange.opacity(0.4))
                    Text(post.nightTitle)
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color(hex: "#4A4540"))
                }
            )
            .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
    }

    // MARK: – Post meta (caption + tags)

    @ViewBuilder
    private var postMeta: some View {
        if let caption = post.caption, !caption.isEmpty {
            Text(caption)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
        }

        if !post.taggedFriends.isEmpty {
            HStack(spacing: 5) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.accentOrange)
                Text(post.taggedFriends.map { "@\($0)" }.joined(separator: " "))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.accentOrange)
            }
        }
    }
}
