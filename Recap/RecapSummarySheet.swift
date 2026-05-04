// RecapSummarySheet.swift – Post-session: name, per-photo captions, caption, friend tags, share to feed

import SwiftUI
import Photos

struct RecapSummarySheet: View {
    @Binding var photos: [UIImage]
    let onSave: (_ title: String, _ selectedPhotos: [(UIImage, String?)], _ caption: String, _ taggedFriends: [String], _ postToFeed: Bool) -> Void

    @State private var title: String = ""
    @State private var caption: String = ""
    @State private var selectedIndices: Set<Int> = []
    @State private var photoCaptions: [Int: String] = [:]
    @State private var tagInput: String = ""
    @State private var taggedFriends: [String] = []
    @State private var photosLoaded = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        nameSection
                        photoComposerSection
                        captionSection
                        tagSection
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("Your Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
        }
        .onAppear {
            title = defaultTitle()
            selectedIndices = Set(photos.indices)
        }
        .onChange(of: photos) { _, newPhotos in
            for idx in newPhotos.indices where !selectedIndices.contains(idx) {
                selectedIndices.insert(idx)
            }
            if !newPhotos.isEmpty { photosLoaded = true }
        }
        .task {
            try? await Task.sleep(for: .seconds(3))
            photosLoaded = true
        }
    }

    // MARK: – Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Name")
            TextField("", text: $title,
                      prompt: Text("e.g. Friday Night Jordaan").foregroundColor(.textSecondary))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)
                .tint(.accentOrange)
                .padding(.horizontal, 14).padding(.vertical, 13)
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderCard, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: – Photo composer

    @ViewBuilder
    private var photoComposerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("Photos")
                Spacer()
                if !photos.isEmpty {
                    Text("\(selectedIndices.count)/\(photos.count) selected")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textMuted)
                }
            }

            if !photosLoaded && photos.isEmpty {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Loading photos...")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if photos.isEmpty {
                Text("No photos taken during this session.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textMuted)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(photos.indices, id: \.self) { idx in
                        photoComposerCard(idx: idx)
                    }
                }
            }
        }
    }

    private func photoComposerCard(idx: Int) -> some View {
        let selected = selectedIndices.contains(idx)
        return VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: photos[idx])
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .contentShape(Rectangle())
                    .opacity(selected ? 1.0 : 0.35)
                    .onTapGesture { togglePhoto(idx) }

                Button { togglePhoto(idx) } label: {
                    ZStack {
                        Circle()
                            .fill(selected ? Color.accentOrange : Color.black.opacity(0.4))
                            .frame(width: 30, height: 30)
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(10)
            }

            HStack(spacing: 8) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
                TextField("", text: Binding(
                    get: { photoCaptions[idx, default: ""] },
                    set: { photoCaptions[idx] = $0 }
                ), prompt: Text("Add a caption to this photo...").foregroundColor(.textSecondary))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)
                .tint(.accentOrange)
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(Color.bgCard)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderCard, lineWidth: 1))
    }

    // MARK: – Caption

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Post caption (optional)")
            TextField("", text: $caption, prompt: Text("What do you want to say about this night?").foregroundColor(.textSecondary), axis: .vertical)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)
                .tint(.accentOrange)
                .lineLimit(3, reservesSpace: true)
                .padding(.horizontal, 14).padding(.vertical, 13)
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderCard, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: – Tag friends

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Tag friends")
            HStack(spacing: 8) {
                TextField("", text: $tagInput,
                          prompt: Text("Username...").foregroundColor(.textSecondary))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .tint(.accentOrange)
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(Color.bgCard)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderCard, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    let t = tagInput.trimmingCharacters(in: .whitespaces)
                    guard !t.isEmpty, !taggedFriends.contains(t) else { return }
                    taggedFriends.append(t)
                    tagInput = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.accentOrange)
                }
            }
            if !taggedFriends.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(taggedFriends, id: \.self) { friend in
                            HStack(spacing: 5) {
                                Text("@\(friend)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.accentOrange)
                                Button { taggedFriends.removeAll { $0 == friend } } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.accentOrange.opacity(0.7))
                                }
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.accentOrangeSoft)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: – Action buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { save(postToFeed: true) } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .bold))
                    Text("Save & Share to Feed")
                        .font(.system(size: 16, weight: .black))
                }
                .foregroundColor(Color(hex: "#FFFDF7"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(colors: [Color(hex: "#FF9F53"), Color(hex: "#FF7A2F")],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color(hex: "#FF9F53").opacity(0.2), radius: 10, y: 6)
            }

            Button { save(postToFeed: false) } label: {
                Text("Save Only")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.borderCard, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.top, 4)
    }

    // MARK: – Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .black))
            .tracking(0.3)
            .foregroundColor(.textPrimary)
    }

    private func togglePhoto(_ idx: Int) {
        if selectedIndices.contains(idx) {
            selectedIndices.remove(idx)
        } else {
            selectedIndices.insert(idx)
        }
    }

    private func save(postToFeed: Bool) {
        let selected: [(UIImage, String?)] = selectedIndices.sorted().map { idx in
            let cap = photoCaptions[idx, default: ""]
            return (photos[idx], cap.isEmpty ? nil : cap)
        }
        onSave(title, selected, caption, taggedFriends, postToFeed)
    }

    private func defaultTitle() -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "Recap \(f.string(from: Date()))"
    }
}
