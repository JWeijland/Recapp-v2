// OnboardingView.swift – Profile form + permission request

import SwiftUI
import CoreLocation
import Photos

private let months = [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
]

struct OnboardingView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    @State private var birthDay    = ""
    @State private var birthMonth  = ""
    @State private var birthYear   = ""
    @State private var country     = ""
    @State private var gender      = ""
    @State private var tosAccepted = false
    @State private var countrySearch = ""

    @State private var showMonthPicker   = false
    @State private var showCountryPicker = false
    @State private var isSubmitting      = false
    @State private var showPermissions   = false
    @State private var permOpacity       = 0.0
    @State private var showTerms         = false

    private var canProceed: Bool {
        let d = Int(birthDay) ?? 0
        let y = Int(birthYear) ?? 0
        let cur = Calendar.current.component(.year, from: Date())
        return !country.isEmpty
            && d >= 1 && d <= 31
            && !birthMonth.isEmpty
            && birthYear.count == 4 && y >= (cur - 100) && y <= cur
            && !gender.isEmpty
            && tosAccepted
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FFF6E5"), Color(hex: "#FBF7F2")],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            if showPermissions {
                permissionsView
            } else {
                formView
            }
        }
        .sheet(isPresented: $showMonthPicker) { monthSheet }
        .sheet(isPresented: $showCountryPicker) { countrySheet }
    }

    // MARK: – Permissions

    private var permissionsView: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.accentOrangeSoft)
                    .frame(width: 72, height: 72)
                    .overlay(Circle().strokeBorder(Color.accentOrange.opacity(0.2), lineWidth: 1.5))
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accentOrange)
            }
            Text("Setting up permissions")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            Text("Please allow location and photo access when prompted.")
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.accentGreen)
                    .font(.system(size: 14))
                Text("Your data is private and anonymized.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#2A8B5F"))
            }
            .padding(.top, 4)
            ProgressView()
                .tint(.accentGreen)
                .padding(.top, 16)
            Spacer()
        }
        .opacity(permOpacity)
    }

    // MARK: – Main form

    private var formView: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recapp")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(.textMuted)
                            .padding(.bottom, 12)
                        Text("Tell us about you")
                            .font(.system(size: 30, weight: .black))
                            .tracking(-0.8)
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 28)

                    fieldLabel("Date of Birth")
                    HStack(spacing: 8) {
                        ZStack {
                            if birthDay.isEmpty {
                                Text("DD")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.textMuted)
                            }
                            TextField("", text: $birthDay)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .tint(.accentOrange)
                                .onChange(of: birthDay) { _, v in birthDay = String(v.filter(\.isNumber).prefix(2)) }
                        }
                        .frame(width: 40)
                        .padding(.horizontal, 12).padding(.vertical, 14)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderInput, lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        Button { showMonthPicker = true } label: {
                            HStack(spacing: 6) {
                                Text(birthMonth.isEmpty ? "Maand" : birthMonth)
                                    .foregroundColor(birthMonth.isEmpty ? .textMuted : .textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.textMuted)
                                    .font(.system(size: 12))
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 14)
                            .background(Color.bgCard)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderInput, lineWidth: 1.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        ZStack {
                            if birthYear.isEmpty {
                                Text("JJJJ")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.textMuted)
                            }
                            TextField("", text: $birthYear)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .tint(.accentOrange)
                                .onChange(of: birthYear) { _, v in birthYear = String(v.filter(\.isNumber).prefix(4)) }
                        }
                        .frame(width: 52)
                        .padding(.horizontal, 12).padding(.vertical, 14)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderInput, lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.bottom, 22)

                    fieldLabel("Country of Origin")
                    Button { showCountryPicker = true } label: {
                        HStack {
                            Text(country.isEmpty ? "Select your country" : country)
                                .foregroundColor(country.isEmpty ? .textMuted : .textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.textMuted)
                                .font(.system(size: 14))
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderInput, lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.bottom, 22)

                    fieldLabel("Gender")
                    HStack(spacing: 10) {
                        ForEach(["Male", "Female", "Other"], id: \.self) { g in
                            Button { gender = g } label: {
                                Text(g)
                                    .font(.system(size: 15, weight: gender == g ? .bold : .semibold))
                                    .foregroundColor(gender == g ? .accentBlue : .textMuted)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(gender == g ? Color.accentBlueSoft : Color.bgCard)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(gender == g ? Color.accentBlue : Color.borderInput, lineWidth: 1.5)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.bottom, 22)

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.accentGreen)
                            .font(.system(size: 13))
                        Text("Your data is private and anonymized.")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#2A8B5F"))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentGreenSoft)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentGreen.opacity(0.2), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 24)
            }

            Button(action: skipToDemo) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.accentOrange)
                        .font(.system(size: 13))
                    Text("Skip for Demo")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.accentOrange)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Button(action: { tosAccepted.toggle() }) {
                        Image(systemName: tosAccepted ? "checkmark.square.fill" : "square")
                            .font(.system(size: 22))
                            .foregroundColor(tosAccepted ? .accentOrange : .textMuted)
                    }
                    HStack(spacing: 0) {
                        Text("I accept the ")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textMuted)
                        Button { showTerms = true } label: {
                            Text("Terms & Conditions")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.accentOrange)
                                .underline()
                        }
                    }
                    Spacer()
                }
                .sheet(isPresented: $showTerms) {
                    NavigationStack { TermsView() }
                        .presentationDetents([.large])
                }

                Button(action: handleContinue) {
                    Group {
                        if isSubmitting {
                            ProgressView().tint(Color(hex: "#FFFDF7"))
                        } else {
                            Text("Continue")
                                .font(.system(size: 17, weight: .black))
                                .foregroundColor(Color(hex: "#FFFDF7"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canProceed ? Color.textPrimary : Color.textPrimary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .disabled(!canProceed || isSubmitting)
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 24)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.borderCard), alignment: .top)
        }
    }

    // MARK: – Sheets

    private var monthSheet: some View {
        NavigationStack {
            List {
                ForEach(months, id: \.self) { m in
                    Button {
                        birthMonth = m; showMonthPicker = false
                    } label: {
                        HStack {
                            Text(m)
                                .font(.system(size: 16, weight: birthMonth == m ? .bold : .semibold))
                                .foregroundColor(birthMonth == m ? .accentOrange : .textPrimary)
                            Spacer()
                            if birthMonth == m { Image(systemName: "checkmark").foregroundColor(.accentOrange) }
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
        .presentationDetents([.medium, .large])
    }

    private var countrySheet: some View {
        NavigationStack {
            List {
                ForEach(filteredCountries, id: \.self) { c in
                    Button {
                        country = c; showCountryPicker = false; countrySearch = ""
                    } label: {
                        HStack {
                            Text(c)
                                .font(.system(size: 16, weight: country == c ? .bold : .semibold))
                                .foregroundColor(country == c ? .accentOrange : .textPrimary)
                            Spacer()
                            if country == c { Image(systemName: "checkmark").foregroundColor(.accentOrange) }
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

    private var filteredCountries: [String] {
        countrySearch.isEmpty ? allOnboardingCountries
            : allOnboardingCountries.filter { $0.localizedCaseInsensitiveContains(countrySearch) }
    }

    // MARK: – Actions

    private func skipToDemo() { onboardingComplete = true }

    private func handleContinue() {
        guard canProceed && !isSubmitting else { return }
        isSubmitting = true
        withAnimation(.easeOut(duration: 0.4)) {
            showPermissions = true
            permOpacity = 1
        }
        Task { @MainActor in
            let manager = CLLocationManager()
            manager.requestWhenInUseAuthorization()
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await NotificationManager.shared.requestPermission()
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            onboardingComplete = true
        }
    }

    @ViewBuilder
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundColor(.textSecondary)
            .padding(.bottom, 10)
    }
}

private extension View {
    func inputStyle() -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.textPrimary)
            .tint(.accentGreen)
            .padding(.horizontal, 12).padding(.vertical, 14)
            .background(Color.bgAlt)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderInput, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private let allOnboardingCountries = [
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

#Preview { OnboardingView() }
