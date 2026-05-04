// EditProfileView.swift – Edit profile, home address, favorite places

import SwiftUI
import MapKit
import PhotosUI

enum ProfilePhotoStore {
    static func save(_ image: UIImage) {
        let data = image.jpegData(compressionQuality: 0.85)
        UserDefaults.standard.set(data, forKey: "profilePhotoData")
    }
    static func load() -> UIImage? {
        guard let data = UserDefaults.standard.data(forKey: "profilePhotoData") else { return nil }
        return UIImage(data: data)
    }
}

struct EditProfileView: View {
    @Binding var profile: ProfileUser
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String
    @State private var bio: String
    @State private var homeAddress: String
    @State private var favoritePlaces: [FavoritePlace]
    @State private var showAddPlace = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage? = ProfilePhotoStore.load()

    init(profile: Binding<ProfileUser>) {
        _profile       = profile
        _displayName   = State(initialValue: profile.wrappedValue.displayName)
        _bio           = State(initialValue: profile.wrappedValue.bio)
        _homeAddress   = State(initialValue: profile.wrappedValue.homeAddress)
        _favoritePlaces = State(initialValue: FavoritePlaceStore.load())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        profileSection
                        homeAddressSection
                        favoritePlacesSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.accentOrange)
                }
            }
            .sheet(isPresented: $showAddPlace) {
                AddFavoritePlaceView { place in
                    favoritePlaces.append(place)
                }
            }
        }
    }

    // MARK: – Profile fields

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Profile")

            HStack {
                Spacer()
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        if let img = profileImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(hex: profile.avatarHex).opacity(0.18))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(initials)
                                        .font(.system(size: 26, weight: .black))
                                        .foregroundColor(Color(hex: profile.avatarHex))
                                )
                        }
                        Circle()
                            .fill(Color.accentOrange)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
                Spacer()
            }

            field("Name", text: $displayName)
            field("Bio", text: $bio, axis: .vertical)
        }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    profileImage = img
                    ProfilePhotoStore.save(img)
                }
            }
        }
    }

    private var initials: String {
        displayName.split(separator: " ").prefix(2)
            .compactMap(\.first).map(String.init).joined()
    }

    // MARK: – Home address

    private var homeAddressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Home Address")

            field("Address", text: $homeAddress, placeholder: "e.g. 123 Main St, Amsterdam")
        }
    }

    // MARK: – Favorite places

    private var favoritePlacesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("Favorite Places")
                Spacer()
                Button { showAddPlace = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.accentOrange)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Color.accentOrangeSoft)
                    .clipShape(Capsule())
                }
            }

            if favoritePlaces.isEmpty {
                Text("No favorite places yet. Add one!")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textMuted)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(favoritePlaces) { place in
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.accentYellow)
                                .frame(width: 32, height: 32)
                                .background(Color.accentYellowSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(place.name)
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(.textPrimary)
                                Text(place.address)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.textMuted)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button {
                                favoritePlaces.removeAll { $0.id == place.id }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                    .foregroundColor(.accentPink)
                            }
                        }
                        .padding(12)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderCard, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }

    // MARK: – Helpers

    private func save() {
        profile.displayName = displayName.trimmingCharacters(in: .whitespaces)
        profile.bio         = bio.trimmingCharacters(in: .whitespaces)
        profile.homeAddress = homeAddress.trimmingCharacters(in: .whitespaces)
        UserDefaults.standard.set(homeAddress, forKey: "homeAddress")
        FavoritePlaceStore.save(favoritePlaces)
        dismiss()
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .black))
            .foregroundColor(.textPrimary)
    }

    private func field(_ label: String, text: Binding<String>,
                       placeholder: String? = nil, axis: Axis = .horizontal) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.4)
                .textCase(.uppercase)
                .foregroundColor(.textMuted)
            TextField(placeholder ?? label, text: text, axis: axis)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)
                .tint(.accentOrange)
                .lineLimit(axis == .vertical ? 3 : 1, reservesSpace: axis == .vertical)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.borderCard, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 13))
        }
    }
}

// MARK: – Add Favorite Place sheet

struct AddFavoritePlaceView: View {
    let onAdd: (FavoritePlace) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var results: [MKMapItem] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 0) {
                    searchBar
                    if isSearching {
                        ProgressView()
                            .padding(.top, 40)
                        Spacer()
                    } else if results.isEmpty && !searchText.isEmpty {
                        Text("No results found")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textMuted)
                            .padding(.top, 40)
                        Spacer()
                    } else {
                        List(results, id: \.self) { item in
                            Button {
                                if let coord = item.placemark.location?.coordinate {
                                    let name    = item.name ?? item.placemark.name ?? "Place"
                                    let address = [item.placemark.thoroughfare,
                                                   item.placemark.locality]
                                        .compactMap { $0 }.joined(separator: ", ")
                                    let place = FavoritePlace(
                                        name: name,
                                        address: address.isEmpty ? searchText : address,
                                        latitude: coord.latitude,
                                        longitude: coord.longitude
                                    )
                                    onAdd(place)
                                    dismiss()
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.name ?? "Unknown")
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundColor(.textPrimary)
                                    Text([item.placemark.thoroughfare, item.placemark.locality]
                                        .compactMap { $0 }.joined(separator: ", "))
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.textMuted)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.bgCard)
                        }
                        .listStyle(.plain)
                        .background(Color.bgPrimary)
                    }
                }
            }
            .navigationTitle("Add Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
                .font(.system(size: 14))
            TextField("Search a place...", text: $searchText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)
                .tint(.accentOrange)
                .onSubmit { performSearch() }
            if !searchText.isEmpty {
                Button { searchText = ""; results = [] } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textMuted)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 11)
        .background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderCard, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = searchText
        MKLocalSearch(request: req).start { response, _ in
            DispatchQueue.main.async {
                results = response?.mapItems ?? []
                isSearching = false
            }
        }
    }
}
