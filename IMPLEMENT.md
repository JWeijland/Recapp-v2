# Recapp v2 — Full Implementation Prompt for Claude Code

You are Claude Code. You have full autonomy. Implement everything in this document without asking questions. Make decisions. If something is ambiguous, pick the best option and keep moving. The goal is a complete, polished, human-feeling iOS app in SwiftUI.

---

## Working directory

`/Users/jelleweijland/Documents/Recap/Recapp-v2/Recap/`

All Swift files live here. The Xcode project is `Recapp.xcodeproj`. Do not move or rename files outside of what's specified below.

---

## What this app is

**Recapp** is a social memory tracker for nights out and city outings. Users tap Start before going out, the app tracks their route and stops silently, then when they get home they tap Finish, pick their best photos, add a caption, and optionally share to a friend feed. Think Strava for social life. Think Polarsteps for your city.

Target user: 18–30 year olds who go out regularly and want a low-effort way to remember and share where they've been.

---

## Ground rules

- Language: **100% English** — find and replace every Dutch word (JJJJ → YYYY, Maand → Month, stappen → steps, Jij → You, Gemaakt met Recap → Made with Recapp)
- Framework: SwiftUI, iOS 17+, existing dependencies (Supabase, MapKit, Photos, CoreLocation) unchanged
- Do not break existing backend logic (SupabaseManager, LocationManager, NotificationManager, NetworkMonitor, FavoritePlaceStore) — only touch UI and data models
- Commit after every major screen or feature group is complete
- The Caveat font is already bundled — use it MORE (recap titles, hero numbers, celebration moments)
- `ScatteredDeckPreview` is the best component in the app — do not modify it
- Dark mode: implement proper dynamic colors for every screen

---

## Step 1 — Data model first (NightData.swift)

Add one field to `NightData`:
```swift
var mood: String? = nil  // "🔥 Banger", "🌙 Chill", "🫀 Wholesome", "🤪 Wild"
```

---

## Step 2 — Color system (update wherever Color extensions are defined)

Replace all static color definitions with dynamic light/dark variants using `Color(uiColor: UIColor { trait in ... })` or Asset Catalog approach. Use these values:

```
bgPrimary:     light #FAFAF8  /  dark #1A1A18
bgCard:        light #FFFFFF  /  dark #242420
bgAlt:         light #F2EDE4  /  dark #1E1E1C
textPrimary:   light #1C1208  /  dark #F5F0E8
textSecondary: light #6B5E4A  /  dark #A89880
textMuted:     light #A89678  /  dark #7A6A58
textDim:       light #C8B89A  /  dark #4A3A28
borderCard:    light #EDE0CC  /  dark #333328
borderInput:   light #D4C4A8  /  dark #3A3028
```

Accent colors stay the same in both modes — they work on dark backgrounds already.

---

## Step 3 — Navigation (ContentView.swift)

Replace the 2-tab `TabView` with a 5-tab version:

```swift
TabView(selection: $selectedTab) {
    DashboardView()
        .tabItem { Label("Recaps", systemImage: "moon.stars.fill") }
        .tag(0)
    FeedView()
        .tabItem { Label("Feed", systemImage: "rectangle.stack.fill") }
        .tag(1)
    ExploreView()
        .tabItem { Label("Explore", systemImage: "magnifyingglass") }
        .tag(2)
    ActivityView()
        .tabItem { Label("Activity", systemImage: "bell.fill") }
        .tag(3)
    ProfileView()
        .tabItem { Label("Me", systemImage: "person.crop.circle.fill") }
        .tag(4)
}
.tint(.accentOrange)
.badge(unreadCount, for: 3)  // red dot on Activity tab
```

Add `@AppStorage("unreadNotifications") private var unreadCount = 2` — clears to 0 when tab 3 is selected.

Add custom tab bar haptic: use `onChange(of: selectedTab)` to fire `UIImpactFeedbackGenerator(style: .light).impactOccurred()` on every tab change.

**Splash/Welcome screen changes:**
- Logo: use Caveat font, size 68, weight regular (the handwritten feel)
- Replace "Start. Enjoy. Relive." with `"Where did you go last night?"`
- Replace category chips (Cafés, Parks, Nights) with: `Text("Join 2,400 people reliving their outings")` — size 13, semibold, textSecondary
- Replace "Relive your memories" below Continue button with: `"Free · No algorithm · Just yours"`
- Continue button: add press scale animation (0.96 → 1.0 spring) + `UIImpactFeedbackGenerator(style: .medium).impactOccurred()`

---

## Step 4 — Dashboard (DashboardView.swift)

### Top bar
- Remove the `person` icon NavigationLink to SettingsView entirely
- Title "My Recaps": switch to Caveat font, size 30
- Add a time-of-day greeting ABOVE the title (small, muted):
  ```swift
  private var greeting: String {
      let h = Calendar.current.component(.hour, from: Date())
      switch h {
      case 0..<12: return "Good morning,"
      case 12..<17: return "Good afternoon,"
      case 17..<22: return "Good evening,"
      default: return "Still up?"
      }
  }
  ```
  Font: system 13, semibold, textMuted

### Weekly summary card (insert between topBar and map section)
Show only if at least 1 recap exists this week. Calculate using `dateISO`:
```
┌──────────────────────────────────────────┐
│ 📅  This week                            │
│     2 recaps · 14 spots · 12.4 km       │
└──────────────────────────────────────────┘
```
Background: accentOrangeSoft, corner radius 16, no border, padding 14. If zero recaps this week: hide entirely.

### Map section fix
- Change "View all" NavigationLink destination from `SettingsView()` to `FavoritePlacesView()`
- Map style: `.standard(pointsOfInterest: .excludingAll)`
- Empty state text: `"Heart a spot in any recap to save it here"`

### Live session
- Remove the separate pink status row above the End button
- Add a floating pill overlay ON the map: `"Out for 1h 23m  ●"` — white text, dark background with 0.7 opacity, Capsule shape, positioned `.bottom` inside the map overlay
- The live pulsing dot: replace with a custom annotation — an orange circle that scales 1.0 → 1.5 → 1.0 repeating with `.easeInOut(duration: 1.5).repeatForever(autoreverses: true)`

### Action buttons
- "Start New Recap" → rename to `"Start Recap"`, corner radius 20pt
- "End Recap" → rename to `"Finish & Save"`
- Below Start button (when no active session): `"Last out: Friday"` or `"Last out: 3 days ago"` — compute from `nights.first?.dateISO`, size 12, textMuted
- Start tap: `UINotificationFeedbackGenerator().notificationOccurred(.success)` + button scale 0.96 → 1.0 spring
- Finish & Save tap: `UINotificationFeedbackGenerator().notificationOccurred(.success)` haptic

### Recap list
- Section title: `"Your recaps"` (was "Previous Recaps")
- Remove pencil icon from `RecapCard` — move rename to `.contextMenu`:
  ```swift
  .contextMenu {
      Button("Rename") { /* existing rename alert logic */ }
      Button("Share") { /* ShareLink */ }
      Button("Delete", role: .destructive) { /* remove from nights array */ }
  }
  ```

### RecapCard redesign
Complete rewrite of the card body:

```
┌─────────────────────────────────────────┐  ← shadow(color: .black.opacity(0.04), radius: 8, y: 2)
│ [72×72 photo or gradient]               │
│                         "2 days ago"   │  ← size 10, textMuted, top-right
│  Friday Vibes                           │  ← Caveat font, size 18, textPrimary
│  4 spots · 2.1 km · 3h 12m             │  ← size 11, textSecondary, no chips
│                                    ›   │
└─────────────────────────────────────────┘
```

- Photo: 72×72, corner radius 16
- If no photo: `LinearGradient` using date string as color seed (hash the dateISO string to pick from 6 preset gradients)
- Remove "Latest Recap" badge — most recent card gets `scaleEffect(1.01)` and `borderColor: Color.accentOrange.opacity(0.6)`
- Natural language stats: compute `"\(night.totalStopsCount) spots · \(km) km · \(night.totalDuration)"` where km = `String(format: "%.1f", Double(night.totalSteps) * 0.00075)`
- Time-ago: compute from `night.dateISO` → "Today", "Yesterday", "2 days ago", "Last Friday", etc.
- Press animation: `scaleEffect(isPressed ? 0.98 : 1.0)` using `@GestureState private var isPressed = false` with `.simultaneousGesture(DragGesture(minimumDistance: 0)...)`

### Empty state
- Icon: `Text("🌆").font(.system(size: 56))` instead of SF Symbol
- Title: `"Nothing here yet"`
- Subtitle: `"Tap the button above next time you head out."`

### Search bar
- Animate in: `.transition(.move(edge: .top).combined(with: .opacity))`
- Placeholder: `"Search your recaps..."`

---

## Step 5 — RecapSummarySheet (RecapSummarySheet.swift)

### Celebration on appear
Add a `CelebrationOverlay` view that shows on `.onAppear`:
```swift
struct CelebrationParticle: Identifiable {
    let id = UUID()
    let color: Color
    let angle: Double
    let distance: Double
}
```
Generate 8 particles with random angles (0–360°) and distances (60–100pt). On appear, animate from `(0,0)` to their target positions with `scaleEffect(0→1→0)` and `opacity(1→0)` over 0.8s using `withAnimation(.spring(response: 0.5, dampingFraction: 0.6))`.

### Dynamic headline
```swift
private var celebrationTitle: String {
    if stops > 4 { return "Busy one!" }
    if duration < 3600 { return "Quick one!" }
    return "Great night out!"
}
```
Use Caveat font, size 36, textPrimary.

### Natural language summary
Below headline: `"You hit \(stops) spots over \(durationString) and walked \(km) km"` — system font, size 15, textSecondary.

### Mood picker (add before title field)
```swift
let moods = [("🔥", "Banger"), ("🌙", "Chill"), ("🫀", "Wholesome"), ("🤪", "Wild")]
```
Horizontal HStack of 4 chips. Selected: accentOrangeSoft background, `scaleEffect(1.06)` spring. Store selection in `@State var selectedMood: String?`. Pass into `finalizeRecap` and save to `NightData.mood`.

### Title field
- Default: use first stop name if available, else `"Recap \(dateFormatted)"`
- Placeholder: `"Give this night a name..."`

### Photo grid
- Add "Select all" / "Deselect all" text button top-right of the photos section
- Selected photo: orange 2pt ring overlay + checkmark circle top-right, spring scale animation 0.9→1.0 on select

### Caption field
- Placeholder: `"Add a caption... (optional)"`
- Show character counter when typing: `"\(text.count) / 280"` — size 11, textMuted, trailing

### Toggle label
- "Post to feed" → `"Share with friends"`

### Save button
- Label: `"Save Recap"`
- On tap: `UINotificationFeedbackGenerator().notificationOccurred(.success)` + scale 0.96→1.0 spring
- After save: show a bottom toast in DashboardView: `"Recap saved 🎉"` — implement as a `@State var showSaveToast` + a `.overlay(alignment: .bottom)` capsule that appears for 2.5 seconds then fades out

### Milestone detection (in DashboardView.finalizeRecap)
After inserting the new night, check `nights.count`:
- 5 recaps: show `MilestoneToastView(emoji: "🎉", title: "5 recaps!", subtitle: "You're on a roll.")`
- 10 recaps: `MilestoneToastView(emoji: "🔥", title: "10 recaps!", subtitle: "That's commitment.")`
- 25 recaps: `MilestoneToastView(emoji: "🏅", title: "25 recaps!", subtitle: "Legendary.")`

`MilestoneToastView` is a new file. It's a bottom-anchored card (accentOrangeSoft background, corner radius 20, shadow) that slides up from bottom on appear, auto-dismisses after 3 seconds, fires `UINotificationFeedbackGenerator().notificationOccurred(.success)` on appear.

---

## Step 6 — NightDetailView (NightDetailView.swift)

### Remove arrow navigation
Delete `titleNavBar` entirely. Delete `canGoOlder`, `canGoNewer`, `currentIndex` navigation logic. The view receives one `nightId`, shows one recap, navigates back via standard back button.

### New top bar
Use SwiftUI navigation:
```swift
.navigationTitle(night.title)
.navigationBarTitleDisplayMode(.large)
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Menu {
            Button("Rename") { showRenameAlert = true }
            ShareLink(item: night.title) { Label("Share", systemImage: "square.and.arrow.up") }
            Button("Delete", role: .destructive) { /* remove night */ }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.textPrimary)
        }
    }
}
```

### Route map at top (new)
Add as the FIRST element inside `scrollContent`, before `deckSection`:
```swift
private var routeMapSection: some View {
    let coords = night.routeCoordinates.map {
        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
    return Map {
        if coords.count > 1 {
            MapPolyline(coordinates: coords)
                .stroke(Color.accentOrange, lineWidth: 3)
        }
        // Start dot: green
        // End dot: pink
        // Numbered stop annotations
        ForEach(Array(night.stops.enumerated()), id: \.element.stopId) { idx, stop in
            Annotation("", coordinate: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)) {
                ZStack {
                    Circle().fill(Color.accentOrange).frame(width: 24, height: 24)
                    Text("\(idx + 1)").font(.system(size: 11, weight: .black)).foregroundColor(.white)
                }
            }
        }
    }
    .mapStyle(.standard(pointsOfInterest: .excludingAll))
    .mapControls { }
    .frame(height: 220)
    // No corner radius — edge to edge like Apple Maps
    .ignoresSafeArea(edges: .horizontal)
}
```

### Stats redesign
Replace the 6-chip `timeRow` grid with:
```swift
private var narrativeStatsSection: some View {
    VStack(alignment: .leading, spacing: 6) {
        Text("\(night.totalDuration) across \(night.totalStopsCount) spots")
            .font(.custom("Caveat-SemiBold", size: 22))
            .foregroundColor(.textPrimary)
        
        if let mood = night.mood {
            Text(mood)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.accentOrangeSoft)
                .clipShape(Capsule())
        }
        
        let km = String(format: "%.1f", Double(night.totalSteps) * 0.00075)
        let kcal = Int(Double(night.totalSteps) * 0.035)
        Text("\(night.totalSteps.formatted()) steps  ·  \(km) km  ·  \(kcal) kcal")
            .font(.system(size: 13))
            .foregroundColor(.textSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.top, 16)
}
```

### Fix bookmark button
```swift
@AppStorage("savedRecapIds") private var savedRecapIdsRaw = ""

private var savedRecapIds: Set<String> {
    get { Set(savedRecapIdsRaw.split(separator: ",").map(String.init)) }
}

// In bookmark button action:
var ids = savedRecapIds
if ids.contains(night.nightId) {
    ids.remove(night.nightId)
} else {
    ids.insert(night.nightId)
    UINotificationFeedbackGenerator().notificationOccurred(.success)
}
savedRecapIdsRaw = ids.joined(separator: ",")
```
Bookmark icon: `bookmark.fill` when saved, `bookmark` when not. Color: accentOrange when saved.

### Heart button animation
```swift
@State private var heartScale: CGFloat = 1.0

// On tap:
withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { heartScale = 1.35 }
DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { heartScale = 1.0 }
}
UIImpactFeedbackGenerator(style: .medium).impactOccurred()

// Applied: .scaleEffect(heartScale) on the heart icon
```

### Locations section
- Title: `"Where you went"` (was "Places")
- Remove "Tap to edit name" hint
- Add timeline connector: a 2pt vertical accentOrange line running down the left side of the stop list. Implement as a `Rectangle()` overlay on a `ZStack` wrapping the `ForEach`.
- Location row tap flash: use `.onTapGesture` on the edit button to briefly change the row background to accentOrangeSoft (0.15s) then back — implement with `@State var flashedStopId: String?` and a `DispatchQueue.main.asyncAfter(deadline: .now() + 0.15)` reset.
- Emoji button: make it open `EmojiPickerSheet` (new file — see Step 12)

### Photos section
Replace the horizontal strip with a 2-column masonry layout:
```swift
LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
    ForEach(Array(night.photos.enumerated()), id: \.element.id) { idx, photo in
        RecapPhotoView(photo: photo)
            .frame(height: idx % 3 == 0 ? 180 : 130)  // stagger heights
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture { photoViewerIndex = idx; showPhotoViewer = true }
    }
}
.padding(.horizontal, 16)
```

### Share button
Remove the large footer Share button. It's now in the toolbar `...` menu.

---

## Step 7 — Feed (FeedView.swift)

### Stories row (new — StoriesRowView.swift)
Create `StoriesRowView.swift`:
```swift
struct StoriesRowView: View {
    let profiles: [ProfileUser]
    @State private var selectedProfile: ProfileUser? = nil
    @State private var showStory = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                // "You" bubble first
                VStack(spacing: 4) {
                    ZStack {
                        Circle().stroke(Color.accentOrange, lineWidth: 2).frame(width: 44, height: 44)
                        Circle().fill(Color.accentOrangeSoft).frame(width: 40, height: 40)
                        Image(systemName: "plus").font(.system(size: 16, weight: .bold)).foregroundColor(.accentOrange)
                    }
                    Text("You").font(.system(size: 9, weight: .semibold)).foregroundColor(.textMuted)
                }
                
                ForEach(profiles) { profile in
                    VStack(spacing: 4) {
                        Button {
                            selectedProfile = profile
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { showStory = true }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(Color.accentOrange, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                                Circle()
                                    .fill(Color(hex: profile.avatarHex).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Text(profile.displayName.prefix(2).uppercased())
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(Color(hex: profile.avatarHex))
                            }
                        }
                        .scaleEffect(1.0)
                        Text(profile.username)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.textMuted)
                            .lineLimit(1)
                    }
                    .frame(width: 48)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 80)
        .fullScreenCover(isPresented: $showStory) {
            if let profile = selectedProfile {
                StoryPreviewSheet(profile: profile, isPresented: $showStory)
            }
        }
    }
}
```

Create `StoryPreviewSheet.swift` — a full-screen dark view showing the profile's most recent recap:
- Background: `Color.black.ignoresSafeArea()`
- Center: Recap title in Caveat font size 44, white
- Below: `"\(recap.totalStopsCount) spots · \(recap.dateString)"` in white, opacity 0.7
- Close: swipe down (use `.presentationDragIndicator(.visible)`) or tap X button top-right
- Transition: `.sheet` is fine — SwiftUI handles the slide-up

### Filter chips row (new)
Below stories row, above feed cards:
```swift
struct FeedFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: { action(); UIImpactFeedbackGenerator(style: .light).impactOccurred() }) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? Color.accentOrange : Color.bgCard)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.clear : Color.borderCard, lineWidth: 1))
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}
```
Filters: ["All", "Friends", "Popular", "Nearby"] — filter `displayPosts` based on selection (mock filtering: "Popular" sorts by likes descending, others show all for now).

### FeedCard redesign

**Header:**
- Move share icon → inside a `Menu` with `...` (ellipsis) icon top-right
- Below username: if post has mood, show `Text(mood).font(.system(size: 11)).padding(4).background(accentOrangeSoft).clipShape(Capsule())`

**Cover image:**
- Height: 240pt (was 180)
- Full-bleed: remove horizontal padding inside card
- Title overlay at bottom: `ZStack(alignment: .bottomLeading)` with gradient scrim + Caveat font size 22 white title
- Multiple photos badge: if `post.nightData?.photos.count ?? 0 > 1`, show `"\(count) photos"` pill bottom-right of image
- Double-tap to fire: add `TapGesture(count: 2)` on the cover area → like action + flame emoji appear-and-fade animation at tap location + haptic

**Stats line:**
- Remove `Text(post.nightTitle)` — it's now on the photo
- Remove all chips — replace with: `"\(post.stopsCount) spots · \(km) km"` size 12, textSecondary
- Date: `"Last Friday · Apr 19"` — compute relative prefix

**Reactions row:**
- Like: change to flame icon `flame.fill` / `flame`
- Like color when active: `.accentOrange`
- Like animation: scale 1.0 → 1.4 → 1.0 spring, haptic medium
- Add Kudos button: `sun.max` / `sun.max.fill` icon, same animation pattern, accentYellow color when active
- Add `var kudosCount: Int = 0` and `var isKudosed: Bool = false` to `FeedPost`
- Comment count: `post.commentsCount + post.commentList.count`
- Show up to 2 inline comments (was 1)
- If more than 2: `Text("View all \(total) comments").font(.system(size: 12)).foregroundColor(.textMuted)`

**Tagged friends:**
- Icon: `at` (was `person.2.fill`)
- Format: `"with @\(friends.joined(separator: " and @"))"`

**Skeleton loading:**
```swift
struct SkeletonFeedCard: View {
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.bgCard)
            .frame(height: 320)
            .overlay(
                LinearGradient(colors: [Color.clear, Color.white.opacity(0.4), Color.clear],
                               startPoint: .leading, endPoint: .trailing)
                    .offset(x: shimmerOffset)
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: shimmerOffset)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .onAppear { shimmerOffset = 400 }
    }
}
```
Show 3 `SkeletonFeedCard` when `isRefreshing` is true.

**Empty feed state:**
```swift
VStack(spacing: 12) {
    Text("🌙").font(.system(size: 48))
    Text("Nothing here yet")
        .font(.system(size: 18, weight: .black)).foregroundColor(.textPrimary)
    Text("Follow some friends to see their nights out.")
        .font(.system(size: 14)).foregroundColor(.textSecondary).multilineTextAlignment(.center)
    Button("Find friends") { /* switch to Explore tab */ }
        .font(.system(size: 14, weight: .bold)).foregroundColor(.accentOrange)
}
.padding(.vertical, 60).padding(.horizontal, 40)
```

**scrollTransition on cards:**
```swift
FeedCardWrapper(...)
    .scrollTransition { content, phase in
        content
            .opacity(phase.isIdentity ? 1 : max(0.6, 1 - abs(phase.value) * 0.4))
            .scaleEffect(phase.isIdentity ? 1 : max(0.96, 1 - abs(phase.value) * 0.04))
    }
```

---

## Step 8 — Explore Tab (ExploreView.swift — was SearchPeopleView.swift)

Rename `SearchPeopleView` to `ExploreView`. Keep all existing search logic. Add:

### Segmented search mode
Below search bar:
```swift
Picker("", selection: $searchMode) {
    Text("People").tag(0)
    Text("Places").tag(1)
}
.pickerStyle(.segmented)
.padding(.horizontal, 20)
.padding(.bottom, 8)
```

When `searchMode == 1` and query not empty: filter stop names from `mockNights` + `mockFeedPosts.compactMap(\.nightData)`.

### Discovery sections (when query is empty)
Section 1 — "Trending places":
```swift
Text("Trending this week")
    .font(.system(size: 13, weight: .bold)).foregroundColor(.textMuted)
    .padding(.horizontal, 20)

ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 12) {
        ForEach(trendingPlaces) { place in
            VStack(alignment: .leading, spacing: 6) {
                Text(place.emoji).font(.system(size: 24))
                Text(place.name).font(.system(size: 13, weight: .bold)).foregroundColor(.textPrimary).lineLimit(1)
                Text("\(place.count) recaps").font(.system(size: 11)).foregroundColor(.textMuted)
            }
            .padding(12)
            .frame(width: 130, height: 90)
            .background(Color.bgCard)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderCard, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    .padding(.horizontal, 20)
}
```
Seed with 5 mock places (e.g., `TrendingPlace(emoji: "🍕", name: "Pizzeria Roma", count: 14)`).

Section 2 — "People you might know": existing `PersonRow` list from `mockFeedProfiles`.

Section 3 — "Hot right now": show 2 compact feed cards from `mockFeedPosts`.

### PersonRow follow animation
```swift
@State private var isFollowing: Bool
@State private var followScale: CGFloat = 1.0

// On follow tap:
withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { followScale = 0.92 }
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { followScale = 1.0 }
    isFollowing.toggle()
}
UIImpactFeedbackGenerator(style: .medium).impactOccurred()

// Applied: .scaleEffect(followScale) on the follow button
```

---

## Step 9 — Activity Tab (ActivityView.swift — new file)

```swift
import SwiftUI

struct AppNotification: Identifiable {
    let id = UUID()
    let kind: NotificationKind
    let timeAgo: String
    var isRead: Bool
}

enum NotificationKind {
    case like(from: String, avatarHex: String, recapTitle: String)
    case comment(from: String, avatarHex: String, recapTitle: String, preview: String)
    case follow(from: String, avatarHex: String)
    case kudos(from: String, avatarHex: String, recapTitle: String)
    case recapReady(title: String, stops: Int)
    case milestone(description: String)
}
```

Seed with these mock notifications:
```swift
let mockNotifications: [AppNotification] = [
    AppNotification(kind: .like(from: "Sophie K.", avatarHex: "#EA5A8A", recapTitle: "Friday Vibes"), timeAgo: "1h ago", isRead: false),
    AppNotification(kind: .comment(from: "Marc B.", avatarHex: "#3FA9F5", recapTitle: "Rooftop Session", preview: "Classic night!"), timeAgo: "3h ago", isRead: false),
    AppNotification(kind: .follow(from: "Tim N.", avatarHex: "#9B7EDE"), timeAgo: "Yesterday", isRead: true),
    AppNotification(kind: .recapReady(title: "Wednesday Wind-down", stops: 3), timeAgo: "2d ago", isRead: true),
    AppNotification(kind: .milestone(description: "You've logged 5 recaps! Keep it up 🎉"), timeAgo: "3d ago", isRead: true),
]
```

Layout per row:
```
[avatar 36pt] [main text bold name + action text]  [timestamp]
              [secondary: recap title in textMuted]  [● unread dot]
```

Row tap: brief accentOrangeSoft background flash (0.15s) before navigating. Unread dot: 6pt filled orange circle on leading edge.

Section grouping: "Today" (< 24h), "This week" (older). Section headers: size 13, bold, textMuted, padding horizontal 20.

"Mark all read" button: top-right, only visible when any notification is unread. On tap: set all `isRead = true` + clear `unreadNotifications` AppStorage.

On tab appear: `unreadNotifications = 0`.

Empty state: `Text("🌙")` size 48 + `"All quiet. Go out and make some noise."` size 15, textMuted, centered.

---

## Step 10 — Profile Tab (ProfileView.swift)

### Own profile top bar
- Remove `person` icon → replace with `gearshape` NavigationLink to `SettingsView()`
- Add `square.and.arrow.up` icon for ShareLink of profile

### Stats row
Add 4th stat "Places":
```swift
let uniquePlaces = Set(profile.recaps.flatMap { $0.stops.map(\.stopName) }).count
statPill(value: uniquePlaces, label: "Places")
```
Make each stat tappable: Posts taps scroll to grid (use `ScrollViewProxy`). Followers/Following: open placeholder `FollowListSheet(title:users:)`.

### Bio section additions
```swift
if !profile.homeAddress.isEmpty {
    Label(profile.homeAddress, systemImage: "mappin")
        .font(.system(size: 13)).foregroundColor(.textSecondary)
}
Text("Member since March 2025")
    .font(.system(size: 13)).foregroundColor(.textMuted)
```

### Segmented grid toggle
```swift
@State private var profileTab = 0

Picker("", selection: $profileTab) {
    Text("Recaps").tag(0)
    Text("Places").tag(1)
    Text("Stats").tag(2)
}
.pickerStyle(.segmented)
.padding(.horizontal, 20).padding(.vertical, 10)
```

- Tab 0: existing `LazyVGrid` recap grid (keep as-is)
- Tab 1: `Map` showing all stop pins from all recaps, clustered — `MapClusterAnnotation` grouping by proximity
- Tab 2: stats card:
  ```
  Total recaps: X
  Total km: X.X
  Total spots visited: X
  Avg session: Xh Xm
  Most visited: [stop name]
  Busiest day: [weekday]
  ```
  All computed from `profile.recaps`.

Grid cell long press context menu:
```swift
.contextMenu {
    Button("Share") { }
    Button("Rename") { }
    Button("Delete", role: .destructive) { }
}
```

### "Complete your profile" banner
```swift
@AppStorage("profileBannerDismissed") private var bannerDismissed = false
@AppStorage("displayName") private var displayName = ""

// Show if displayName is empty and banner not dismissed:
if !displayName.isEmpty == false && !bannerDismissed {
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your profile is 60% complete")
                .font(.system(size: 13, weight: .bold)).foregroundColor(.textPrimary)
            ProgressView(value: 0.6)
                .tint(.accentOrange)
                .frame(width: 160)
        }
        Spacer()
        Button("Finish →") { /* push to CompleteProfileView */ }
            .font(.system(size: 13, weight: .bold)).foregroundColor(.accentOrange)
        Button { bannerDismissed = true } label: {
            Image(systemName: "xmark").font(.system(size: 12)).foregroundColor(.textMuted)
        }
    }
    .padding(14)
    .background(Color.accentOrangeSoft)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding(.horizontal, 20)
}
```

### Other profile: Message button
```swift
// Was: Button {} label: { Text("Message") }
// Now:
NavigationLink(destination: DirectMessageView(profile: profile)) {
    Text("Message")
        ...
}
```

---

## Step 11 — Onboarding (OnboardingView.swift)

Completely replace the form-first flow with a 3-step flow:

### Step 0 — Value slides (new)
```swift
@State private var valueStep = 0

let slides = [
    ("Track where you go", "Start a recap when you leave, end it when you're home.", Color.accentOrangeSoft),
    ("Share the good parts", "Pick your best photos, add a caption, share with friends.", Color.accentPinkSoft),
    ("Look back anytime", "Your history, your places, your memories.", Color.accentBlueSoft),
]
```
Display using `TabView` with `.tabViewStyle(.page)` and `.indexViewStyle(.page(backgroundDisplayMode: .always))`. 
Last slide: show "Get started" button (primary style) → moves to step 1.
All slides: show "Explore the app first" as a plain text link at bottom → `skipToDemo()`.

### Step 1 — Account basics (new, replaces entire old form)
Only two fields:
- Display name (TextField)
- Username (TextField, no spaces, lowercase enforced)

"Why?" explainer below username: `"Your username is how friends find you."` — size 12, textMuted.

"Continue" button: requires both fields non-empty. On tap → move to step 2 (permissions).

Save: `UserDefaults.standard.set(displayName, forKey: "displayName")` + `UserDefaults.standard.set(username, forKey: "username")`.

### Step 2 — Permissions (improved existing)
Title: `"Two quick permissions"`
Replace spinner with two permission rows that check off:
```swift
struct PermissionRow: View {
    let emoji: String
    let title: String  
    let subtitle: String
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Text(emoji).font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(.textPrimary)
                Text(subtitle).font(.system(size: 12)).foregroundColor(.textSecondary)
            }
            Spacer()
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(isGranted ? .accentGreen : .borderCard)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isGranted)
        }
        .padding(16)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

Move all the old form fields (birth date, country, gender, TOS) OUT of onboarding. They go into `CompleteProfileView.swift` which is shown from the Profile tab banner.

---

## Step 12 — New supporting files

### MilestoneToastView.swift
```swift
struct MilestoneToastView: View {
    let emoji: String
    let title: String
    let subtitle: String
    var onDismiss: () -> Void
    
    @State private var offset: CGFloat = 120
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: 14) {
            Text(emoji).font(.system(size: 32))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .black)).foregroundColor(.textPrimary)
                Text(subtitle).font(.system(size: 13)).foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(18)
        .background(Color.accentOrangeSoft)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.accentOrange.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.1), radius: 16, y: 8)
        .padding(.horizontal, 20)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                offset = 0; opacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    offset = 120; opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onDismiss() }
            }
        }
        .onTapGesture { onDismiss() }
    }
}
```

### FavoritePlacesView.swift
```swift
struct FavoritePlacesView: View {
    @State private var places = FavoritePlaceStore.load()
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                // Map at top
                Map {
                    ForEach(places) { place in
                        Annotation(place.name, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)) {
                            ZStack {
                                Circle().fill(Color.bgCard).frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(Color.accentPink, lineWidth: 2))
                                Image(systemName: "heart.fill").font(.system(size: 14)).foregroundColor(.accentPink)
                            }
                        }
                    }
                }
                .frame(height: 200)
                
                // List
                List {
                    ForEach(places) { place in
                        HStack {
                            Text("❤️").font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(place.name).font(.system(size: 15, weight: .bold)).foregroundColor(.textPrimary)
                                Text("Tap to open in Maps").font(.system(size: 12)).foregroundColor(.textMuted)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let url = URL(string: "maps://?q=\(place.latitude),\(place.longitude)")!
                            UIApplication.shared.open(url)
                        }
                    }
                    .onDelete { idx in
                        places.remove(atOffsets: idx)
                        FavoritePlaceStore.save(places)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Your places")
        .navigationBarTitleDisplayMode(.large)
    }
}
```

### DirectMessageView.swift
```swift
struct DirectMessageView: View {
    let profile: ProfileUser
    @State private var messages: [DMMessage] = [
        DMMessage(text: "that recap was wild lol 😂", isOwn: false, timeAgo: "2d ago"),
        DMMessage(text: "haha right! we should do it again", isOwn: true, timeAgo: "2d ago"),
    ]
    @State private var inputText = ""
    @FocusState private var focused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in
                            DMBubble(message: msg)
                                .id(msg.id)
                                .transition(.asymmetric(insertion: .push(from: .bottom), removal: .opacity))
                        }
                    }
                    .padding(16)
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation { proxy.scrollTo(messages.last?.id) }
                }
            }
            
            Divider()
            
            HStack(spacing: 10) {
                TextField("Message...", text: $inputText)
                    .focused($focused)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Button {
                    guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        messages.append(DMMessage(text: inputText, isOwn: true, timeAgo: "Just now"))
                    }
                    inputText = ""
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.accentOrange)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .navigationTitle("@\(profile.username)")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.bgPrimary.ignoresSafeArea())
    }
}

struct DMMessage: Identifiable {
    let id = UUID()
    let text: String
    let isOwn: Bool
    let timeAgo: String
}

struct DMBubble: View {
    let message: DMMessage
    
    var body: some View {
        HStack {
            if message.isOwn { Spacer() }
            Text(message.text)
                .font(.system(size: 15))
                .foregroundColor(message.isOwn ? .white : .textPrimary)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(message.isOwn ? Color.accentOrange : Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            if !message.isOwn { Spacer() }
        }
    }
}
```

### EmojiPickerSheet.swift
```swift
struct EmojiPickerSheet: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    let emojis = ["🍕","🍺","☕","🍸","🌙","🎵","🎮","🛍️","🌳","🏖️",
                  "🍜","🎭","🏋️","📚","🎨","🍣","🥂","🎪","🌆","🏠"]
    
    var body: some View {
        NavigationStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(emojis, id: \.self) { emoji in
                    Button {
                        onSelect(emoji)
                        dismiss()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(emoji).font(.system(size: 32))
                            .frame(width: 56, height: 56)
                            .background(Color.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(20)
            .navigationTitle("Pick an icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.accentOrange)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
```

### CompleteProfileView.swift
Reuse all the form fields from the old `OnboardingView` (birth date, country, gender, TOS). Present as a `NavigationStack` sheet from the Profile banner's "Finish →" button. On save: write to `@AppStorage` keys and dismiss.

---

## Step 13 — Settings (SettingsView.swift)

- Access: only from Profile tab gear icon — remove all other entry points
- Add profile photo section at top (avatar 80pt + "Edit photo" link → `EditProfileView`)
- Admin section: remove from the visible list. Keep `AdminView` reachable via triple-tap on the footer version label (use `TapGesture(count: 3)`)
- "Sign Out" → `"Log out"`
- Add Appearance section: single row "Appearance" with `Text("Coming soon").foregroundColor(.textMuted)` as trailing detail
- Footer: `"Recapp v1.0 · Made with ♥"` — add `.onTapGesture(count: 3) { showAdmin = true }` here

---

## Step 14 — Language fixes (grep and replace everywhere)

Do a complete pass on ALL Swift files:

```
"JJJJ"         → "YYYY"
"Maand"         → "Month"  
"stappen"       → "steps"
"Jij"           → "You"
"Gemaakt met Recap" → "Made with Recapp"
"Recap · v1.0"  → handled in Settings
"Recording for" → "Out for"
"Now at:"       → "Currently at"
"End Recap"     → "Finish & Save"
"Start New Recap" → "Start Recap"
"Previous Recaps" → "Your recaps"
"Give this recap a new name." → "What should we call this one?"
"Correct the location name:" → "Fix the name"
"No internet connection" → "You're offline"
"Back online"   → "Back online ✓"
"Edit Profile"  → "Edit profile"
"Posts" (profile stat) → "Recaps"
"Tap to edit name" → remove entirely
"Relive your memories" → "Free · No algorithm · Just yours"
"No recaps yet" → "Nothing here yet"
"Tap Start to record your first evening out." → "Tap the button above next time you head out."
"Suggestions"  → "People you might know"
```

---

## Step 15 — Micro-interactions pass (final, apply everywhere)

Go through every interactive element in the app and ensure:

**Primary buttons** (filled, full-width):
```swift
@State private var isPressed = false

// modifier:
.scaleEffect(isPressed ? 0.96 : 1.0)
.animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
.simultaneousGesture(DragGesture(minimumDistance: 0)
    .onChanged { _ in isPressed = true }
    .onEnded { _ in isPressed = false }
)
```

**Feed scroll entrance**: already added in Step 7 via `scrollTransition`.

**Notification rows**: tap flash via `@State var flashedId: UUID?` — set on tap, clear after 0.15s, use in background modifier.

**Photo selection ring** (RecapSummarySheet): 
```swift
.overlay(
    RoundedRectangle(cornerRadius: 12)
        .stroke(isSelected ? Color.accentOrange : Color.clear, lineWidth: 2)
        .scaleEffect(isSelected ? 1.0 : 0.9)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
)
```

**Mood chip selection**: `scaleEffect(selectedMood == mood ? 1.06 : 1.0)` with `.animation(.spring(response: 0.25, dampingFraction: 0.7), value: selectedMood)`.

---

## Step 16 — Commit strategy

Commit after each step is complete with a clear message:
```
Step 2: dynamic dark mode color system
Step 3: 5-tab navigation + welcome screen updates
Step 4: Dashboard redesign + RecapCard
Step 5: RecapSummarySheet + celebration + mood picker
Step 6: NightDetailView — map at top, narrative stats, fixed bookmark
Step 7: Feed redesign — stories, filter chips, flame reactions
Step 8: ExploreView — expanded from SearchPeopleView
Step 9: ActivityView — notifications tab
Step 10: ProfileView — segmented grid, DM wiring, profile banner
Step 11: Onboarding — 3-step value-first flow
Step 12: New supporting files (Toast, Places, DM, Emoji, CompleteProfile)
Step 13: Settings cleanup
Step 14: Language fixes — full English pass
Step 15: Micro-interactions — final pass
```

---

## What NOT to touch

- `ScatteredDeckPreview` — perfect, leave it
- `RecapShareCard` — leave it
- `SupabaseManager` — leave it
- `LocationManager` — leave it  
- `NotificationManager` — leave it
- `NetworkMonitor` + `AnimatedOfflineBanner` — leave it
- `FavoritePlaceStore` — leave it
- Caveat font files — leave them

---

Start with Step 1. Go through every step in order. Do not ask questions. Do not skip steps. When a step is done, commit it and move to the next.
