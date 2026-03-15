import SwiftUI
import SwiftData

// MARK: - Caffeine Half-Life Service
struct CaffeineHalfLifeService {
    static let halfLifeHours: Double = 5.7   // average adult half-life

    /// mg remaining in body at a given hour offset from now
    static func mgRemaining(initialMg: Double, consumedAt: Date, at checkTime: Date) -> Double {
        let hoursElapsed = checkTime.timeIntervalSince(consumedAt) / 3600
        guard hoursElapsed >= 0 else { return initialMg }
        return initialMg * pow(0.5, hoursElapsed / halfLifeHours)
    }

    /// Total caffeine from multiple entries at a given time
    static func totalRemaining(entries: [(mg: Double, time: Date)], at checkTime: Date) -> Double {
        entries.reduce(0) { $0 + mgRemaining(initialMg: $1.mg, consumedAt: $1.time, at: checkTime) }
    }

    /// Hour at which caffeine drops below threshold
    static func clearanceTime(entries: [(mg: Double, time: Date)], threshold: Double = 25) -> Date? {
        let start = entries.map(\.time).min() ?? Date()
        for h in 0..<48 {
            let checkTime = Calendar.current.date(byAdding: .hour, value: h, to: start) ?? start
            if totalRemaining(entries: entries, at: checkTime) < threshold { return checkTime }
        }
        return nil
    }

    /// Build 24-hour timeline of caffeine levels
    static func buildTimeline(entries: [(mg: Double, time: Date)], hoursAhead: Int = 18) -> [(hour: Date, mg: Double)] {
        guard !entries.isEmpty else { return [] }
        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -2, to: now) ?? now
        return (0..<(hoursAhead + 2)).map { offset in
            let t = Calendar.current.date(byAdding: .hour, value: offset, to: start) ?? start
            return (t, totalRemaining(entries: entries, at: t))
        }
    }
}

// MARK: - Caffeine Half-Life View
struct CaffeineHalfLifeView: View {
    @Query(sort: \CaffeineEntry.date, order: .reverse) var caffeineEntries: [CaffeineEntry]
    @State private var appeared = false

    // Today's entries as tuples
    private var todayEntries: [(mg: Double, time: Date)] {
        let today = Calendar.current.startOfDay(for: Date())
        return caffeineEntries
            .filter { Calendar.current.startOfDay(for: $0.date) == today }
            .map { ($0.mg, $0.time) }
    }

    private var currentCaffeine: Double {
        CaffeineHalfLifeService.totalRemaining(entries: todayEntries, at: Date())
    }

    private var timeline: [(hour: Date, mg: Double)] {
        CaffeineHalfLifeService.buildTimeline(entries: todayEntries)
    }

    private var clearanceTime: Date? {
        CaffeineHalfLifeService.clearanceTime(entries: todayEntries)
    }

    private var sleepImpact: String {
        if currentCaffeine < 25 { return "No impact on sleep tonight" }
        if currentCaffeine < 75 { return "Mild delay — ~15–30 min harder to fall asleep" }
        if currentCaffeine < 150 { return "Moderate — expect 30–60 min delayed sleep onset" }
        return "High — sleep quality will be significantly impacted tonight"
    }

    private var sleepImpactColor: Color {
        if currentCaffeine < 25 { return .mint }
        if currentCaffeine < 75 { return .amber }
        if currentCaffeine < 150 { return .amber }
        return .coral
    }

    private let tf: DateFormatter = { let f = DateFormatter(); f.dateFormat = "h:mm a"; return f }()
    private let shortTF: DateFormatter = { let f = DateFormatter(); f.dateFormat = "h a"; return f }()

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Current level card
                    currentLevelCard.stagger(appeared: appeared, delay: 0)

                    // Timeline graph
                    if !timeline.isEmpty {
                        timelineCard.stagger(appeared: appeared, delay: 0.08)
                    }

                    // Impact on tonight's sleep
                    sleepImpactCard.stagger(appeared: appeared, delay: 0.14)

                    // Today's breakdown
                    if !todayEntries.isEmpty {
                        todayBreakdownCard.stagger(appeared: appeared, delay: 0.20)
                    }

                    // Science explainer
                    scienceCard.stagger(appeared: appeared, delay: 0.26)

                    if todayEntries.isEmpty {
                        EmptyStateView(icon: "cup.and.heat.waves.fill",
                            title: "No caffeine logged today",
                            message: "Log your coffee or tea to see real-time caffeine levels in your body.")
                        .padding(.vertical, 30).stagger(appeared: appeared, delay: 0.08)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 24)
            }
        }
        .navigationTitle("Caffeine Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surface0, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { withAnimation { appeared = true } }
    }

    // MARK: - Current Level
    private var currentLevelCard: some View {
        HStack(spacing: 0) {
            // Big number
            VStack(spacing: 4) {
                Text("\(Int(currentCaffeine))")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(mgColor(currentCaffeine))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5), value: currentCaffeine)
                Text("mg now")
                    .font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink2)
            }
            .frame(maxWidth: .infinity)

            Rectangle().fill(Color.surfaceLine).frame(width: 1).padding(.vertical, 16)

            VStack(alignment: .leading, spacing: 12) {
                miniStat("Total today", "\(Int(todayEntries.reduce(0){$0+$1.mg}))mg", .amber)
                if let clear = clearanceTime {
                    miniStat("Clear by", tf.string(from: clear), .mint)
                }
                miniStat("Half-life", "5.7 hours", .sky)
            }
            .frame(maxWidth: .infinity).padding(.leading, 14)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22).fill(Color.surface1)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(mgColor(currentCaffeine).opacity(0.2), lineWidth: 1))
        )
        .overlay(alignment: .topTrailing) {
            Text(mgLabel(currentCaffeine))
                .font(.system(size: 9, weight: .black, design: .rounded)).tracking(1)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(mgColor(currentCaffeine).opacity(0.15)).overlay(Capsule().stroke(mgColor(currentCaffeine).opacity(0.3), lineWidth: 1)))
                .foregroundStyle(mgColor(currentCaffeine))
                .padding(14)
        }
    }

    private func miniStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.system(size: 8, weight: .black, design: .rounded)).tracking(1).foregroundStyle(Color.ink2)
            Text(value).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
        }
    }

    // MARK: - Timeline Graph
    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "CAFFEINE OVER TIME")
                Spacer()
                // Optimal sleep threshold marker label
                HStack(spacing: 4) {
                    Rectangle().fill(Color.mint.opacity(0.5)).frame(width: 12, height: 1.5)
                    Text("Sleep safe (<25mg)").font(.system(size: 9, design: .rounded)).foregroundStyle(Color.ink2)
                }
            }

            GeometryReader { geo in
                let maxMg = max(timeline.map(\.mg).max() ?? 200, 200)
                let w = geo.size.width / CGFloat(max(timeline.count - 1, 1))
                let h = geo.size.height
                let now = Date()
                let nowX: CGFloat = {
                    if let nowIdx = timeline.indices.min(by: { abs(timeline[$0].hour.timeIntervalSince(now)) < abs(timeline[$1].hour.timeIntervalSince(now)) }) {
                        return CGFloat(nowIdx) * w
                    }
                    return 0
                }()

                ZStack(alignment: .bottomLeading) {
                    // Sleep safe line
                    let safeY = h - h * (25 / maxMg)
                    Path { p in p.move(to: CGPoint(x: 0, y: safeY)); p.addLine(to: CGPoint(x: geo.size.width, y: safeY)) }
                        .stroke(Color.mint.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

                    // Area fill (gradient past vs future)
                    Path { p in
                        guard !timeline.isEmpty else { return }
                        p.move(to: CGPoint(x: 0, y: h))
                        for (i, pt) in timeline.enumerated() {
                            let x = CGFloat(i) * w
                            let y = h - h * CGFloat(pt.mg / maxMg)
                            if i == 0 { p.addLine(to: CGPoint(x: x, y: y)) }
                            else { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                        p.addLine(to: CGPoint(x: CGFloat(timeline.count - 1) * w, y: h))
                        p.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [Color.amber.opacity(0.18), Color.amber.opacity(0.02)], startPoint: .top, endPoint: .bottom))

                    // Line
                    Path { p in
                        for (i, pt) in timeline.enumerated() {
                            let x = CGFloat(i) * w
                            let y = h - h * CGFloat(pt.mg / maxMg)
                            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                            else { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(Color.amber, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    // "Now" vertical line
                    Path { p in p.move(to: CGPoint(x: nowX, y: 0)); p.addLine(to: CGPoint(x: nowX, y: h)) }
                        .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))

                    // "Now" dot on line
                    let nowMg = CaffeineHalfLifeService.totalRemaining(entries: todayEntries, at: now)
                    let nowY = h - h * CGFloat(nowMg / maxMg)
                    Circle().fill(Color.amber).frame(width: 8, height: 8)
                        .shadow(color: .amber, radius: 4)
                        .position(x: nowX, y: nowY)

                    // Time labels
                    HStack(spacing: 0) {
                        ForEach(Array(timeline.enumerated()), id: \.offset) { i, pt in
                            if i % 4 == 0 {
                                Text(shortTF.string(from: pt.hour))
                                    .font(.system(size: 8, design: .rounded)).foregroundStyle(Color.ink2)
                                    .frame(maxWidth: .infinity)
                            } else { Color.clear.frame(maxWidth: .infinity) }
                        }
                    }
                    .frame(width: geo.size.width)
                    .offset(y: h + 4)
                }
            }
            .frame(height: 130)
            .padding(.bottom, 18) // room for labels
        }
        .padding(18).background(cardBackground)
    }

    // MARK: - Sleep Impact
    private var sleepImpactCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(sleepImpactColor.opacity(0.10)).frame(width: 42, height: 42)
                Image(systemName: "moon.fill").font(.system(size: 17, weight: .semibold)).foregroundStyle(sleepImpactColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("TONIGHT'S SLEEP IMPACT").font(.system(size: 9, weight: .black, design: .rounded)).tracking(2).foregroundStyle(Color.ink2)
                Text(sleepImpact).font(.system(size: 13, design: .rounded)).foregroundStyle(Color.ink0).lineSpacing(3)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(sleepImpactColor.opacity(0.07)).overlay(RoundedRectangle(cornerRadius: 16).stroke(sleepImpactColor.opacity(0.2), lineWidth: 1)))
    }

    // MARK: - Today Breakdown
    private var todayBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "TODAY'S BREAKDOWN")
            ForEach(Array(todayEntries.enumerated()), id: \.offset) { _, entry in
                let remaining = CaffeineHalfLifeService.mgRemaining(initialMg: entry.mg, consumedAt: entry.time, at: Date())
                let pct = remaining / entry.mg
                HStack(spacing: 12) {
                    Image(systemName: "cup.and.heat.waves.fill").font(.system(size: 13)).foregroundStyle(Color.amber).frame(width: 18)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("\(Int(entry.mg))mg at \(tf.string(from: entry.time))")
                                .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Color.ink0)
                            Spacer()
                            Text("\(Int(remaining))mg left")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(mgColor(remaining))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.05))
                                RoundedRectangle(cornerRadius: 3).fill(Color.amber.opacity(0.5 + pct * 0.5))
                                    .frame(width: geo.size.width * pct)
                                    .animation(.spring(response: 0.6), value: pct)
                            }
                        }.frame(height: 4)
                    }
                }
                .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.surface2))
            }
        }
        .padding(18).background(cardBackground)
    }

    // MARK: - Science Card
    private var scienceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "THE SCIENCE")
            VStack(alignment: .leading, spacing: 8) {
                sciRow("Average half-life is 5.7 hours — meaning a 200mg coffee at 3 PM still has ~100mg active at 8:45 PM.")
                sciRow("Caffeine blocks adenosine receptors, preventing the sleepiness signal from reaching your brain — even when you feel tired.")
                sciRow("Research shows caffeine consumed 6+ hours before bed reduces total sleep time by ~1 hour.")
                sciRow("Genetics affect metabolism — ~10% of people process caffeine in 1.5h (fast metabolisers); others take 9+ hours.")
            }
        }
        .padding(18).background(cardBackground)
    }

    private func sciRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Color.amber.opacity(0.4)).frame(width: 4, height: 4).padding(.top, 5)
            Text(text).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink1).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Helpers
    private func mgColor(_ mg: Double) -> Color {
        if mg < 25 { return .mint }; if mg < 100 { return .amber }; return .coral
    }
    private func mgLabel(_ mg: Double) -> String {
        if mg < 25 { return "CLEAR" }; if mg < 100 { return "LOW" }; if mg < 200 { return "MODERATE" }; return "HIGH"
    }
}

