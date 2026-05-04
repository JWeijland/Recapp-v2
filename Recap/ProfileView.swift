// ProfileView.swift – Instagram-style user profile

import SwiftUI

// MARK: – Profile model

struct ProfileUser: Identifiable {
    let id:             String
    var username:       String
    var displayName:    String
    var bio:            String
    let avatarHex:      String
    var postsCount:     Int
    var followersCount: Int
    var followingCount: Int
    var isFollowing:    Bool   = false
    let isOwnProfile:   Bool
    let recaps:         [NightData]
    var homeAddress:    String = ""
}

// MARK: – Mock profiles

let mockOwnProfile = ProfileUser(
    id: "own",
    username: "jweijland",
    displayName: "Jelle Weijland",
    bio: "Reliving every night. Built with Recap.",
    avatarHex: "#FF8A3D",
    postsCount: mockNights.count,
    followersCount: 142,
    followingCount: 89,
    isOwnProfile: true,
    recaps: mockNights
)

let mockFeedProfiles: [String: ProfileUser] = [
    "SK": ProfileUser(id: "SK", username: "sophiek", displayName: "Sophie K.",
                      bio: "Amsterdam nights \u{2728}", avatarHex: "#EA5A8A",
                      postsCount: 12, followersCount: 834, followingCount: 201,
                      isOwnProfile: false, recaps: Array(mockNights.prefix(3))),
    "MB": ProfileUser(id: "MB", username: "marcb_", displayName: "Marc B.",
                      bio: "Always exploring", avatarHex: "#3FA9F5",
                      postsCount: 28, followersCount: 1204, followingCount: 387,
                      isOwnProfile: false, recaps: Array(mockNights.prefix(4))),
    "LW": ProfileUser(id: "LW", username: "lenaw", displayName: "Lena W.",
                      bio: "Coffee & adventures", avatarHex: "#4FC38A",
                      postsCount: 8, followersCount: 312, followingCount: 156,
                      isOwnProfile: false, recaps: Array(mockNights.prefix(2))),
    "TN": ProfileUser(id: "TN", username: "tim.n", displayName: "Tim N.",
                      bio: "Sunday mornings.", avatarHex: "#9B7EDE",
                      postsCount: 15, followersCount: 567, followingCount: 234,
                      isOwnProfile: false, recaps: mockNights),
    "EM": ProfileUser(id: "EM", username: "eva.m", displayName: "Eva M.",
                      bio: "Rooftop enthusiast", avatarHex: "#F4C23D",
                      postsCount: 6, followersCount: 891, followingCount: 445,
                      isOwnProfile: false, recaps: Array(mockNights.prefix(2))),
]

// MARK: – View

struct ProfileView: View {
    @State var profile:  ProfileUser
    @State private var nights: [NightData]
    @State private var showEditProfile = false
    @Environment(\.dismiss) private var dismiss
    @State private var profileImage: UIImage? = ProfilePhotoStore.load()

    private let columns = [GridItem(.flexible(), spacing: 2),
                           GridItem(.flexible(), spacing: 2),
                           GridItem(.flexible(), spacing: 2)]

    init(profile: ProfileUser = mockOwnProfile) {
        _profile = State(initialValue: profile)
        _nights  = State(initialValue: profile.recaps)
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    divider
                    recapGrid
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: – Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
            avatarStatsRow
            nameBlock
            actionButton
        }
        .padding(.bottom, 16)
    }

    private var topBar: some View {
        HStack {
            if !profile.isOwnProfile {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderCard, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            Text(profile.username)
                .font(.system(size: 20, weight: .black))
                .tracking(-0.4)
                .foregroundColor(.textPrimary)
            Spacer()
            if profile.isOwnProfile {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                        .frame(width: 38, height: 38)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderCard, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 58)
        .padding(.bottom, 20)
    }

    private var avatarStatsRow: some View {
        HStack(spacing: 0) {
            // Avatar
            ZStack {
                if profile.isOwnProfile, let img = profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color(hex: profile.avatarHex).opacity(0.3), lineWidth: 2))
                } else {
                    Circle()
                        .fill(Color(hex: profile.avatarHex).opacity(0.18))
                        .frame(width: 80, height: 80)
                    Circle()
                        .strokeBorder(Color(hex: profile.avatarHex).opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                    Text(initials)
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(Color(hex: profile.avatarHex))
                }
            }
            .padding(.leading, 20)

            Spacer()

            // Stats
            HStack(spacing: 0) {
                statPill(value: profile.postsCount,     label: "Posts")
                statDivider
                statPill(value: profile.followersCount, label: "Followers")
                statDivider
                statPill(value: profile.followingCount, label: "Following")
            }
            .padding(.trailing, 20)
        }
        .padding(.bottom, 14)
    }

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.displayName)
                .font(.system(size: 15, weight: .black))
                .foregroundColor(.textPrimary)
            if !profile.bio.isEmpty {
                Text(profile.bio)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var actionButton: some View {
        if profile.isOwnProfile {
            Button { showEditProfile = true } label: {
                Text("Edit Profile")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.bgCard)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderCard, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 20)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(profile: $profile)
            }
            .onChange(of: showEditProfile) { _, open in
                if !open { profileImage = ProfilePhotoStore.load() }
            }
        } else {
            HStack(spacing: 10) {
                Button {
                    profile.isFollowing.toggle()
                    profile.followersCount += profile.isFollowing ? 1 : -1
                } label: {
                    Text(profile.isFollowing ? "Following" : "Follow")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(profile.isFollowing ? .textPrimary : Color(hex: "#FFFDF7"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(profile.isFollowing ? Color.bgCard : Color.accentOrange)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(profile.isFollowing ? Color.borderCard : Color.clear, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {} label: {
                    Text("Message")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderCard, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: – Grid

    private var divider: some View {
        Rectangle()
            .fill(Color.borderCard)
            .frame(height: 1)
            .padding(.bottom, 2)
    }

    private var recapGrid: some View {
        Group {
            if nights.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 32))
                        .foregroundColor(.textDim)
                    Text("No recaps yet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textMuted)
                }
                .padding(.vertical, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(nights) { night in
                        NavigationLink(destination: NightDetailView(nightId: night.nightId, nights: $nights)) {
                            recapCell(night)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func recapCell(_ night: NightData) -> some View {
        let size = (UIScreen.main.bounds.width - 6) / 3
        return ZStack(alignment: .bottomLeading) {
            if let photo = night.photos.first {
                AsyncImage(url: URL(string: photo.uri)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.bgAlt
                }
                .frame(width: size, height: size)
                .clipped()
            } else {
                LinearGradient(colors: [Color.accentOrangeSoft, Color.accentBlueSoft],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: size, height: size)
            }

            LinearGradient(colors: [Color.clear, Color.black.opacity(0.5)],
                           startPoint: .center, endPoint: .bottom)
                .frame(width: size, height: size)

            Text(night.title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
        }
        .frame(width: size, height: size)
        .clipped()
    }

    // MARK: – Helpers

    private var initials: String {
        profile.displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
    }

    private func statPill(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value >= 1000 ? String(format: "%.1fK", Double(value) / 1000) : "\(value)")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.borderCard)
            .frame(width: 1, height: 28)
    }
}

#Preview {
    ProfileView()
}
