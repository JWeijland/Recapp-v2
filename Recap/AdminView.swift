// AdminView.swift – Admin-only aggregated activity dashboard

import SwiftUI

struct AdminView: View {
    private let nights = mockNights

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    topBar
                    privacyBanner
                    overviewGrid
                    topStopsSection
                    activityTimesSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: – Header

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Admin")
                    .font(.system(size: 28, weight: .black))
                    .tracking(-0.8)
                    .foregroundColor(.textPrimary)
                Text("Only visible to you")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textMuted)
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.accentOrangeSoft)
                    .frame(width: 42, height: 42)
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.accentOrange)
            }
        }
        .padding(.top, 58)
        .padding(.bottom, 4)
    }

    private var privacyBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundColor(.accentGreen)
                .font(.system(size: 14))
            Text("Aggregated & anonymized data only. No individual tracking.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#2A8B5F"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentGreenSoft)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentGreen.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: – Overview cards

    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            adminCard(icon: "moon.fill",   color: .accentOrange,         bg: .accentOrangeSoft,
                      title: "Total Recaps", value: "\(nights.count)")
            adminCard(icon: "figure.walk", color: .accentBlue,           bg: .accentBlueSoft,
                      title: "Total Steps",  value: totalSteps)
            adminCard(icon: "mappin",      color: .accentGreen,          bg: .accentGreenSoft,
                      title: "Total Stops",  value: "\(totalStops)")
            adminCard(icon: "flame.fill",  color: Color(hex: "#B8881A"), bg: .accentYellowSoft,
                      title: "Total Calories", value: "\(totalCalories)")
        }
    }

    private func adminCard(icon: String, color: Color, bg: Color, title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.textPrimary)
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.3)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20).padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: – Top stop types

    private var topStopsSection: some View {
        let counts = stopTypeCounts()
        let maxCount = counts.first?.1 ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Most Visited Places")

            ForEach(counts.prefix(5), id: \.0) { (type, count) in
                HStack(spacing: 10) {
                    Text(type.emoji)
                        .font(.system(size: 20))
                        .frame(width: 40, height: 40)
                        .background(Color.bgAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.label)
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.textPrimary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.bgAlt)
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accentOrange)
                                    .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }

                    Text("\(count)x")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.textSecondary)
                        .frame(width: 32, alignment: .trailing)
                }
                .padding(10)
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderCard, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: – Activity times

    private var activityTimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Activity Times")

            ForEach(nights) { night in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(night.dateString)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textSecondary)
                        Text(night.title)
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text(night.startTime)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.accentGreen)
                        Text("–")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                        Text(night.endTime)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.accentPink)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderCard, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: – Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .black))
            .foregroundColor(.textPrimary)
    }

    private var totalSteps: String {
        nights.reduce(0) { $0 + $1.totalSteps }.formatted()
    }

    private var totalStops: Int {
        nights.reduce(0) { $0 + $1.totalStopsCount }
    }

    private var totalCalories: Int {
        nights.reduce(0) { $0 + $1.caloriesBurned }
    }

    private func stopTypeCounts() -> [(StopIconType, Int)] {
        var counts: [StopIconType: Int] = [:]
        for night in nights {
            for stop in night.stops { counts[stop.iconType, default: 0] += 1 }
        }
        return counts.sorted { $0.value > $1.value }
    }
}

#Preview { AdminView() }
