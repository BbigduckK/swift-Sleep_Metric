import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \SleepEntry.date, order: .reverse) var sleepEntries: [SleepEntry]
    @Query(sort: \CaffeineEntry.date, order: .reverse) var caffeineEntries: [CaffeineEntry]
    @Query(sort: \MoodEntry.date, order: .reverse) var moodEntries: [MoodEntry]

    private var insights: [Insight] {
        InsightsService.generate(
            sleepEntries: sleepEntries,
            caffeineEntries: caffeineEntries,
            moodEntries: moodEntries
        )
    }

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach(insights) { insight in
                        InsightCard(insight: insight)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surface0, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct InsightCard: View {
    let insight: Insight
    @State private var appeared = false

    private var accentColor: Color {
        switch insight.category {
        case .sleep:    return .sky
        case .caffeine: return .amber
        case .mood:     return .lilac
        case .trend:    return .mint
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: insight.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(insight.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ink0)
                Text(insight.body)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Color.ink1)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.surface1)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(accentColor.opacity(0.15), lineWidth: 1))
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }
}

