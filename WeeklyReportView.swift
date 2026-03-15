import SwiftUI
import SwiftData

struct WeeklyReportView: View {
    @Query(sort: \SleepEntry.date, order: .reverse)    var sleepEntries: [SleepEntry]
    @Query(sort: \CaffeineEntry.date, order: .reverse) var caffeineEntries: [CaffeineEntry]
    @Query(sort: \MoodEntry.date, order: .reverse)     var moodEntries: [MoodEntry]
    @Query(sort: \SleepGoal.createdAt, order: .reverse) var goals: [SleepGoal]

    @State private var selectedWeek = 0  // 0 = this week, 1 = last week, etc.
    @State private var appeared = false

    private var goal: SleepGoal? { goals.first }

    private var weekRange: (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        let weekStart = cal.date(byAdding: .weekOfYear, value: -selectedWeek, to: cal.startOfWeek(for: now)) ?? now
        let weekEnd = cal.date(byAdding: .day, value: 6, to: weekStart) ?? now
        return (weekStart, weekEnd)
    }

    private var weekSleeps: [SleepEntry] {
        let r = weekRange
        return sleepEntries.filter { $0.date >= r.start && $0.date <= r.end }
    }
    private var weekCaffeines: [CaffeineEntry] {
        let r = weekRange
        return caffeineEntries.filter { $0.date >= r.start && $0.date <= r.end }
    }
    private var weekMoods: [MoodEntry] {
        let r = weekRange
        return moodEntries.filter { $0.date >= r.start && $0.date <= r.end }
    }

    private var avgSleep: Double {
        guard !weekSleeps.isEmpty else { return 0 }
        return weekSleeps.map(\.duration).reduce(0, +) / Double(weekSleeps.count)
    }
    private var avgMood: Double {
        guard !weekMoods.isEmpty else { return 0 }
        return Double(weekMoods.map(\.score).reduce(0, +)) / Double(weekMoods.count)
    }
    private var totalCaffeine: Double { weekCaffeines.reduce(0) { $0 + $1.mg } }
    private var avgCaffeine: Double {
        guard !weekCaffeines.isEmpty else { return 0 }
        return totalCaffeine / Double(Set(weekCaffeines.map { Calendar.current.startOfDay(for: $0.date) }).count)
    }
    private var totalDebt: Double {
        weekSleeps.reduce(0) { $0 + SleepAnalysisService.dailyDebt(for: $1.duration) }
    }
    private var bestSleep: SleepEntry? { weekSleeps.max(by: { $0.duration < $1.duration }) }
    private var worstSleep: SleepEntry? { weekSleeps.min(by: { $0.duration < $1.duration }) }
    private var consistency: Double { SleepAnalysisService.sleepConsistency(from: weekSleeps) }
    private var weekScore: Int {
        let debt = SleepAnalysisService.cumulativeDebt(from: weekSleeps)
        return EnergyScoreService.calculate(sleepDebt: debt, todayCaffeine: avgCaffeine,
            latestMood: weekMoods.first?.score, lastSleepDuration: avgSleep, caffeineAfter2pm: 0)
    }

    // Compare with previous week
    private var prevWeekSleeps: [SleepEntry] {
        let prevRange: (start: Date, end: Date) = {
            let cal = Calendar.current
            let now = Date()
            let prevStart = cal.date(byAdding: .weekOfYear, value: -(selectedWeek + 1), to: cal.startOfWeek(for: now)) ?? now
            let prevEnd = cal.date(byAdding: .day, value: 6, to: prevStart) ?? now
            return (prevStart, prevEnd)
        }()
        return sleepEntries.filter { $0.date >= prevRange.start && $0.date <= prevRange.end }
    }
    private var prevAvgSleep: Double {
        guard !prevWeekSleeps.isEmpty else { return 0 }
        return prevWeekSleeps.map(\.duration).reduce(0, +) / Double(prevWeekSleeps.count)
    }
    private var sleepTrend: Double { avgSleep - prevAvgSleep }

    private var weekLabel: String {
        if selectedWeek == 0 { return "This Week" }
        if selectedWeek == 1 { return "Last Week" }
        return "\(selectedWeek) weeks ago"
    }

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f
    }()

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Week Selector
                    HStack(spacing: 16) {
                        Button {
                            withAnimation { selectedWeek += 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.ink1)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color.surface2))
                        }
                        VStack(spacing: 2) {
                            Text(weekLabel)
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(Color.ink0)
                            Text("\(dayFormatter.string(from: weekRange.start)) – \(dayFormatter.string(from: weekRange.end))")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(Color.ink2)
                        }
                        .frame(maxWidth: .infinity)
                        Button {
                            if selectedWeek > 0 { withAnimation { selectedWeek -= 1 } }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(selectedWeek > 0 ? Color.ink1 : Color.ink2.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color.surface2))
                        }
                        .disabled(selectedWeek == 0)
                    }
                    .padding(16)
                    .background(cardBackground)
                    .stagger(appeared: appeared, delay: 0)

                    // Week Score Card
                    weekScoreCard
                        .stagger(appeared: appeared, delay: 0.05)

                    // Key Stats Row
                    keyStatsRow
                        .stagger(appeared: appeared, delay: 0.1)

                    // Sleep Bar Chart
                    if !weekSleeps.isEmpty {
                        sleepChartCard
                            .stagger(appeared: appeared, delay: 0.15)
                    }

                    // Goal Progress
                    if let g = goal {
                        goalProgressCard(goal: g)
                            .stagger(appeared: appeared, delay: 0.2)
                    }

                    // Highlights
                    if !weekSleeps.isEmpty {
                        highlightsCard
                            .stagger(appeared: appeared, delay: 0.25)
                    }

                    // Empty state
                    if weekSleeps.isEmpty && weekMoods.isEmpty && weekCaffeines.isEmpty {
                        EmptyStateView(icon: "calendar.badge.clock",
                            title: "No data this week",
                            message: "Log sleep, caffeine and mood to see your weekly report.")
                        .padding(.vertical, 50)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Weekly Report")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surface0, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { withAnimation { appeared = true } }
    }

    // MARK: - Week Score Card
    private var weekScoreCard: some View {
        HStack(spacing: 20) {
            // Score circle
            ZStack {
                Circle().stroke(Color.surfaceLine, lineWidth: 8).frame(width: 90, height: 90)
                Circle()
                    .trim(from: 0, to: CGFloat(weekScore) / 100)
                    .stroke(AngularGradient(colors: [weekScore.scoreColor.opacity(0.5), weekScore.scoreColor],
                        center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 90, height: 90).rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(weekScore)").font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(weekScore.scoreColor)
                    Text("AVG").font(.system(size: 9, weight: .black, design: .rounded)).tracking(2).foregroundStyle(Color.ink2)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                trendRow("moon.fill", "Avg Sleep", String(format: "%.1fh", avgSleep),
                    trendVal: sleepTrend, suffix: "h vs last week", color: .sky)
                trendRow("face.smiling", "Avg Mood", avgMood > 0 ? String(format: "%.1f/10", avgMood) : "—",
                    trendVal: nil, suffix: "", color: .lilac)
                trendRow("flame.fill", "Sleep Debt", String(format: "%.1fh", totalDebt),
                    trendVal: nil, suffix: "this week", color: totalDebt > 5 ? .coral : .mint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(cardBackground)
    }

    private func trendRow(_ icon: String, _ label: String, _ value: String, trendVal: Double?, suffix: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(color).frame(width: 16)
            Text(label).font(.system(size: 11, design: .rounded)).foregroundStyle(Color.ink2)
            Spacer()
            Text(value).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
            if let t = trendVal, t != 0 {
                HStack(spacing: 2) {
                    Image(systemName: t > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                    Text(String(format: "%.1f\(suffix)", abs(t)))
                        .font(.system(size: 10, design: .rounded))
                }
                .foregroundStyle(t > 0 ? Color.mint : Color.coral)
            }
        }
    }

    // MARK: - Key Stats Row
    private var keyStatsRow: some View {
        HStack(spacing: 10) {
            miniStatCard("Consistency", value: "\(Int(consistency))%",
                icon: "arrow.triangle.2.circlepath", color: consistency > 75 ? .mint : .amber)
            miniStatCard("Logged Days", value: "\(weekSleeps.count)/7",
                icon: "checkmark.circle.fill", color: .sky)
            miniStatCard("Avg Caffeine", value: "\(Int(avgCaffeine))mg",
                icon: "cup.and.heat.waves.fill", color: .amber)
        }
    }

    private func miniStatCard(_ label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(color)
            Text(value).font(.system(size: 16, weight: .black, design: .rounded)).foregroundStyle(Color.ink0)
            Text(label).font(.system(size: 10, design: .rounded)).foregroundStyle(Color.ink2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(cardBackground)
    }

    // MARK: - Sleep Chart
    private var sleepChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "SLEEP BY DAY")
                Spacer()
                if let g = goal {
                    HStack(spacing: 4) {
                        Rectangle().fill(Color.amber.opacity(0.5)).frame(width: 16, height: 1.5)
                        Text("Goal \(String(format: "%.1f", g.targetHours))h")
                            .font(.system(size: 10, design: .rounded)).foregroundStyle(Color.ink2)
                    }
                }
            }
            GeometryReader { geo in
                let maxH = max((weekSleeps.map(\.duration).max() ?? 9), goal?.targetHours ?? 0, 9)
                ZStack(alignment: .bottomLeading) {
                    // Goal line
                    if let g = goal {
                        Rectangle()
                            .fill(Color.amber.opacity(0.4))
                            .frame(height: 1)
                            .offset(y: -geo.size.height * CGFloat(g.targetHours / maxH))
                    }
                    // Bars
                    HStack(alignment: .bottom, spacing: 6) {
                        let days = buildDayBars()
                        ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                            VStack(spacing: 4) {
                                if day.hours > 0 {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(day.color)
                                        .frame(height: geo.size.height * CGFloat(day.hours / maxH))
                                } else {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.white.opacity(0.05))
                                        .frame(height: geo.size.height * 0.05)
                                }
                                Text(day.label)
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.ink2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 130)
        }
        .padding(18)
        .background(cardBackground)
    }

    private func buildDayBars() -> [(label: String, hours: Double, color: Color)] {
        let cal = Calendar.current
        let fmt = DateFormatter(); fmt.dateFormat = "EEE"
        return (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: offset, to: weekRange.start) ?? weekRange.start
            let dayStart = cal.startOfDay(for: day)
            let entry = weekSleeps.first { cal.startOfDay(for: $0.date) == dayStart }
            let h = entry?.duration ?? 0
            let color: Color = h >= (goal?.targetHours ?? 7) ? .mint : h >= 5 ? .amber : h > 0 ? .coral : .surface2
            return (fmt.string(from: day).uppercased(), h, color)
        }
    }

    // MARK: - Goal Progress
    private func goalProgressCard(goal: SleepGoal) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "GOAL PROGRESS")
            let daysHit = weekSleeps.filter { $0.duration >= goal.targetHours }.count
            let pct = weekSleeps.isEmpty ? 0.0 : Double(daysHit) / Double(max(weekSleeps.count, 1))

            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(Color.surfaceLine, lineWidth: 6).frame(width: 70, height: 70)
                    Circle().trim(from: 0, to: pct)
                        .stroke(pct >= 0.7 ? Color.mint : Color.amber, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 70, height: 70).rotationEffect(.degrees(-90))
                    Text("\(daysHit)/\(weekSleeps.count)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(Color.ink0)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target: \(String(format: "%.1f", goal.targetHours))h per night")
                        .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
                    Text("Hit goal \(daysHit) out of \(weekSleeps.count) logged days")
                        .font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink1)
                    if daysHit == weekSleeps.count && weekSleeps.count >= 5 {
                        Label("Perfect week!", systemImage: "trophy.fill")
                            .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Color.amber)
                    }
                }
                Spacer()
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    // MARK: - Highlights
    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "WEEK HIGHLIGHTS")
            VStack(spacing: 10) {
                if let best = bestSleep {
                    highlightRow("Best night", icon: "star.fill", color: .mint,
                        value: String(format: "%.1fh", best.duration),
                        detail: dayFormatter.string(from: best.date))
                }
                if let worst = worstSleep {
                    highlightRow("Shortest night", icon: "exclamationmark.circle.fill", color: .coral,
                        value: String(format: "%.1fh", worst.duration),
                        detail: dayFormatter.string(from: worst.date))
                }
                highlightRow("Consistency score", icon: "arrow.triangle.2.circlepath", color: .sky,
                    value: "\(Int(consistency))%", detail: consistency > 75 ? "Good rhythm" : "Needs work")
                if totalCaffeine > 0 {
                    highlightRow("Total caffeine", icon: "cup.and.heat.waves.fill", color: .amber,
                        value: "\(Int(totalCaffeine))mg", detail: "~\(Int(avgCaffeine))mg per day")
                }
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    private func highlightRow(_ label: String, icon: String, color: Color, value: String, detail: String) -> some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.1)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(color)
            }
            Text(label).font(.system(size: 13, design: .rounded)).foregroundStyle(Color.ink1)
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(value).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
                Text(detail).font(.system(size: 10, design: .rounded)).foregroundStyle(Color.ink2)
            }
        }
    }
}



