// SearchPeopleView.swift – Search and follow other users

import SwiftUI

struct SearchPeopleView: View {
    @State private var query = ""
    @State private var results: [ProfileUser] = []
    @State private var hasSearched = false

    private let allProfiles = Array(mockFeedProfiles.values)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 0) {
                    topBar
                    searchBar
                    content
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: – Top bar

    private var topBar: some View {
        HStack {
            Text("Search")
                .font(.system(size: 28, weight: .black))
                .tracking(-0.8)
                .foregroundColor(.textPrimary)
            Spacer()
        }
        .padding(.top, 58)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: – Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
                .font(.system(size: 14))
            TextField("Search people...", text: $query)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)
                .tint(.accentOrange)
                .onSubmit { performSearch() }
                .onChange(of: query) { _, val in
                    if val.isEmpty { results = []; hasSearched = false }
                    else { performSearch() }
                }
            if !query.isEmpty {
                Button { query = ""; results = []; hasSearched = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textMuted)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderCard, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: – Content

    @ViewBuilder
    private var content: some View {
        if !hasSearched && query.isEmpty {
            suggestedSection
        } else if results.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "person.slash")
                    .font(.system(size: 40))
                    .foregroundColor(.textDim)
                Text("No results for \"\(query)\"")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textMuted)
            }
            .padding(.top, 60)
            Spacer()
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(results) { user in
                        NavigationLink(destination: ProfileView(profile: user)) {
                            PersonRow(user: user)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }

    private var suggestedSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Suggestions")
                    .font(.system(size: 13, weight: .black))
                    .tracking(0.3)
                    .foregroundColor(.textMuted)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                ForEach(allProfiles) { user in
                    NavigationLink(destination: ProfileView(profile: user)) {
                        PersonRow(user: user)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: – Search logic

    private func performSearch() {
        let q = query.lowercased()
        results = allProfiles.filter {
            $0.username.lowercased().contains(q) ||
            $0.displayName.lowercased().contains(q)
        }
        hasSearched = true
    }
}

// MARK: – Person row

struct PersonRow: View {
    let user: ProfileUser
    @State private var isFollowing: Bool

    init(user: ProfileUser) {
        self.user = user
        _isFollowing = State(initialValue: user.isFollowing)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: user.avatarHex).opacity(0.18))
                    .frame(width: 46, height: 46)
                Circle()
                    .strokeBorder(Color(hex: user.avatarHex).opacity(0.25), lineWidth: 1.5)
                    .frame(width: 46, height: 46)
                Text(initials(for: user.displayName))
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(Color(hex: user.avatarHex))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.textPrimary)
                Text("@\(user.username)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            if !user.isOwnProfile {
                Button {
                    isFollowing.toggle()
                } label: {
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isFollowing ? .textPrimary : Color(hex: "#FFFDF7"))
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(isFollowing ? Color.bgCard : Color.accentOrange)
                        .overlay(
                            Capsule().stroke(isFollowing ? Color.borderCard : Color.clear, lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderCard, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }
}

#Preview { SearchPeopleView() }
