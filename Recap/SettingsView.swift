// SettingsView.swift – Profile editing + home address

import SwiftUI
import UserNotifications

private let settingsMonths = [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December",
]

struct SettingsView: View {
    @AppStorage("displayName")    private var storedDisplayName = ""
    @AppStorage("profileDay")     private var storedDay         = ""
    @AppStorage("profileMonth")   private var storedMonth       = ""
    @AppStorage("profileYear")    private var storedYear        = ""
    @AppStorage("profileCountry") private var storedCountry     = ""
    @AppStorage("profileGender")  private var storedGender      = ""

    @State private var editDisplayName = ""
    @State private var editDay     = ""
    @State private var editMonth   = ""
    @State private var editYear    = ""
    @State private var editCountry = ""
    @State private var editGender  = ""
    @State private var profileSaved  = false
    @State private var profileExpanded = false

    @AppStorage("homeStreet")  private var storedStreet       = ""
    @AppStorage("homeCity")    private var storedCity         = ""
    @AppStorage("homePostal")  private var storedPostal       = ""
    @AppStorage("homeCountry") private var storedAddrCountry  = ""

    @State private var street       = ""
    @State private var city         = ""
    @State private var postal       = ""
    @State private var addrCountry  = ""
    @State private var addressSaved  = false
    @State private var addressExpanded = false

    @StateObject private var notifications = NotificationManager.shared
    @AppStorage("notifWeekly") private var notifWeekly = true

    @State private var privacyExpanded     = false
    @State private var showMonthPicker     = false
    @State private var showCountryPicker   = false
    @State private var countrySearch       = ""
    @State private var showDeleteConfirm   = false
    @State private var showDataExportInfo  = false

    private var canSaveAddress: Bool {
        !street.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var profileSummary: String {
        var parts: [String] = []
        if !storedDisplayName.isEmpty { parts.append(storedDisplayName) }
        if !storedGender.isEmpty      { parts.append(storedGender) }
        if !storedCountry.isEmpty     { parts.append(storedCountry) }
        if !storedYear.isEmpty        { parts.append(storedYear) }
        return parts.isEmpty ? "Not set yet" : parts.joined(separator: " · ")
    }

    private var addressSummary: String {
        if !storedCity.isEmpty { return storedCity }
        return "Not set yet"
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    profileSection
                    addressSection
                    notificationsSection
                    gdprSection
                    adminSection
                    footerView
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadValues)
        .sheet(isPresented: $showMonthPicker) { monthSheet }
        .sheet(isPresented: $showCountryPicker) { countrySheet }
        .alert("Delete All Data", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your local data and sign you out. This cannot be undone.")
        }
        .alert("Data Export", isPresented: $showDataExportInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("To request a full export of your data, email us at privacy@recapapp.io with the subject \"Data Export Request\". We will respond within 30 days as required by GDPR.")
        }
    }

    // MARK: – Profile section

    private var profileSection: some View {
        sectionCard {
            // Header / collapsed strip
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    profileExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person")
                        .font(.system(size: 15))
                        .foregroundColor(.accentOrange)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Profile")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.textPrimary)
                        if !profileExpanded {
                            Text(profileSummary)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textMuted)
                        }
                    }
                    Spacer()
                    Image(systemName: profileExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textMuted)
                }
            }
            .buttonStyle(.plain)

            if profileExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider().padding(.vertical, 14)

                    fieldLabel("Display Name")
                    TextField("", text: $editDisplayName,
                              prompt: Text("Your name").foregroundColor(.textMuted))
                        .settingsStyle()
                        .padding(.bottom, 14)

                    fieldLabel("Date of Birth")
                    HStack(spacing: 8) {
                        TextField("DD", text: $editDay)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 54)
                            .settingsStyle()
                            .onChange(of: editDay) { _, v in editDay = String(v.filter(\.isNumber).prefix(2)) }

                        Button { showMonthPicker = true } label: {
                            HStack {
                                Text(editMonth.isEmpty ? "Month" : editMonth)
                                    .foregroundColor(editMonth.isEmpty ? .textMuted : .textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.textMuted)
                                    .font(.system(size: 11))
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(Color.bgCard)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderInput, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        TextField("YYYY", text: $editYear)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 72)
                            .settingsStyle()
                            .onChange(of: editYear) { _, v in editYear = String(v.filter(\.isNumber).prefix(4)) }
                    }
                    .padding(.bottom, 14)

                    fieldLabel("Country of Origin")
                    Button { showCountryPicker = true } label: {
                        HStack {
                            Text(editCountry.isEmpty ? "Select country" : editCountry)
                                .foregroundColor(editCountry.isEmpty ? .textMuted : .textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.textMuted)
                                .font(.system(size: 13))
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderInput, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.bottom, 14)

                    fieldLabel("Gender")
                    HStack(spacing: 8) {
                        ForEach(["Male","Female","Other"], id: \.self) { g in
                            Button { editGender = g } label: {
                                Text(g)
                                    .font(.system(size: 14, weight: editGender == g ? .bold : .semibold))
                                    .foregroundColor(editGender == g ? .accentOrange : .textMuted)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(editGender == g ? Color.accentOrangeSoft : Color.bgCard)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(editGender == g ? Color.accentOrange : Color.borderInput, lineWidth: 1.5)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.bottom, 14)

                    Button(action: saveProfile) {
                        Text(profileSaved ? "Saved ✓" : "Save Profile")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(Color(hex: "#FFFDF7"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.accentOrange)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }

    // MARK: – Address section

    private var addressSection: some View {
        sectionCard {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    addressExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.accentGreen)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Home Location")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.textPrimary)
                        if !addressExpanded {
                            Text(addressSummary)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textMuted)
                        }
                    }
                    Spacer()
                    Image(systemName: addressExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textMuted)
                }
            }
            .buttonStyle(.plain)

            if addressExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider().padding(.vertical, 14)

                    Text("Lets Recap show \"Home Sweet Home\" on your timeline.")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                        .padding(.bottom, 14)

                    fieldLabel("Street")
                    TextField("123 Main Street", text: $street)
                        .settingsStyle()
                        .padding(.bottom, 14)

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 0) {
                            fieldLabel("City")
                            TextField("Berlin", text: $city)
                                .settingsStyle()
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            fieldLabel("Postal Code")
                            TextField("10115", text: $postal)
                                .settingsStyle()
                                .frame(width: 110)
                        }
                    }
                    .padding(.bottom, 14)

                    fieldLabel("Country")
                    TextField("Germany", text: $addrCountry)
                        .settingsStyle()
                        .padding(.bottom, 14)

                    HStack(spacing: 10) {
                        Button(action: saveAddress) {
                            Text(addressSaved ? "Saved ✓" : "Save Address")
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(Color(hex: "#FFFDF7"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(canSaveAddress ? Color.accentOrange : Color.accentOrange.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!canSaveAddress)

                        if !street.isEmpty || !city.isEmpty {
                            Button(action: clearAddress) {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                    .foregroundColor(.accentPink)
                                    .frame(width: 46, height: 46)
                                    .background(Color.accentPinkSoft)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentPink.opacity(0.3), lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: – Notifications section

    private var notificationsSection: some View {
        sectionCard {
            sectionHeader(icon: "bell.fill", color: .accentOrange, title: "Notifications")

            if notifications.authStatus == .denied {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.accentOrange)
                        .font(.system(size: 13))
                    Text("Notifications are disabled. Enable them in Settings.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSecondary)
                }
                .padding(.bottom, 12)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.accentOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.accentOrangeSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Toggle(isOn: $notifWeekly) {
                    Text("Weekend reminders")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textPrimary)
                }
                .tint(.accentOrange)
                .onChange(of: notifWeekly) { _, on in
                    if on { NotificationManager.shared.scheduleWeeklyReminders() }
                    else  { NotificationManager.shared.cancelWeeklyReminders() }
                }
            }
        }
    }

    // MARK: – GDPR section

    private var gdprSection: some View {
        sectionCard {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    privacyExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#7B5EA7"))
                        .frame(width: 22)
                    Text("Privacy & Data")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: privacyExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textMuted)
                }
            }
            .buttonStyle(.plain)

            if privacyExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider().padding(.vertical, 12)
                    NavigationLink(destination: PrivacyPolicyView()) {
                        gdprRow(icon: "doc.text", label: "Privacy Policy")
                    }
                    Divider().padding(.vertical, 4)
                    NavigationLink(destination: TermsView()) {
                        gdprRow(icon: "doc.plaintext", label: "Terms & Conditions")
                    }
                    Divider().padding(.vertical, 4)
                    Button { showDataExportInfo = true } label: {
                        gdprRow(icon: "square.and.arrow.up", label: "Request Data Export")
                    }
                    Divider().padding(.vertical, 4)
                    Button { showDeleteConfirm = true } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.accentPink)
                            Text("Delete All My Data")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.accentPink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.accentPink.opacity(0.5))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func gdprRow(icon: String, label: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(.textMuted)
        }
        .padding(.vertical, 4)
    }

    // MARK: – Admin section

    private var adminSection: some View {
        sectionCard {
            sectionHeader(icon: "lock.fill", color: .accentOrange, title: "Admin")

            NavigationLink(destination: AdminView()) {
                HStack {
                    Text("View Admin Dashboard")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                }
                .padding(.vertical, 4)
            }
            .padding(.bottom, 12)

            Button {
                UserDefaults.standard.set(false, forKey: "onboardingComplete")
            } label: {
                Text("Sign Out")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.accentPink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.accentPinkSoft)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentPink.opacity(0.3), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: – Footer

    private var footerView: some View {
        VStack(spacing: 4) {
            Text("Recap · v1.0")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.textSecondary)
            Text("Relive your memories")
                .font(.system(size: 11))
                .foregroundColor(.textMuted)
        }
        .padding(.vertical, 20)
    }

    // MARK: – Sheets

    private var monthSheet: some View {
        NavigationStack {
            List {
                ForEach(settingsMonths, id: \.self) { m in
                    Button {
                        editMonth = m; showMonthPicker = false
                    } label: {
                        HStack {
                            Text(m).foregroundColor(editMonth == m ? .accentOrange : .textPrimary)
                            Spacer()
                            if editMonth == m { Image(systemName: "checkmark").foregroundColor(.accentOrange) }
                        }
                    }
                }
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { showMonthPicker = false }.foregroundColor(.accentOrange)
            }}
        }
        .presentationDetents([.medium])
    }

    private var countrySheet: some View {
        NavigationStack {
            List {
                ForEach(filteredSettingsCountries, id: \.self) { c in
                    Button {
                        editCountry = c; showCountryPicker = false; countrySearch = ""
                    } label: {
                        HStack {
                            Text(c).foregroundColor(editCountry == c ? .accentOrange : .textPrimary)
                            Spacer()
                            if editCountry == c { Image(systemName: "checkmark").foregroundColor(.accentOrange) }
                        }
                    }
                }
            }
            .searchable(text: $countrySearch, prompt: "Search countries…")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { showCountryPicker = false; countrySearch = "" }.foregroundColor(.accentOrange)
            }}
        }
        .presentationDetents([.large])
    }

    private var filteredSettingsCountries: [String] {
        countrySearch.isEmpty ? allSettingsCountries
            : allSettingsCountries.filter { $0.localizedCaseInsensitiveContains(countrySearch) }
    }

    // MARK: – Actions

    private func loadValues() {
        editDisplayName = storedDisplayName
        editDay = storedDay; editMonth = storedMonth; editYear = storedYear
        editCountry = storedCountry; editGender = storedGender
        street = storedStreet; city = storedCity; postal = storedPostal; addrCountry = storedAddrCountry
        // Collapse if already filled in
        profileExpanded = storedDisplayName.isEmpty && storedGender.isEmpty && storedCountry.isEmpty && storedYear.isEmpty
        addressExpanded = storedCity.isEmpty && storedStreet.isEmpty
    }

    private func saveProfile() {
        storedDisplayName = editDisplayName.trimmingCharacters(in: .whitespaces)
        storedDay = editDay; storedMonth = editMonth; storedYear = editYear
        storedCountry = editCountry; storedGender = editGender
        profileSaved = true
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { profileExpanded = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { profileSaved = false }
    }

    private func saveAddress() {
        storedStreet      = street.trimmingCharacters(in: .whitespaces)
        storedCity        = city.trimmingCharacters(in: .whitespaces)
        storedPostal      = postal.trimmingCharacters(in: .whitespaces)
        storedAddrCountry = addrCountry.trimmingCharacters(in: .whitespaces)
        addressSaved = true
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { addressExpanded = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { addressSaved = false }
    }

    private func clearAddress() {
        street = ""; city = ""; postal = ""; addrCountry = ""
        storedStreet = ""; storedCity = ""; storedPostal = ""; storedAddrCountry = ""
    }

    private func deleteAllData() {
        let keys = [
            "displayName",
            "profileDay","profileMonth","profileYear","profileCountry","profileGender",
            "homeStreet","homeCity","homePostal","homeCountry",
            "notifWeekly","onboardingComplete",
            "sessionActive","sessionStartTimestamp",
            "sb_token","sb_uid","sb_email",
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: – Helpers

    @ViewBuilder
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
        .padding(18)
        .background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.borderCard, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private func sectionHeader(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 17, weight: .black))
                .foregroundColor(.textPrimary)
        }
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(0.5)
            .textCase(.uppercase)
            .foregroundColor(.textSecondary)
            .padding(.bottom, 6)
    }
}

private extension View {
    func settingsStyle() -> some View {
        self
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.textPrimary)
            .tint(.accentOrange)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.bgCard)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderInput, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private let allSettingsCountries = [
    "Afghanistan","Albania","Algeria","Andorra","Angola","Argentina","Armenia",
    "Australia","Austria","Azerbaijan","Bahamas","Bahrain","Bangladesh","Barbados",
    "Belarus","Belgium","Belize","Bolivia","Bosnia and Herzegovina","Brazil","Bulgaria",
    "Cambodia","Canada","Chile","China","Colombia","Costa Rica","Croatia","Cuba",
    "Cyprus","Czech Republic","Denmark","Ecuador","Egypt","Estonia","Ethiopia",
    "Fiji","Finland","France","Georgia","Germany","Ghana","Greece","Guatemala",
    "Hungary","Iceland","India","Indonesia","Iran","Iraq","Ireland","Israel","Italy",
    "Jamaica","Japan","Jordan","Kazakhstan","Kenya","Kuwait","Latvia","Lebanon",
    "Lithuania","Luxembourg","Malaysia","Mexico","Moldova","Monaco","Mongolia",
    "Montenegro","Morocco","Myanmar","Nepal","Netherlands","New Zealand","Nigeria",
    "Norway","Pakistan","Panama","Peru","Philippines","Poland","Portugal","Qatar",
    "Romania","Russia","Saudi Arabia","Serbia","Singapore","Slovakia","Slovenia",
    "South Africa","South Korea","Spain","Sri Lanka","Sweden","Switzerland",
    "Taiwan","Tanzania","Thailand","Turkey","Uganda","Ukraine",
    "United Arab Emirates","United Kingdom","United States","Uruguay",
    "Venezuela","Vietnam","Zimbabwe",
]

#Preview {
    NavigationStack { SettingsView() }
}
