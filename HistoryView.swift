import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \SleepEntry.date, order: .reverse) var sleepEntries: [SleepEntry]
    @Query(sort: \CaffeineEntry.date, order: .reverse) var caffeineEntries: [CaffeineEntry]
    @Query(sort: \MoodEntry.date, order: .reverse) var moodEntries: [MoodEntry]

    private var recentSleeps: [SleepEntry] { Array(sleepEntries.prefix(14).reversed()) }
    private var maxSleepDuration: Double { recentSleeps.map(\.duration).max() ?? 9 }

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // Sleep chart
                    if !recentSleeps.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "SLEEP — LAST 14 DAYS")
                            ForEach(recentSleeps) { entry in
                                SleepBarRow(entry: entry, max: max(maxSleepDuration, 9))
                            }
                        }
                        .padding(18)
                        .background(cardBackground)
                    }

                    // Caffeine history
                    if !caffeineEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "CAFFEINE LOG")
                            ForEach(Array(caffeineEntries.prefix(10))) { entry in
                                HStack {
                                    Image(systemName: "cup.and.heat.waves.fill")
                                        .foregroundStyle(Color.amber)
                                        .frame(width: 20)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.drinkName)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color.ink0)
                                        Text(entry.time, style: .time)
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundStyle(Color.ink2)
                                    }
                                    Spacer()
                                    Text("\(Int(entry.mg))mg")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.amber)
                                }
                                Divider().background(Color.surfaceLine)
                            }
                        }
                        .padding(18)
                        .background(cardBackground)
                    }

                    // Mood history
                    if !moodEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "MOOD LOG")
                            ForEach(Array(moodEntries.prefix(10))) { entry in
                                HStack {
                                    Text(entry.score.moodEmoji)
                                        .font(.system(size: 22))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.score.moodLabel)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color.ink0)
                                        if !entry.note.isEmpty {
                                            Text(entry.note)
                                                .font(.system(size: 11, design: .rounded))
                                                .foregroundStyle(Color.ink2)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(entry.score)/10")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.ink1)
                                        Text(entry.date, style: .date)
                                            .font(.system(size: 10, design: .rounded))
                                            .foregroundStyle(Color.ink2)
                                    }
                                }
                                Divider().background(Color.surfaceLine)
                            }
                        }
                        .padding(18)
                        .background(cardBackground)
                    }

                    if sleepEntries.isEmpty && caffeineEntries.isEmpty && moodEntries.isEmpty {
                        EmptyStateView(
                            icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                            title: "No History Yet",
                            message: "Start logging your sleep, caffeine, and mood to see your history here." // ✅ เปลี่ยนเป็น message
                        )
                        .padding(.top, 60)
                    }

                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surface0, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}


