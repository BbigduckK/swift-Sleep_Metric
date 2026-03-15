import SwiftUI
import SwiftData

// MARK: - Journal View
struct JournalView: View {
    @Query(sort: \JournalEntry.date, order: .reverse)    var entries: [JournalEntry]
    @Query(sort: \SleepEntry.date, order: .reverse)      var sleepEntries: [SleepEntry]
    @Query(sort: \MoodEntry.date, order: .reverse)       var moodEntries: [MoodEntry]
    @State private var showWrite = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            VStack(spacing: 0) {
                // Write button
                Button { showWrite = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "pencil.line").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.lilac)
                        Text("Write today's entry").font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(Color.ink0)
                        Spacer()
                        Text("optional").font(.system(size: 11, design: .rounded)).foregroundStyle(Color.ink2)
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Color.ink2)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.lilac.opacity(0.07)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.lilac.opacity(0.2), lineWidth: 1)))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)

                if entries.isEmpty {
                    Spacer()
                    EmptyStateView(icon: "pencil.and.scribble", title: "No journal entries yet",
                        message: "Jot down what happened today. After a few entries, you'll get AI-powered pattern insights — completely optional.")
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        // AI pattern card (shows after 3+ entries)
                        if entries.count >= 3 {
                            PatternInsightCard(entries: Array(entries.prefix(14)),
                                sleeps: Array(sleepEntries.prefix(14)), moods: Array(moodEntries.prefix(14)))
                            .padding(.horizontal, 20).padding(.bottom, 12)
                            .stagger(appeared: appeared, delay: 0)
                        }
                        LazyVStack(spacing: 12) {
                            ForEach(Array(entries.enumerated()), id: \.element.id) { i, entry in
                                JournalCard(entry: entry)
                                    .padding(.horizontal, 20)
                                    .stagger(appeared: appeared, delay: Double(i) * 0.05)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surface0, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showWrite) { WriteJournalView() }
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Write Journal Sheet
struct WriteJournalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SleepEntry.date, order: .reverse)  var sleepEntries: [SleepEntry]
    @Query(sort: \MoodEntry.date, order: .reverse)   var moodEntries: [MoodEntry]
    @Query(sort: \JournalEntry.date, order: .reverse) var entries: [JournalEntry]

    @State private var text = ""
    @State private var showConfirm = false
    @State private var saved = false
    @FocusState private var focused: Bool

    private var todayScore: Int {
        let debt = SleepAnalysisService.cumulativeDebt(from: sleepEntries)
        return EnergyScoreService.calculate(sleepDebt: debt, todayCaffeine: 0, latestMood: moodEntries.first?.score, lastSleepDuration: sleepEntries.first?.duration ?? 0, caffeineAfter2pm: 0)
    }
    private var todaySleep: Double { sleepEntries.first?.duration ?? 0 }
    private var todayMood: Int { moodEntries.first?.score ?? 0 }

    private var prompts = [
        "How are you feeling today?",
        "What's on your mind?",
        "Anything affecting your energy today?",
        "What went well? What was tough?",
        "How did you sleep last night — really?"
    ]
    @State private var promptIndex = Int.random(in: 0..<5)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Context snapshot
                    HStack(spacing: 12) {
                        contextChip("\(todayScore)", "score", .amber)
                        if todaySleep > 0 { contextChip(String(format: "%.1fh", todaySleep), "sleep", .sky) }
                        if todayMood > 0 { contextChip("\(todayMood)/10", "mood", .lilac) }
                    }
                    .padding(.horizontal, 24).padding(.top, 16)

                    // Text area
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text(prompts[promptIndex])
                                .font(.system(size: 16, design: .rounded)).foregroundStyle(Color.ink2)
                                .padding(.horizontal, 4).padding(.top, 2)
                        }
                        TextEditor(text: $text)
                            .font(.system(size: 16, design: .rounded)).foregroundStyle(Color.ink0)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .focused($focused)
                            .frame(minHeight: 200)
                    }
                    .padding(.horizontal, 20).padding(.top, 16)

                    // Word count
                    HStack {
                        Spacer()
                        Text("\(text.split(separator: " ").count) words")
                            .font(.system(size: 11, design: .rounded)).foregroundStyle(Color.ink2)
                    }
                    .padding(.horizontal, 24).padding(.top, 4)

                    Spacer()

                    // Save
                    PrimaryButton(label: saved ? "Saved ✓" : "Save Entry", icon: saved ? "checkmark" : "square.and.arrow.down.fill", color: .lilac) {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { showConfirm = true }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || saved)
                    .padding(.horizontal, 24).padding(.bottom, 32)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.surface1, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.ink2).font(.system(size: 15, design: .rounded))
                }
            }
            .confirmationDialog("Save this entry?", isPresented: $showConfirm, titleVisibility: .visible) {
                Button("Save") { saveEntry() }
                Button("Cancel", role: .cancel) {}
            }
        }
        .modifier(SheetBackgroundModifier())
        .onAppear { focused = true }
    }

    private func contextChip(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(color)
            Text(label).font(.system(size: 9, design: .rounded)).foregroundStyle(Color.ink2)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(Capsule().fill(color.opacity(0.09)).overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 1)))
    }

    private func saveEntry() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let entry = JournalEntry(text: trimmed, energyScore: todayScore, sleepHours: todaySleep, moodScore: todayMood)
        entry.tags = autoDetectTags(text: trimmed)
        context.insert(entry)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
    }

    private func autoDetectTags(text: String) -> [String] {
        let lower = text.lowercased()
        var tags: [String] = []
        let stressWords = ["stress", "anxious", "anxiety", "worried", "overwhelm", "deadline", "pressure", "busy", "exhausted", "tired"]
        let recoveryWords = ["relax", "great", "good sleep", "rested", "calm", "peaceful", "energetic", "productive", "focus"]
        let exerciseWords = ["workout", "gym", "run", "exercise", "walk", "yoga", "swim"]
        let socialWords = ["friends", "family", "party", "social", "out", "dinner", "meeting"]
        if stressWords.contains(where: { lower.contains($0) }) { tags.append("stress") }
        if recoveryWords.contains(where: { lower.contains($0) }) { tags.append("recovery") }
        if exerciseWords.contains(where: { lower.contains($0) }) { tags.append("exercise") }
        if socialWords.contains(where: { lower.contains($0) }) { tags.append("social") }
        return tags
    }
}

// MARK: - Journal Card
struct JournalCard: View {
    let entry: JournalEntry
    @State private var expanded = false
    private let df: DateFormatter = { let f = DateFormatter(); f.dateFormat = "EEE, MMM d · h:mm a"; return f }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(df.string(from: entry.date)).font(.system(size: 11, design: .rounded)).foregroundStyle(Color.ink2)
                Spacer()
                HStack(spacing: 6) {
                    if entry.energyScore > 0 { scorePill(entry.energyScore) }
                    if entry.moodScore > 0 { Text("\(entry.moodScore.moodEmoji)").font(.system(size: 14)) }
                }
            }
            Text(entry.text)
                .font(.system(size: 14, design: .rounded)).foregroundStyle(Color.ink0).lineSpacing(4)
                .lineLimit(expanded ? nil : 3)

            if entry.text.count > 120 {
                Button { withAnimation { expanded.toggle() } } label: {
                    Text(expanded ? "Show less" : "Read more")
                        .font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(Color.lilac)
                }
            }

            // Tags
            if !entry.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(entry.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(0.5)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(tagColor(tag).opacity(0.12)).overlay(Capsule().stroke(tagColor(tag).opacity(0.25), lineWidth: 1)))
                            .foregroundStyle(tagColor(tag))
                    }
                }
            }

            // AI insight if available
            if !entry.aiInsight.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles").font(.system(size: 11)).foregroundStyle(Color.mint)
                    Text(entry.aiInsight).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.mint).lineSpacing(3)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.mint.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mint.opacity(0.15), lineWidth: 1)))
            }
        }
        .padding(16).background(cardBackground)
    }

    private func scorePill(_ score: Int) -> some View {
        HStack(spacing: 3) {
            Circle().fill(score.scoreColor).frame(width: 5, height: 5)
            Text("\(score)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(score.scoreColor)
        }
    }

    private func tagColor(_ tag: String) -> Color {
        switch tag {
        case "stress": return .coral; case "recovery": return .mint
        case "exercise": return .sky; case "social": return .lilac
        default: return .amber
        }
    }
}

// MARK: - Pattern Insight Card (local heuristic, no API needed)
struct PatternInsightCard: View {
    let entries: [JournalEntry]
    let sleeps: [SleepEntry]
    let moods: [MoodEntry]

    private var insight: String {
        // Correlate stress tags with next-day sleep
        let stressDays = entries.filter { $0.tags.contains("stress") }
        let normalDays = entries.filter { !$0.tags.contains("stress") }
        if stressDays.count >= 2 && normalDays.count >= 2 {
            let cal = Calendar.current
            let avgStressSleep = stressDays.compactMap { entry -> Double? in
                let nextDay = cal.date(byAdding: .day, value: 1, to: entry.date) ?? entry.date
                return sleeps.first { cal.startOfDay(for: $0.date) == cal.startOfDay(for: nextDay) }?.duration
            }.reduce(0, +) / Double(max(stressDays.count, 1))

            let avgNormalSleep = normalDays.compactMap { entry -> Double? in
                let nextDay = cal.date(byAdding: .day, value: 1, to: entry.date) ?? entry.date
                return sleeps.first { cal.startOfDay(for: $0.date) == cal.startOfDay(for: nextDay) }?.duration
            }.reduce(0, +) / Double(max(normalDays.count, 1))

            if avgStressSleep > 0 && avgNormalSleep > 0 {
                let diff = avgNormalSleep - avgStressSleep
                if abs(diff) > 0.4 {
                    return "On nights after you noted stress, you sleep \(String(format: "%.1f", abs(diff)))h \(diff > 0 ? "less" : "more") than usual. Managing stress before bed may help your sleep quality."
                }
            }
        }
        // Correlation: recovery tags with high mood next day
        let recovDays = entries.filter { $0.tags.contains("recovery") }
        if recovDays.count >= 2 {
            return "You've noted \(recovDays.count) recovery days in your journal. Keep tracking — patterns between your daily events and sleep will appear over time."
        }
        return "Keep journalling — after a few more entries, patterns between your mood, stress, and sleep quality will start to appear here."
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.mint.opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: "sparkles").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.mint)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("PATTERN INSIGHT").font(.system(size: 9, weight: .black, design: .rounded)).tracking(2).foregroundStyle(Color.mint)
                    Spacer()
                    Text("From your entries").font(.system(size: 9, design: .rounded)).foregroundStyle(Color.ink2)
                }
                Text(insight).font(.system(size: 13, design: .rounded)).foregroundStyle(Color.ink0).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.surface1).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mint.opacity(0.2), lineWidth: 1)))
    }
}

// MARK: - Siri Shortcuts Guide View
struct SiriShortcutsView: View {
    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "mic.fill").font(.system(size: 36, weight: .semibold)).foregroundStyle(Color.sky)
                        Text("Siri Shortcuts").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(Color.ink0)
                        Text("Use your voice to log data without opening the app.")
                            .font(.system(size: 14, design: .rounded)).foregroundStyle(Color.ink1)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 8)

                    // Setup steps
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "SETUP IN 3 STEPS")
                        stepCard(1, "Open the Shortcuts app on your iPhone", "arrow.up.right.square.fill", .sky)
                        stepCard(2, "Tap + → Search 'Sleep Metric' to find Sleep Metric actions", "plus.circle.fill", .amber)
                        stepCard(3, "Create a shortcut and record your Siri phrase", "mic.circle.fill", .mint)
                    }
                    .padding(18).background(cardBackground)

                    // Available shortcuts
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "AVAILABLE VOICE COMMANDS")
                        shortcutRow("Log my sleep", "Opens sleep log sheet instantly", "moon.fill", .sky)
                        shortcutRow("Log caffeine", "Opens caffeine log sheet", "cup.and.heat.waves.fill", .amber)
                        shortcutRow("Log my mood", "Opens mood log sheet", "face.smiling.fill", .lilac)
                        shortcutRow("What's my energy score", "Shows Energy Score notification", "bolt.fill", .mint)
                        shortcutRow("Log a nap", "Opens nap log sheet", "zzz", .lilac)
                        shortcutRow("Open Sleep Metric", "Opens app to Dashboard", "house.fill", .sky)
                    }
                    .padding(18).background(cardBackground)

                    // Note
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill").font(.system(size: 14)).foregroundStyle(Color.sky)
                        Text("Siri Shortcuts require Xcode integration to register custom intents. In Swift Playgrounds, you can still use the Shortcuts app to create 'Open App' shortcuts that launch directly to any screen via URL schemes.")
                            .font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink1).lineSpacing(3)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.sky.opacity(0.07)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sky.opacity(0.2), lineWidth: 1)))

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 24)
            }
        }
        .navigationTitle("Siri Shortcuts")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surface0, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func stepCard(_ num: Int, _ text: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 36, height: 36)
                Text("\(num)").font(.system(size: 15, weight: .black, design: .rounded)).foregroundStyle(color)
            }
            Text(text).font(.system(size: 13, design: .rounded)).foregroundStyle(Color.ink0).lineSpacing(3)
        }
    }

    private func shortcutRow(_ phrase: String, _ desc: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.1)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\"\(phrase)\"").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
                Text(desc).font(.system(size: 11, design: .rounded)).foregroundStyle(Color.ink2)
            }
            Spacer()
        }
    }
}

