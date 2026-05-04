// FeedView.swift – Community feed of recaps

import SwiftUI

struct FeedComment: Identifiable {
    let id        = UUID()
    let author:   String
    let initials: String
    let avatarHex: String
    let text:     String
}

struct FeedPost: Identifiable {
    let id         = UUID()
    let profileId:  String
    let username:   String
    let initials:   String
    let avatarHex:  String
    let nightTitle: String
    let dateString: String
    let coverUri:   String
    let steps:      Int
    let stopsCount: Int
    var likes:      Int
    var isLiked:    Bool   = false
    var commentsCount: Int
    var commentList:   [FeedComment] = []
    let timeAgo:    String
    var caption:    String? = nil
    var taggedFriends: [String] = []
    var nightData:  NightData? = nil
}

let mockFeedPosts: [FeedPost] = [
    FeedPost(profileId: "SK", username: "Sophie K.", initials: "SK", avatarHex: "#EA5A8A",
             nightTitle: "Amsterdam Canal Night", dateString: "Sat, Apr 19",
             coverUri: "https://images.unsplash.com/photo-1512470876302-972faa2aa9a4?w=600",
             steps: 7320, stopsCount: 3, likes: 24, commentsCount: 7, timeAgo: "2h ago",
             caption: "Best night out in ages 🌙",
             nightData: mockNights[safe: 0]),
    FeedPost(profileId: "MB", username: "Marc B.", initials: "MB", avatarHex: "#3FA9F5",
             nightTitle: "Friday Harbour Walk", dateString: "Fri, Apr 18",
             coverUri: "https://images.unsplash.com/photo-1534430480872-3498386e7856?w=600",
             steps: 6120, stopsCount: 2, likes: 41, commentsCount: 12, timeAgo: "18h ago",
             nightData: mockNights[safe: 1]),
    FeedPost(profileId: "LW", username: "Lena W.", initials: "LW", avatarHex: "#4FC38A",
             nightTitle: "Friday Adventure", dateString: "Sat, Apr 12",
             coverUri: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600",
             steps: 9820, stopsCount: 4, likes: 18, commentsCount: 3, timeAgo: "1d ago",
             caption: "Eindelijk weer de stad in met deze gasten 🌙",
             taggedFriends: ["marc", "sophie"],
             nightData: mockNights[safe: 2]),
    FeedPost(profileId: "TN", username: "Tim N.", initials: "TN", avatarHex: "#9B7EDE",
             nightTitle: "Coffee & Chill", dateString: "Sun, Apr 13",
             coverUri: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600",
             steps: 5300, stopsCount: 3, likes: 9, commentsCount: 2, timeAgo: "2d ago",
             nightData: mockNights[safe: 3]),
    FeedPost(profileId: "EM", username: "Eva M.", initials: "EM", avatarHex: "#F4C23D",
             nightTitle: "Sunset Tapas Night", dateString: "Thu, Apr 10",
             coverUri: "https://images.unsplash.com/photo-1572116469696-31de0f17cc34?w=600",
             steps: 3800, stopsCount: 2, likes: 33, commentsCount: 8, timeAgo: "4d ago",
             nightData: mockNights[safe: 4]),
]

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct FeedView: View {
    @ObservedObject private var feedStore = FeedStore.shared
    @State private var isRefreshing = false

    private var displayPosts: [FeedPost] { feedStore.allPosts }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        topBar
                        ForEach(displayPosts) { post in
                            FeedCardWrapper(post: post, profile: mockFeedProfiles[post.profileId])
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                        }
                    }
                    .padding(.bottom, 40)
                }
                .refreshable {
                    await loadFeed()
                }
            }
            .navigationBarHidden(true)
            .task { await loadFeed() }
            .onAppear {
                if feedStore.cloudPosts.isEmpty {
                    feedStore.setCloudPosts(mockFeedPosts)
                }
            }
        }
    }

    private func loadFeed() async {
        guard SupabaseConfig.isConfigured else { return }
        do {
            let rows = try await SupabaseManager.shared.fetchFeedNights()
            let feedPosts = rows.map { row -> FeedPost in
                let name = row.authorName ?? "Recap User"
                let initials = name.split(separator: " ").prefix(2)
                    .compactMap(\.first).map(String.init).joined()
                return FeedPost(
                    profileId: row.userId,
                    username: name,
                    initials: initials.isEmpty ? "?" : initials,
                    avatarHex: feedAvatarColor(for: row.userId),
                    nightTitle: row.title,
                    dateString: row.data.dateString,
                    coverUri: row.data.photos.first?.uri ?? "",
                    steps: row.totalSteps,
                    stopsCount: row.stopsCount,
                    likes: 0,
                    commentsCount: 0,
                    timeAgo: feedTimeAgo(from: row.createdAt),
                    caption: row.data.postCaption
                )
            }
            if !feedPosts.isEmpty { feedStore.setCloudPosts(feedPosts) }
        } catch {}
    }

    private func feedAvatarColor(for userId: String) -> String {
        let palette = ["#EA5A8A","#3FA9F5","#4FC38A","#9B7EDE","#F4C23D","#FF8A3D"]
        return palette[abs(userId.hashValue) % palette.count]
    }

    private func feedTimeAgo(from iso: String?) -> String {
        guard let iso, let date = ISO8601DateFormatter().date(from: iso) else { return "" }
        let s = Int(Date().timeIntervalSince(date))
        if s < 3600  { return "\(s / 60)m ago" }
        if s < 86400 { return "\(s / 3600)h ago" }
        return "\(s / 86400)d ago"
    }

    private var topBar: some View {
        HStack {
            Text("Feed")
                .font(.system(size: 28, weight: .black))
                .tracking(-0.8)
                .foregroundColor(.textPrimary)
            Spacer()
        }
        .padding(.top, 58)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: – Feed card wrapper (owns local mutable state)

struct FeedCardWrapper: View {
    let post: FeedPost
    let profile: ProfileUser?
    @State private var mutablePost: FeedPost

    init(post: FeedPost, profile: ProfileUser?) {
        self.post    = post
        self.profile = profile
        _mutablePost = State(initialValue: post)
    }

    var body: some View {
        FeedCard(post: $mutablePost, profile: profile)
    }
}

// MARK: – Feed card

struct FeedCard: View {
    @Binding var post: FeedPost
    let profile: ProfileUser?
    @State private var showComments     = false
    @State private var showRecapDetail  = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            coverImage
            content
        }
        .background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.borderCard, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $showComments) {
            CommentSheet(post: $post, isPresented: $showComments)
        }
        .sheet(isPresented: $showRecapDetail) {
            FeedRecapDetailSheet(post: post)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Group {
                if let profile {
                    NavigationLink(destination: ProfileView(profile: profile)) {
                        avatarBlock
                    }
                    .buttonStyle(.plain)
                } else {
                    avatarBlock
                }
            }

            Spacer()

            ShareLink(item: "\(post.username) had a great Recap: \(post.nightTitle)! \(post.steps.formatted()) steps") {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.bgPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var avatarBlock: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(hex: post.avatarHex).opacity(0.2))
                    .frame(width: 38, height: 38)
                Text(post.initials)
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(Color(hex: post.avatarHex))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(post.username)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.textPrimary)
                Text(post.timeAgo)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.textMuted)
            }
        }
    }

    @ViewBuilder
    private var coverImage: some View {
        if let night = post.nightData {
            ScatteredDeckPreview(night: night, showTitle: false)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .onTapGesture { showRecapDetail = true }
        } else {
            AsyncImage(url: URL(string: post.coverUri)) { img in
                img.resizable().scaledToFill()
            } placeholder: { Color.bgPrimary }
            .frame(height: 180)
            .clipped()
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.nightTitle)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.textPrimary)

            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !post.taggedFriends.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.accentOrange)
                    Text(post.taggedFriends.joined(separator: ", "))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.accentOrange)
                }
            }

            Text(post.dateString)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textMuted)

            Divider().padding(.vertical, 2)

            HStack(spacing: 18) {
                Button {
                    post.isLiked.toggle()
                    post.likes += post.isLiked ? 1 : -1
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(post.isLiked ? .accentPink : .textSecondary)
                        Text("\(post.likes)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(post.isLiked ? .accentPink : .textSecondary)
                    }
                }

                Button { showComments = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 18))
                            .foregroundColor(.textSecondary)
                        Text("\(post.commentsCount + post.commentList.count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)

            if let firstComment = post.commentList.first {
                HStack(alignment: .top, spacing: 5) {
                    Text(firstComment.author)
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.textPrimary)
                    Text(firstComment.text)
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9)).foregroundColor(.accentOrange)
            Text(text).font(.system(size: 10, weight: .bold)).foregroundColor(.accentOrange)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.accentOrangeSoft)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: – Comment sheet

struct CommentSheet: View {
    @Binding var post: FeedPost
    @Binding var isPresented: Bool
    @State private var text = ""
    @FocusState private var focused: Bool

    private var ownName: String {
        UserDefaults.standard.string(forKey: "displayName") ?? "You"
    }
    private var ownInitials: String {
        ownName.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 0) {
                    if post.commentList.isEmpty && post.commentsCount == 0 {
                        Spacer()
                        Text("No comments yet.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textMuted)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(post.commentList) { comment in
                                    commentRow(comment)
                                    Divider().padding(.leading, 58)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                        }
                    }

                    Divider()

                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.accentOrange.opacity(0.18))
                                .frame(width: 34, height: 34)
                            Text(ownInitials)
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.accentOrange)
                        }

                        TextField("Write a comment...", text: $text)
                            .font(.system(size: 14, weight: .semibold))
                            .focused($focused)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(Color.bgCard)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderCard, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            let trimmed = text.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            let comment = FeedComment(
                                author: ownName,
                                initials: ownInitials,
                                avatarHex: "#FF8A3D",
                                text: trimmed
                            )
                            post.commentList.append(comment)
                            text = ""
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.accentOrange)
                        }
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.bgPrimary)
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isPresented = false }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.accentOrange)
                }
            }
        }
        .onAppear { focused = true }
    }

    private func commentRow(_ comment: FeedComment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: comment.avatarHex).opacity(0.18))
                    .frame(width: 36, height: 36)
                Text(comment.initials)
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(Color(hex: comment.avatarHex))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(comment.author)
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.textPrimary)
                Text(comment.text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview { FeedView() }
