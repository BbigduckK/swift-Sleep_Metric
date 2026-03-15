import SwiftUI
import SwiftData

// MARK: - Content View
struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "bolt.heart.fill") }
            NavigationStack { ChallengesView() }
                .tabItem { Label("Challenges", systemImage: "trophy.fill") }
            NavigationStack { WeeklyReportView() }
                .tabItem { Label("Report", systemImage: "chart.bar.doc.horizontal") }
            NavigationStack { JournalView() }
                .tabItem { Label("Journal", systemImage: "pencil.line") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.amber)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @Query(sort: \SleepEntry.date, order: .reverse)       var sleepEntries: [SleepEntry]
    @Query(sort: \CaffeineEntry.date, order: .reverse)    var caffeineEntries: [CaffeineEntry]
    @Query(sort: \MoodEntry.date, order: .reverse)        var moodEntries: [MoodEntry]
    @Query(sort: \NapEntry.date, order: .reverse)         var napEntries: [NapEntry]
    @Query(sort: \SleepGoal.createdAt, order: .reverse)   var goals: [SleepGoal]
    @Query(sort: \EarnedBadge.earnedAt, order: .reverse)  var earnedBadges: [EarnedBadge]
    @Query(sort: \ChronotypeResult.completedAt, order: .reverse) var chronotypes: [ChronotypeResult]
    @Query(sort: \OnboardingProfile.completedAt, order: .reverse) var profiles: [OnboardingProfile]

    @StateObject private var healthKit = HealthKitService.shared
    @Environment(\.modelContext) private var context

    @State private var animatedScore: Double = 0
    @State private var appeared = false
    @State private var showLogSleep    = false
    @State private var showLogCaffeine = false
    @State private var showLogMood     = false
    @State private var showLogNap      = false
    @State private var showGoal        = false
    @State private var showDebtPayoff  = false
    @State private var showWhatIf      = false
    @State private var showCorrelation = false
    @State private var showChronotype  = false
    @State private var showCaffCalc    = false
    @State private var showSiri        = false
    @State private var tipIndex: Int   = 0
    @State private var newRecordMessage: String? = nil

    private var goal: SleepGoal? { goals.first }
    private var chronotype: Chronotype? { chronotypes.first.map { Chronotype.from(id: $0.chronotype) } }
    private var profile: OnboardingProfile? { profiles.first }

    private var debt: Double { SleepAnalysisService.cumulativeDebt(from: sleepEntries) }
    private var risk: String { SleepAnalysisService.cognitiveRiskLevel(debt: debt) }
    private var lastSleep: Double { sleepEntries.first?.duration ?? 0 }
    private var todayCaffeine: Double {
        let t = Calendar.current.startOfDay(for: Date())
        return caffeineEntries.filter { Calendar.current.startOfDay(for: $0.date) == t }.reduce(0) { $0 + $1.mg }
    }
    private var caffeineAfter2pm: Double {
        let t = Calendar.current.startOfDay(for: Date())
        return caffeineEntries.filter { Calendar.current.startOfDay(for: $0.date) == t && Calendar.current.component(.hour, from: $0.time) >= 14 }.reduce(0) { $0 + $1.mg }
    }
    private var currentCaffeineInBody: Double {
        let entries = caffeineEntries.filter { Calendar.current.startOfDay(for: $0.date) == Calendar.current.startOfDay(for: Date()) }.map { ($0.mg, $0.time) }
        return CaffeineHalfLifeService.totalRemaining(entries: entries, at: Date())
    }
    private var latestMood: Int? { moodEntries.first?.score }
    private var score: Int { EnergyScoreService.calculate(sleepDebt: debt, todayCaffeine: todayCaffeine, latestMood: latestMood, lastSleepDuration: lastSleep, caffeineAfter2pm: caffeineAfter2pm) }
    private var streak: Int { StreakService.currentStreak(sleeps: sleepEntries, caffeines: caffeineEntries, moods: moodEntries) }
    private var completion: (sleep: Bool, caffeine: Bool, mood: Bool) { StreakService.todayCompletion(sleeps: sleepEntries, caffeines: caffeineEntries, moods: moodEntries) }
    private var recentSleeps: [SleepEntry] { Array(sleepEntries.prefix(7).reversed()) }
    private var maxSleep: Double { recentSleeps.map(\.duration).max() ?? 10 }
    private var hasAnyData: Bool { !sleepEntries.isEmpty || !caffeineEntries.isEmpty || !moodEntries.isEmpty }
    private var tips: [SleepTip] { TipsService.contextualTips(sleepDebt: debt, lastSleep: lastSleep, latestMood: latestMood, caffeineAfter2pm: caffeineAfter2pm, hour: Calendar.current.component(.hour, from: Date())) }
    private var goalProgress: Double? { guard let g = goal else { return nil }; return min(lastSleep / g.targetHours, 1.0) }
    private var recommendedBedtime: Date { SmartBedtimeService.recommendedBedtime(debt: debt, goal: goal) }
    private var bedtimeFmt: DateFormatter { let f = DateFormatter(); f.dateFormat = "h:mm a"; return f }
    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good Morning"; case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"; default: return "Good Night"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface0.ignoresSafeArea()
                Circle().fill(score.scoreColor.opacity(0.04)).frame(width: 500).blur(radius: 120).offset(x: 100, y: -250)
                    .animation(.easeInOut(duration: 1.2), value: score).allowsHitTesting(false)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("SLEEP METRIC").font(.system(size: 10, weight: .black, design: .rounded)).tracking(4).foregroundStyle(Color.ink2)
                                Text(greeting).font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(Color.ink0)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 6) {
                                if hasAnyData { RiskBadge(risk: risk) }
                                if streak > 0 { StreakBadge(streak: streak) }
                            }
                        }.stagger(appeared: appeared, delay: 0)

                        // New Record Toast
                        if let msg = newRecordMessage {
                            HStack(spacing: 10) {
                                Image(systemName: "trophy.fill").foregroundStyle(Color.amber)
                                Text(msg).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.amber.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.amber.opacity(0.3), lineWidth: 1)))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if !hasAnyData {
                            EmptyStateView(icon: "bolt.heart", title: "Welcome to Sleep Metric", message: "Log your first sleep session to calculate your Energy Score.")
                            .padding(.vertical, 50).stagger(appeared: appeared, delay: 0.1)
                        } else {
                            scoreCard.stagger(appeared: appeared, delay: 0.08)

                            // Chronotype banner
                            if let ct = chronotype {
                                chronotypeBanner(ct).stagger(appeared: appeared, delay: 0.11)
                            }

                            smartBedtimeCard.stagger(appeared: appeared, delay: 0.13)
                            if let g = goal, let prog = goalProgress { goalBar(goal: g, progress: prog).stagger(appeared: appeared, delay: 0.16) }
                            todayChecklist.stagger(appeared: appeared, delay: 0.19)
                            if !recentSleeps.isEmpty { sleepChart.stagger(appeared: appeared, delay: 0.23) }
                            // Caffeine live level
                            if todayCaffeine > 0 { caffeineLiveCard.stagger(appeared: appeared, delay: 0.26) }
                            if !tips.isEmpty { tipSection.stagger(appeared: appeared, delay: 0.29) }
                            quickActions.stagger(appeared: appeared, delay: 0.32)
                        }

                        logButtons.stagger(appeared: appeared, delay: hasAnyData ? 0.36 : 0.15)
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20).padding(.top, 56).padding(.bottom, 16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showLogSleep)    { LogSleepSheet() }
        .sheet(isPresented: $showLogCaffeine) { LogCaffeineSheet() }
        .sheet(isPresented: $showLogMood)     { LogMoodSheet() }
        .sheet(isPresented: $showLogNap)      { LogNapSheet() }
        .sheet(isPresented: $showGoal)        { SleepGoalView() }
        .sheet(isPresented: $showDebtPayoff)  { NavigationStack { DebtPayoffView() } }
        .sheet(isPresented: $showWhatIf)      { NavigationStack { WhatIfSimulatorView() } }
        .sheet(isPresented: $showCorrelation) { NavigationStack { CorrelationView() } }
        .sheet(isPresented: $showChronotype)  { ChronotypeQuizView() }
        .sheet(isPresented: $showCaffCalc)    { NavigationStack { CaffeineHalfLifeView() } }
        .sheet(isPresented: $showSiri)        { NavigationStack { SiriShortcutsView() } }
        .onAppear {
            appeared = true
            withAnimation(.spring(response: 1.2, dampingFraction: 0.72).delay(0.4)) { animatedScore = Double(score) }
            tipIndex = Int.random(in: 0..<max(tips.count, 1))
            healthKit.checkAuthorization()
            checkPersonalRecords()
            MoodAwareNotificationService.scheduleEveningNotification(recentMoods: Array(moodEntries.prefix(3)), streak: streak)
            SmartBedtimeService.scheduleSmartReminder(debt: debt, goal: goal)
        }
        .onChange(of: score) { _, new in withAnimation(.spring(response: 0.8)) { animatedScore = Double(new) } }
    }

    // MARK: - Score Card
    private var scoreCard: some View {
        ZStack {
            Canvas { ctx, size in
                for x in stride(from: 0, to: size.width, by: 24) {
                    for y in stride(from: 0, to: size.height, by: 24) {
                        ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(.white.opacity(0.03)))
                    }
                }
            }.clipShape(RoundedRectangle(cornerRadius: 24))
            HStack(spacing: 0) {
                VStack(spacing: 8) {
                    EnergyRing(score: score, animatedScore: animatedScore, size: 148, lineWidth: 12)
                    Text("debt · \(String(format: "%.1f", debt))h").font(.system(size: 10, design: .rounded)).foregroundStyle(Color.ink2)
                }
                .frame(maxWidth: .infinity)
                Rectangle().fill(Color.surfaceLine).frame(width: 1).padding(.vertical, 16)
                VStack(alignment: .leading, spacing: 12) {
                    statPill("moon.fill", .sky,   "Sleep",    String(format: "%.1fh", lastSleep))
                    statPill("cup.and.heat.waves.fill", .amber, "In body", "\(Int(currentCaffeineInBody))mg now")
                    if let mood = latestMood { statPill("face.smiling", .lilac, "Mood", "\(mood)/10") }
                    if sleepEntries.count >= 3 {
                        let c = SleepAnalysisService.sleepConsistency(from: Array(sleepEntries.prefix(7)))
                        statPill("arrow.triangle.2.circlepath", .mint, "Consistency", "\(Int(c))%")
                    }
                    if !earnedBadges.isEmpty { statPill("trophy.fill", .amber, "Badges", "\(earnedBadges.count) earned") }
                }
                .frame(maxWidth: .infinity).padding(.leading, 14)
            }
            .padding(18)
        }
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.surface1).overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.surfaceLine, lineWidth: 1)))
    }

    private func statPill(_ icon: String, _ color: Color, _ label: String, _ value: String) -> some View {
        HStack(spacing: 8) {
            ZStack { Circle().fill(color.opacity(0.12)).frame(width: 26, height: 26); Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundStyle(color) }
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.system(size: 8, weight: .black, design: .rounded)).tracking(1).foregroundStyle(Color.ink2)
                Text(value).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
            }
        }
    }

    // MARK: - Chronotype Banner
    private func chronotypeBanner(_ ct: Chronotype) -> some View {
        Button { showChronotype = true } label: {
            HStack(spacing: 12) {
                Text(ct.animal).font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text("YOUR TYPE: \(ct.name.uppercased())").font(.system(size: 9, weight: .black, design: .rounded)).tracking(2).foregroundStyle(ct.color)
                    Text(ct.tagline).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("PEAK FOCUS").font(.system(size: 8, weight: .black, design: .rounded)).tracking(1).foregroundStyle(Color.ink2)
                    Text(ct.peakFocus).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(ct.color)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(ct.color.opacity(0.07)).overlay(RoundedRectangle(cornerRadius: 16).stroke(ct.color.opacity(0.2), lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Smart Bedtime
    private var smartBedtimeCard: some View {
        HStack(spacing: 12) {
            ZStack { RoundedRectangle(cornerRadius: 10).fill(Color.sky.opacity(0.1)).frame(width: 36, height: 36); Image(systemName: "moon.stars.fill").font(.system(size: 15)).foregroundStyle(Color.sky) }
            VStack(alignment: .leading, spacing: 2) {
                Text("SMART BEDTIME").font(.system(size: 9, weight: .black, design: .rounded)).tracking(2).foregroundStyle(Color.ink2)
                Text("Tonight: \(bedtimeFmt.string(from: recommendedBedtime))").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Color.sky)
            }
            Spacer()
            if debt > 1 { Text("+\(Int(min(debt*15,60)))min recovery").font(.system(size: 10, design: .rounded)).foregroundStyle(Color.amber) }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.sky.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sky.opacity(0.2), lineWidth: 1)))
    }

    // MARK: - Goal Bar
    private func goalBar(goal: SleepGoal, progress: Double) -> some View {
        VStack(spacing: 8) {
            HStack {
                Label("Sleep Goal", systemImage: "target").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Color.amber)
                Spacer()
                Text("\(String(format: "%.1f", lastSleep)) / \(String(format: "%.1f", goal.targetHours))h").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(progress >= 1 ? Color.mint : Color.ink1)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05))
                    RoundedRectangle(cornerRadius: 6).fill(progress >= 1 ? Color.mint : Color.amber).frame(width: geo.size.width * progress).animation(.spring(response: 0.8), value: progress)
                }
            }.frame(height: 8)
            if progress >= 1 { Label("Goal reached! 🎉", systemImage: "checkmark.circle.fill").font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(Color.mint) }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.amber.opacity(0.07)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.amber.opacity(0.2), lineWidth: 1)))
    }

    // MARK: - Checklist
    private var todayChecklist: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "TODAY'S LOG")
                Spacer()
                let n = [completion.sleep, completion.caffeine, completion.mood].filter { $0 }.count
                Text("\(n)/3 done").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(n == 3 ? Color.mint : Color.ink2)
            }
            HStack(spacing: 10) {
                checkItem("Sleep", icon: "moon.fill", color: .sky, done: completion.sleep) { showLogSleep = true }
                checkItem("Caffeine", icon: "cup.and.heat.waves.fill", color: .amber, done: completion.caffeine) { showLogCaffeine = true }
                checkItem("Mood", icon: "face.smiling.fill", color: .lilac, done: completion.mood) { showLogMood = true }
            }
        }
        .padding(16).background(cardBackground)
    }

    private func checkItem(_ label: String, icon: String, color: Color, done: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { if !done { action() } }) {
            VStack(spacing: 7) {
                ZStack {
                    Circle().fill(done ? color.opacity(0.14) : Color.white.opacity(0.04)).frame(width: 42, height: 42)
                        .overlay(Circle().stroke(done ? color.opacity(0.4) : Color.surfaceLine, lineWidth: done ? 1.5 : 1))
                    Image(systemName: done ? "checkmark" : icon).font(.system(size: done ? 14 : 17, weight: .semibold)).foregroundStyle(done ? color : Color.ink2)
                }
                Text(label).font(.system(size: 11, weight: done ? .bold : .regular, design: .rounded)).foregroundStyle(done ? color : Color.ink2)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(done ? color.opacity(0.06) : Color.surface2).overlay(RoundedRectangle(cornerRadius: 14).stroke(done ? color.opacity(0.2) : Color.clear, lineWidth: 1)))
        }
        .buttonStyle(.plain).animation(.spring(response: 0.3), value: done)
    }

    // MARK: - Sleep Chart
    private var sleepChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "SLEEP — LAST 7 DAYS"); Spacer()
                if let g = goal { HStack(spacing: 4) { Rectangle().fill(Color.amber.opacity(0.5)).frame(width: 12, height: 1.5); Text("Goal \(String(format: "%.1f", g.targetHours))h").font(.system(size: 9, design: .rounded)).foregroundStyle(Color.ink2) } }
            }
            VStack(spacing: 8) { ForEach(recentSleeps) { SleepBarRow(entry: $0, max: max(maxSleep, 9)) } }
        }
        .padding(18).background(cardBackground)
    }

    // MARK: - Caffeine Live
    private var caffeineLiveCard: some View {
        Button { showCaffCalc = true } label: {
            HStack(spacing: 12) {
                ZStack { RoundedRectangle(cornerRadius: 10).fill(Color.amber.opacity(0.1)).frame(width: 36, height: 36); Image(systemName: "cup.and.heat.waves.fill").font(.system(size: 15)).foregroundStyle(Color.amber) }
                VStack(alignment: .leading, spacing: 2) {
                    Text("CAFFEINE IN BODY").font(.system(size: 9, weight: .black, design: .rounded)).tracking(2).foregroundStyle(Color.ink2)
                    Text("\(Int(currentCaffeineInBody))mg active right now").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(currentCaffeineInBody > 100 ? Color.coral : currentCaffeineInBody > 25 ? Color.amber : Color.mint)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Color.ink2)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.amber.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.amber.opacity(0.2), lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tip
    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "RESEARCH TIP"); Spacer()
                if tips.count > 1 { Button { withAnimation(.spring(response: 0.4)) { tipIndex = (tipIndex + 1) % tips.count } } label: { HStack(spacing: 3) { Text("Next").font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(Color.ink2); Image(systemName: "arrow.right").font(.system(size: 9)).foregroundStyle(Color.ink2) } } }
            }
            if tips.indices.contains(tipIndex) { TipCard(tip: tips[tipIndex]).id(tipIndex).transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity))) }
        }
    }

    // MARK: - Quick Actions
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "TOOLS")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                quickBtn("target",                     "Goal",        .amber)  { showGoal = true }
                quickBtn("scalemass.fill",             "Debt Plan",   .coral)  { showDebtPayoff = true }
                quickBtn("questionmark.circle.fill",   "What If",     .lilac)  { showWhatIf = true }
                quickBtn("sparkles",                   "Analysis",    .mint)   { showCorrelation = true }
                quickBtn(chronotype != nil ? "arrow.triangle.2.circlepath" : "pawprint.fill",
                         chronotype != nil ? "Retype" : "Chronotype", .lilac)  { showChronotype = true }
                quickBtn("cup.and.heat.waves.fill",    "Caffeine",    .amber)  { showCaffCalc = true }
                quickBtn("zzz",                        "Nap",         .sky)    { showLogNap = true }
                quickBtn("mic.fill",                   "Siri",        .sky)    { showSiri = true }
            }
        }
    }

    private func quickBtn(_ icon: String, _ label: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(color)
                Text(label).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(Color.ink2)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.08)).overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.18), lineWidth: 1)))
        }.buttonStyle(.plain)
    }

    // MARK: - Log Buttons
    private var logButtons: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "LOG ENTRY")
            HStack(spacing: 10) {
                logBtn("moon.fill", "Sleep", .sky) { showLogSleep = true }
                logBtn("cup.and.heat.waves.fill", "Caffeine", .amber) { showLogCaffeine = true }
                logBtn("face.smiling.fill", "Mood", .lilac) { showLogMood = true }
            }
        }
    }

    private func logBtn(_ icon: String, _ label: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                ZStack { RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.10)).frame(width: 48, height: 48).overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1)); Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(color) }
                Text(label).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(Color.ink1)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.surface1).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.surfaceLine, lineWidth: 1)))
        }.buttonStyle(.plain)
    }

    // MARK: - Records check
    private func checkPersonalRecords() {
        let existing = Array((try? context.fetch(FetchDescriptor<PersonalRecord>())) ?? [])
        let results = PersonalRecordsService.check(sleeps: sleepEntries, caffeines: caffeineEntries, moods: moodEntries, currentScore: score, currentStreak: streak, existing: existing)
        for r in results {
            if let meta = PersonalRecordsService.recordMeta[r.type] {
                let pr = existing.first { $0.recordType == r.type }
                if let pr { pr.value = r.newValue; pr.achievedAt = Date() }
                else { context.insert(PersonalRecord(recordType: r.type, value: r.newValue)) }
                if r.isNew || r.newValue > r.oldValue + 1 {
                    withAnimation { newRecordMessage = "New record: \(meta.label) — \(meta.format(r.newValue)) 🏆" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) { withAnimation { newRecordMessage = nil } }
                }
            }
        }
    }
}

