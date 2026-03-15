import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding")       private var hasCompletedOnboarding = true
    @AppStorage("hasCompletedPersonalization")  private var hasCompletedPersonalization = true
    @AppStorage("morningReminderHour")          private var morningHour: Int = 8
    @AppStorage("eveningReminderHour")          private var eveningHour: Int = 22
    @AppStorage("notificationsEnabled")         private var notificationsEnabled: Bool = true
    @AppStorage("smartBedtimeEnabled")          private var smartBedtimeEnabled: Bool = true
    @AppStorage("moodAwareEnabled")             private var moodAwareEnabled: Bool = true

    @Environment(\.modelContext) private var context
    @StateObject private var healthKit = HealthKitService.shared

    @Query(sort: \SleepGoal.createdAt, order: .reverse)          var goals: [SleepGoal]
    @Query(sort: \SleepEntry.date, order: .reverse)              var sleepEntries: [SleepEntry]
    @Query(sort: \CaffeineEntry.date, order: .reverse)           var caffeineEntries: [CaffeineEntry]
    @Query(sort: \MoodEntry.date, order: .reverse)               var moodEntries: [MoodEntry]
    @Query(sort: \NapEntry.date, order: .reverse)                var napEntries: [NapEntry]
    @Query(sort: \EarnedBadge.earnedAt, order: .reverse)         var earnedBadges: [EarnedBadge]
    @Query(sort: \PersonalRecord.achievedAt, order: .reverse)    var personalRecords: [PersonalRecord]
    @Query(sort: \ChallengeProgress.startDate)                   var challengeProgresses: [ChallengeProgress]
    @Query(sort: \ChronotypeResult.completedAt, order: .reverse) var chronotypes: [ChronotypeResult]
    @Query(sort: \JournalEntry.date, order: .reverse)            var journalEntries: [JournalEntry]

    @State private var showResetConfirm      = false
    @State private var showGoal              = false
    @State private var showNapTracker        = false
    @State private var showCorrelation       = false
    @State private var showWeeklyReport      = false
    @State private var showDebtPayoff        = false
    @State private var showWhatIf            = false
    @State private var showChronotype        = false
    @State private var showCaffeineCalc      = false
    @State private var showSiri              = false
    @State private var isSyncing             = false

    private var goal: SleepGoal? { goals.first }
    private var streak: Int { StreakService.currentStreak(sleeps: sleepEntries, caffeines: caffeineEntries, moods: moodEntries) }
    private var longest: Int { StreakService.longestStreak(sleeps: sleepEntries, caffeines: caffeineEntries, moods: moodEntries) }
    private var debt: Double { SleepAnalysisService.cumulativeDebt(from: sleepEntries) }
    private var chronotype: Chronotype? { chronotypes.first.map { Chronotype.from(id: $0.chronotype) } }

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            List {

                // MARK: Stats
                Section {
                    statsRow("flame.fill",          "Current Streak",    "\(streak) days",    .amber)
                    statsRow("crown.fill",           "Longest Streak",    "\(longest) days",   .amber)
                    statsRow("trophy.fill",          "Badges Earned",     "\(earnedBadges.count)", .amber)
                    statsRow("moon.fill",            "Sleep Entries",     "\(sleepEntries.count)", .sky)
                    statsRow("pencil.line",          "Journal Entries",   "\(journalEntries.count)", .lilac)
                    statsRow("checkmark.seal.fill",  "Challenges Done",   "\(challengeProgresses.filter { $0.isCompleted }.count)", .mint)
                    if let ct = chronotype {
                        statsRow("pawprint.fill", "Chronotype", "\(ct.animal) \(ct.name)", ct.color)
                    }
                } header: { sh("YOUR STATS") }
                .listRowBackground(Color.surface1)

                // MARK: Features
                Section {
                    navRow("target",                   "Sleep Goal",           goal != nil ? "Set to \(String(format: "%.1f", goal?.targetHours ?? 0))h" : "Not set", .amber) { showGoal = true }
                    navRow("scalemass.fill",            "Debt Payoff Plan",     "Recover \(String(format: "%.1f", debt))h", .coral) { showDebtPayoff = true }
                    navRow("questionmark.circle.fill",  "What If Simulator",   "Predict tonight's score", .lilac) { showWhatIf = true }
                    navRow("cup.and.heat.waves.fill",   "Caffeine Calculator",  "Real-time caffeine levels", .amber) { showCaffeineCalc = true }
                    navRow("pawprint.fill",             "Chronotype Quiz",      chronotype != nil ? "\(chronotype!.animal) You're a \(chronotype!.name)" : "Discover your sleep type", .lilac) { showChronotype = true }
                    navRow("zzz",                       "Nap Tracker",          "\(napEntries.count) naps logged", .sky) { showNapTracker = true }
                    navRow("sparkles",                  "Smart Analysis",       "Correlation finder", .mint) { showCorrelation = true }
                    navRow("chart.bar.doc.horizontal",  "Weekly Report",        "View trends", .sky) { showWeeklyReport = true }
                    navRow("mic.fill",                  "Siri Shortcuts",       "Set up voice commands", .sky) { showSiri = true }
                } header: { sh("FEATURES") }
                .listRowBackground(Color.surface1)

                // MARK: HealthKit
                if healthKit.isAvailable {
                    Section {
                        HStack { label("heart.fill", "HealthKit Sync", color: .coral); Spacer(); Text(healthKit.isAuthorized ? "Connected" : "Not connected").font(.system(size: 12, design: .rounded)).foregroundStyle(healthKit.isAuthorized ? .mint : Color.ink2) }
                        if !healthKit.isAuthorized {
                            Button { Task { await healthKit.requestAuthorization() } } label: { label("lock.open.fill", "Connect HealthKit", color: .coral) }
                        } else {
                            Button {
                                isSyncing = true
                                Task { await healthKit.syncSleep(context: context); isSyncing = false }
                            } label: {
                                HStack { label("arrow.triangle.2.circlepath", isSyncing ? "Syncing…" : "Sync Sleep Data", color: .coral); if isSyncing { Spacer(); ProgressView().tint(.coral) } }
                            }
                        }
                    } header: { sh("HEALTH") }
                    .listRowBackground(Color.surface1)
                }

                // MARK: Notifications
                Section {
                    Toggle(isOn: $notificationsEnabled) { label("bell.fill", "Daily Reminders", color: .lilac) }.tint(.lilac)
                        .onChange(of: notificationsEnabled) { _, v in
                            if v { NotificationService.requestPermission(); NotificationService.scheduleDailyReminders(morningHour: morningHour, eveningHour: eveningHour) }
                            else { UNUserNotificationCenter.current().removeAllPendingNotificationRequests() }
                        }
                    if notificationsEnabled {
                        HStack { label("sun.horizon.fill", "Morning", color: .amber); Spacer(); Picker("", selection: $morningHour) { ForEach(5...11, id: \.self) { Text("\($0):00").tag($0) } }.tint(.amber).onChange(of: morningHour) { _, _ in reschedule() } }
                        HStack { label("moon.fill", "Evening", color: .sky); Spacer(); Picker("", selection: $eveningHour) { ForEach(18...23, id: \.self) { Text("\($0):00").tag($0) } }.tint(.sky).onChange(of: eveningHour) { _, _ in reschedule() } }
                    }
                    Toggle(isOn: $smartBedtimeEnabled) { label("moon.stars.fill", "Smart Bedtime Reminder", color: .sky) }.tint(.sky)
                        .onChange(of: smartBedtimeEnabled) { _, v in
                            if v { SmartBedtimeService.scheduleSmartReminder(debt: debt, goal: goal) }
                            else { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["smart_bedtime"]) }
                        }
                    Toggle(isOn: $moodAwareEnabled) { label("face.smiling.fill", "Mood-Aware Notifications", color: .lilac) }.tint(.lilac)
                        .onChange(of: moodAwareEnabled) { _, v in
                            if v { MoodAwareNotificationService.scheduleEveningNotification(recentMoods: Array(moodEntries.prefix(3)), streak: streak) }
                            else { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["mood_aware_evening"]) }
                        }
                } header: { sh("NOTIFICATIONS") }
                .listRowBackground(Color.surface1)

                // MARK: Data
                Section {
                    Button { withAnimation { hasCompletedPersonalization = false } } label: { label("person.crop.circle.badge.questionmark", "Redo Personalization", color: .sky) }
                    Button { withAnimation { hasCompletedOnboarding = false } } label: { label("arrow.counterclockwise", "Replay Onboarding", color: .sky) }
                    Button(role: .destructive) { showResetConfirm = true } label: { label("trash.fill", "Delete All Data", color: .coral) }
                } header: { sh("DATA") }
                .listRowBackground(Color.surface1)

                Section {
                    HStack { label("info.circle.fill", "Version", color: .sky); Spacer(); Text("4.0.0").font(.system(size: 14, design: .rounded)).foregroundStyle(Color.ink2) }
                } header: { sh("ABOUT") }
                .listRowBackground(Color.surface1)
            }
            .scrollContentBackground(.hidden).background(Color.surface0)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surface0, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showGoal)         { SleepGoalView() }
        .sheet(isPresented: $showNapTracker)   { NavigationStack { NapTrackerView() } }
        .sheet(isPresented: $showCorrelation)  { NavigationStack { CorrelationView() } }
        .sheet(isPresented: $showWeeklyReport) { NavigationStack { WeeklyReportView() } }
        .sheet(isPresented: $showDebtPayoff)   { NavigationStack { DebtPayoffView() } }
        .sheet(isPresented: $showWhatIf)       { NavigationStack { WhatIfSimulatorView() } }
        .sheet(isPresented: $showChronotype)   { ChronotypeQuizView() }
        .sheet(isPresented: $showCaffeineCalc) { NavigationStack { CaffeineHalfLifeView() } }
        .sheet(isPresented: $showSiri)         { NavigationStack { SiriShortcutsView() } }
        .confirmationDialog("Delete all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Delete Everything", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will permanently remove all entries, challenges, badges, journal, and records.") }
    }

    private func sh(_ t: String) -> some View {
        Text(t).font(.system(size: 11, weight: .black, design: .rounded)).tracking(2).foregroundStyle(Color.ink2)
    }
    private func label(_ icon: String, _ text: String, color: Color) -> some View {
        Label { Text(text).font(.system(size: 15, design: .rounded)).foregroundStyle(Color.ink0) } icon: { Image(systemName: icon).foregroundStyle(color) }
    }
    private func statsRow(_ icon: String, _ lbl: String, _ val: String, _ color: Color) -> some View {
        HStack { Image(systemName: icon).foregroundStyle(color).frame(width: 22); Text(lbl).font(.system(size: 15, design: .rounded)).foregroundStyle(Color.ink0); Spacer(); Text(val).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Color.ink1) }
    }
    private func navRow(_ icon: String, _ title: String, _ sub: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) { HStack { Image(systemName: icon).foregroundStyle(color).frame(width: 22); VStack(alignment: .leading, spacing: 2) { Text(title).font(.system(size: 15, design: .rounded)).foregroundStyle(Color.ink0); Text(sub).font(.system(size: 11, design: .rounded)).foregroundStyle(Color.ink2) }; Spacer(); Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Color.ink2) } }
    }
    private func reschedule() {
        if notificationsEnabled { NotificationService.scheduleDailyReminders(morningHour: morningHour, eveningHour: eveningHour) }
    }
    private func deleteAll() {
        try? context.delete(model: SleepEntry.self); try? context.delete(model: CaffeineEntry.self)
        try? context.delete(model: MoodEntry.self);  try? context.delete(model: NapEntry.self)
        try? context.delete(model: SleepGoal.self);  try? context.delete(model: ChallengeProgress.self)
        try? context.delete(model: EarnedBadge.self); try? context.delete(model: PersonalRecord.self)
        try? context.delete(model: JournalEntry.self); try? context.delete(model: ChronotypeResult.self)
        try? context.delete(model: OnboardingProfile.self)
    }
}

