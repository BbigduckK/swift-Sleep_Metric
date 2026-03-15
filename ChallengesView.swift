import SwiftUI
import SwiftData

// MARK: - Challenges & Records Hub View
struct ChallengesView: View {
    @Query(sort: \SleepEntry.date, order: .reverse)     var sleepEntries: [SleepEntry]
    @Query(sort: \CaffeineEntry.date, order: .reverse)  var caffeineEntries: [CaffeineEntry]
    @Query(sort: \MoodEntry.date, order: .reverse)      var moodEntries: [MoodEntry]
    @Query(sort: \ChallengeProgress.startDate)          var challengeProgresses: [ChallengeProgress]
    @Query(sort: \EarnedBadge.earnedAt, order: .reverse) var earnedBadges: [EarnedBadge]
    @Query(sort: \PersonalRecord.achievedAt, order: .reverse) var personalRecords: [PersonalRecord]
    @Environment(\.modelContext) private var context
    @State private var selectedTab = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            VStack(spacing: 0) {
                // Tab picker
                HStack(spacing: 0) {
                    tabPill("Challenges", 0)
                    tabPill("Badges", 1)
                    tabPill("Records", 2)
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(Color.surface0)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case 0: challengesTab
                        case 1: badgesTab
                        default: recordsTab
                        }
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Challenges")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surface0, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { withAnimation { appeared = true }; checkAndAwardBadges() }
    }

    private func tabPill(_ label: String, _ idx: Int) -> some View {
        Button { withAnimation(.spring(response: 0.3)) { selectedTab = idx } } label: {
            Text(label).font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(selectedTab == idx ? Color.surface0 : Color.ink1)
                .padding(.vertical, 8).frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).fill(selectedTab == idx ? Color.amber : Color.clear))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Challenges Tab
    private var challengesTab: some View {
        VStack(spacing: 12) {
            ForEach(Array(SleepChallenge.all.enumerated()), id: \.element.id) { i, challenge in
                ChallengeCard(
                    challenge: challenge,
                    progress: challengeProgresses.first { $0.challengeID == challenge.id },
                    sleeps: sleepEntries, caffeines: caffeineEntries, moods: moodEntries
                ) { startChallenge(challenge) }
                .stagger(appeared: appeared, delay: Double(i) * 0.06)
            }
        }
    }

    private func startChallenge(_ challenge: SleepChallenge) {
        guard challengeProgresses.first(where: { $0.challengeID == challenge.id }) == nil else { return }
        let progress = ChallengeProgress(challengeID: challenge.id)
        context.insert(progress)
    }

    // MARK: - Badges Tab
    private var badgesTab: some View {
        VStack(spacing: 16) {
            let earnedIDs = Set(earnedBadges.map(\.badgeID))
            let earned = BadgeDefinition.all.filter { earnedIDs.contains($0.id) }
            let locked = BadgeDefinition.all.filter { !earnedIDs.contains($0.id) }

            if !earned.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "EARNED (\(earned.count))")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(earned) { badge in BadgeCell(badge: badge, earned: true) }
                    }
                }
                .stagger(appeared: appeared, delay: 0)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "trophy").font(.system(size: 40)).foregroundStyle(Color.ink2)
                    Text("Complete challenges to earn badges").font(.system(size: 14, design: .rounded)).foregroundStyle(Color.ink2)
                }
                .padding(40)
                .stagger(appeared: appeared, delay: 0)
            }

            if !locked.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "LOCKED (\(locked.count))")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(locked) { badge in BadgeCell(badge: badge, earned: false) }
                    }
                }
                .stagger(appeared: appeared, delay: 0.05)
            }
        }
    }

    // MARK: - Records Tab
    private var recordsTab: some View {
        VStack(spacing: 12) {
            let streak = StreakService.currentStreak(sleeps: sleepEntries, caffeines: caffeineEntries, moods: moodEntries)
            let debt = SleepAnalysisService.cumulativeDebt(from: sleepEntries)
            let score = EnergyScoreService.calculate(sleepDebt: debt, todayCaffeine: 0, latestMood: moodEntries.first?.score, lastSleepDuration: sleepEntries.first?.duration ?? 0, caffeineAfter2pm: 0)
            let scoreHistory = ScoreHistoryService.build(sleeps: sleepEntries, caffeines: caffeineEntries, moods: moodEntries, days: 30)

            // Score history graph
            if scoreHistory.count >= 3 {
                scoreGraphCard(history: scoreHistory).stagger(appeared: appeared, delay: 0)
            }

            // Personal records
            let recordTypes = ["bestScore", "longestStreak", "mostSleep", "bestConsistency", "bestMood"]
            ForEach(Array(recordTypes.enumerated()), id: \.element) { i, type in
                if let meta = PersonalRecordsService.recordMeta[type] {
                    let record = personalRecords.first { $0.recordType == type }
                    RecordCard(
                        icon: meta.icon, label: meta.label, color: meta.color,
                        currentValue: currentValueFor(type, score: score, streak: streak),
                        record: record, formatValue: meta.format
                    )
                    .stagger(appeared: appeared, delay: Double(i) * 0.06 + 0.05)
                }
            }
        }
    }

    private func currentValueFor(_ type: String, score: Int, streak: Int) -> Double {
        switch type {
        case "bestScore": return Double(score)
        case "longestStreak": return Double(streak)
        case "mostSleep": return sleepEntries.first?.duration ?? 0
        case "bestConsistency": return SleepAnalysisService.sleepConsistency(from: Array(sleepEntries.prefix(7)))
        case "bestMood": return Double(moodEntries.first?.score ?? 0)
        default: return 0
        }
    }

    // MARK: - Score Graph
    private func scoreGraphCard(history: [ScoreHistoryService.DayScore]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "30-DAY ENERGY SCORE")
                Spacer()
                let avg = Int(history.map(\.score).reduce(0, +) / history.count)
                Text("Avg \(avg)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Color.ink2)
            }

            GeometryReader { geo in
                let scores = history.map(\.score)
                let minS = Double(scores.min() ?? 0)
                let maxS = Double(scores.max() ?? 100)
                let range = max(maxS - minS, 20)
                let w = geo.size.width / CGFloat(max(scores.count - 1, 1))
                let h = geo.size.height

                ZStack(alignment: .bottomLeading) {
                    // Grid lines
                    ForEach([25, 50, 75], id: \.self) { val in
                        Path { p in
                            let y = h - h * CGFloat((Double(val) - minS) / range)
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    }

                    // Area fill
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h))
                        for (i, score) in scores.enumerated() {
                            let x = CGFloat(i) * w
                            let y = h - h * CGFloat((Double(score) - minS) / range)
                            if i == 0 { p.addLine(to: CGPoint(x: x, y: y)) }
                            else { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                        p.addLine(to: CGPoint(x: CGFloat(scores.count - 1) * w, y: h))
                        p.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [Color.amber.opacity(0.15), Color.amber.opacity(0.02)], startPoint: .top, endPoint: .bottom))

                    // Line
                    Path { p in
                        for (i, score) in scores.enumerated() {
                            let x = CGFloat(i) * w
                            let y = h - h * CGFloat((Double(score) - minS) / range)
                            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                            else { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(Color.amber, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Dots for high/low points
                    if let maxIdx = scores.indices.max(by: { scores[$0] < scores[$1] }) {
                        let x = CGFloat(maxIdx) * w
                        let y = h - h * CGFloat((Double(scores[maxIdx]) - minS) / range)
                        Circle().fill(Color.mint).frame(width: 8, height: 8).position(x: x, y: y)
                    }
                }
            }
            .frame(height: 120)
        }
        .padding(18).background(cardBackground)
    }

    // MARK: - Badge auto-award logic
    private func checkAndAwardBadges() {
        let earnedIDs = Set(earnedBadges.map(\.badgeID))
        func award(_ id: String) {
            guard !earnedIDs.contains(id) else { return }
            context.insert(EarnedBadge(badgeID: id))
        }
        if !sleepEntries.isEmpty { award("first_log") }
        let streak = StreakService.currentStreak(sleeps: sleepEntries, caffeines: caffeineEntries, moods: moodEntries)
        if streak >= 3  { award("streak_3") }
        if streak >= 7  { award("streak_7") }
        if streak >= 30 { award("streak_30") }
        let debt = SleepAnalysisService.cumulativeDebt(from: sleepEntries)
        if debt < 1 && !sleepEntries.isEmpty { award("debt_free") }
        let score = EnergyScoreService.calculate(sleepDebt: debt, todayCaffeine: 0, latestMood: nil, lastSleepDuration: sleepEntries.first?.duration ?? 0, caffeineAfter2pm: 0)
        if score >= 90 { award("score_90") }
        // Check completed challenges
        for prog in challengeProgresses where prog.isCompleted {
            if prog.challengeID == "early_bird"      { award("early_bird") }
            if prog.challengeID == "caffeine_curfew" { award("caffeine_curfew") }
            if prog.challengeID == "sleep_champion"  { award("sleep_champ") }
            if prog.challengeID == "consistent_logger" { award("logger") }
            if prog.challengeID == "night_owl_rehab" { award("night_rehab") }
        }
    }
}

// MARK: - Challenge Card
private struct ChallengeCard: View {
    let challenge: SleepChallenge
    let progress: ChallengeProgress?
    let sleeps: [SleepEntry]; let caffeines: [CaffeineEntry]; let moods: [MoodEntry]
    let onStart: () -> Void
    @Environment(\.modelContext) private var context

    private var progressDays: Int {
        guard let p = progress else { return 0 }
        return challenge.evaluateProgress(sleeps: sleeps, caffeines: caffeines, moods: moods, since: p.startDate)
    }
    private var pct: Double { Double(progressDays) / Double(challenge.durationDays) }
    private var isActive: Bool { progress != nil && !isComplete }
    private var isComplete: Bool { progress?.isCompleted ?? false || progressDays >= challenge.durationDays }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(challenge.color.opacity(0.12)).frame(width: 46, height: 46)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(challenge.color.opacity(isComplete ? 0.5 : 0.2), lineWidth: isComplete ? 2 : 1))
                    Image(systemName: isComplete ? "checkmark" : challenge.icon)
                        .font(.system(size: 18, weight: .semibold)).foregroundStyle(challenge.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(challenge.title).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
                        Spacer()
                        if isComplete {
                            Text("Done ✓").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(challenge.color)
                        } else if isActive {
                            Text("\(progressDays)/\(challenge.durationDays)d").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(challenge.color)
                        } else {
                            Text("\(challenge.durationDays) days").font(.system(size: 11, design: .rounded)).foregroundStyle(Color.ink2)
                        }
                    }
                    Text(challenge.description).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink2).lineSpacing(2)
                }
            }

            if isActive || isComplete {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05))
                            RoundedRectangle(cornerRadius: 4).fill(isComplete ? challenge.color : challenge.color.opacity(0.7))
                                .frame(width: geo.size.width * min(pct, 1))
                                .animation(.spring(response: 0.6), value: pct)
                        }
                    }.frame(height: 6)
                    if isActive {
                        Text("\(challenge.durationDays - progressDays) more day\(challenge.durationDays - progressDays == 1 ? "" : "s") to go")
                            .font(.system(size: 10, design: .rounded)).foregroundStyle(Color.ink2)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            } else {
                Button(action: onStart) {
                    Text("Start Challenge")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(challenge.color)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(challenge.color.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 10).stroke(challenge.color.opacity(0.3), lineWidth: 1)))
                }.buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18).fill(Color.surface1)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(isComplete ? challenge.color.opacity(0.3) : Color.surfaceLine, lineWidth: isComplete ? 1.5 : 1))
        )
        .onChange(of: progressDays) { _, new in
            if new >= challenge.durationDays, let p = progress, !p.isCompleted {
                p.isCompleted = true; p.completedAt = Date()
            }
        }
    }
}

// MARK: - Badge Cell
private struct BadgeCell: View {
    let badge: BadgeDefinition; let earned: Bool
    @State private var shine = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(earned ? badge.color.opacity(0.15) : Color.surface2)
                    .frame(width: 60, height: 60)
                    .overlay(Circle().stroke(earned ? badge.color.opacity(0.4) : Color.surfaceLine, lineWidth: earned ? 1.5 : 1))
                Image(systemName: badge.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(earned ? badge.color : Color.ink2)
                    .opacity(earned ? 1 : 0.3)
                if earned && shine {
                    Circle().stroke(badge.color.opacity(0.5), lineWidth: 2).frame(width: 70, height: 70).scaleEffect(shine ? 1.2 : 1).opacity(shine ? 0 : 0.8)
                }
            }
            Text(badge.title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(earned ? Color.ink0 : Color.ink2)
                .multilineTextAlignment(.center).lineLimit(2)
        }
        .onAppear { if earned { withAnimation(.easeOut(duration: 1.0).delay(0.3)) { shine = true } } }
    }
}

// MARK: - Record Card
private struct RecordCard: View {
    let icon: String; let label: String; let color: Color
    let currentValue: Double; let record: PersonalRecord?
    let formatValue: (Double) -> String

    private var isNewRecord: Bool { currentValue > (record?.value ?? 0) }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.10)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(label).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink2)
                HStack(spacing: 6) {
                    Text(formatValue(record?.value ?? currentValue))
                        .font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(Color.ink0)
                    if isNewRecord && record == nil {
                        Text("NEW").font(.system(size: 9, weight: .black, design: .rounded)).tracking(1)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Capsule().fill(color.opacity(0.2)))
                            .foregroundStyle(color)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("Current").font(.system(size: 9, design: .rounded)).foregroundStyle(Color.ink2)
                Text(formatValue(currentValue))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isNewRecord ? color : Color.ink1)
            }
        }
        .padding(14)
        .background(cardBackground)
    }
}

