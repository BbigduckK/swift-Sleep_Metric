import SwiftUI
import SwiftData

// MARK: - Correlation Service
struct CorrelationService {
    struct Finding: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
        let strength: Double   // 0–1, higher = stronger correlation
        let direction: Direction
        let color: Color
        enum Direction { case positive, negative, neutral }
    }

    static func analyze(sleeps: [SleepEntry], caffeines: [CaffeineEntry], moods: [MoodEntry]) -> [Finding] {
        var findings: [Finding] = []
        let cal = Calendar.current

        // Build day-by-day dataset
        guard sleeps.count >= 5 else { return [tooFewDataFinding] }

        var dayData: [(sleep: Double, caffeine: Double, lateCaffeine: Double, mood: Int?, bedHour: Double)] = []
        for sleep in sleeps.prefix(30) {
            let day = cal.startOfDay(for: sleep.date)
            let caffeineMg = caffeines.filter { cal.startOfDay(for: $0.date) == day }.reduce(0) { $0 + $1.mg }
            let lateMg = caffeines.filter { cal.startOfDay(for: $0.date) == day && cal.component(.hour, from: $0.time) >= 14 }.reduce(0) { $0 + $1.mg }
            let mood = moods.first { cal.startOfDay(for: $0.date) == day }?.score
            let bedH = Double(cal.component(.hour, from: sleep.bedtime)) + Double(cal.component(.minute, from: sleep.bedtime)) / 60
            dayData.append((sleep.duration, caffeineMg, lateMg, mood, bedH))
        }

        // 1. Late caffeine vs sleep duration
        let lateCaffDays = dayData.filter { $0.lateCaffeine > 0 }
        let noLateCaffDays = dayData.filter { $0.lateCaffeine == 0 }
        if lateCaffDays.count >= 3 && noLateCaffDays.count >= 3 {
            let avgWithLate = lateCaffDays.map(\.sleep).reduce(0, +) / Double(lateCaffDays.count)
            let avgWithout = noLateCaffDays.map(\.sleep).reduce(0, +) / Double(noLateCaffDays.count)
            let diff = avgWithout - avgWithLate
            if abs(diff) > 0.3 {
                findings.append(Finding(
                    icon: "cup.and.heat.waves.fill",
                    title: "Late Caffeine Costs You \(String(format: "%.1f", abs(diff)))h",
                    body: "On days you have caffeine after 2 PM, you sleep \(String(format: "%.1f", abs(diff)))h less on average (\(String(format: "%.1f", avgWithLate))h vs \(String(format: "%.1f", avgWithout))h without).",
                    strength: min(abs(diff) / 2.0, 1.0),
                    direction: diff > 0 ? .negative : .neutral,
                    color: .amber))
            }
        }

        // 2. Bedtime hour vs sleep duration
        let earlyBed = dayData.filter { $0.bedHour < 23 }
        let lateBed = dayData.filter { $0.bedHour >= 23 }
        if earlyBed.count >= 3 && lateBed.count >= 3 {
            let avgEarly = earlyBed.map(\.sleep).reduce(0, +) / Double(earlyBed.count)
            let avgLate = lateBed.map(\.sleep).reduce(0, +) / Double(lateBed.count)
            let diff = avgEarly - avgLate
            if abs(diff) > 0.4 {
                findings.append(Finding(
                    icon: "moon.fill",
                    title: "Earlier Bedtime = \(String(format: "%.1f", abs(diff)))h More Sleep",
                    body: "When you sleep before 11 PM, you average \(String(format: "%.1f", avgEarly))h of sleep vs \(String(format: "%.1f", avgLate))h when you sleep later.",
                    strength: min(abs(diff) / 2.5, 1.0),
                    direction: .positive,
                    color: .sky))
            }
        }

        // 3. Sleep vs mood (next-day mood effect)
        let moodDays = dayData.filter { $0.mood != nil }
        if moodDays.count >= 5 {
            let goodSleepMood = moodDays.filter { $0.sleep >= 7 }.compactMap(\.mood)
            let badSleepMood = moodDays.filter { $0.sleep < 6 }.compactMap(\.mood)
            if goodSleepMood.count >= 2 && badSleepMood.count >= 2 {
                let avgGood = Double(goodSleepMood.reduce(0, +)) / Double(goodSleepMood.count)
                let avgBad = Double(badSleepMood.reduce(0, +)) / Double(badSleepMood.count)
                let diff = avgGood - avgBad
                if abs(diff) > 0.8 {
                    findings.append(Finding(
                        icon: "face.smiling.fill",
                        title: "Sleep Quality Moves Your Mood \(String(format: "+%.1f", diff)) Points",
                        body: "Your mood averages \(String(format: "%.1f", avgGood))/10 after 7h+ sleep, vs \(String(format: "%.1f", avgBad))/10 after under 6h.",
                        strength: min(abs(diff) / 5.0, 1.0),
                        direction: .positive,
                        color: .lilac))
                }
            }
        }

        // 4. Consistency vs average sleep
        let consistency = SleepAnalysisService.sleepConsistency(from: Array(sleeps.prefix(14)))
        let avgSleep = sleeps.prefix(7).map(\.duration).reduce(0, +) / Double(min(sleeps.count, 7))
        if consistency < 60 && avgSleep < 7 {
            findings.append(Finding(
                icon: "waveform.path.ecg",
                title: "Irregular Schedule Draining Your Sleep",
                body: "Your bedtime consistency is \(Int(consistency))%. Research shows irregular schedules reduce sleep quality even if total hours seem adequate.",
                strength: (60 - consistency) / 60,
                direction: .negative,
                color: .coral))
        }

        // 5. Caffeine total vs mood
        let highCaffDays = dayData.filter { $0.caffeine > 300 }.compactMap(\.mood)
        let normalCaffDays = dayData.filter { $0.caffeine <= 300 && $0.caffeine > 0 }.compactMap(\.mood)
        if highCaffDays.count >= 3 && normalCaffDays.count >= 3 {
            let avgHigh = Double(highCaffDays.reduce(0, +)) / Double(highCaffDays.count)
            let avgNormal = Double(normalCaffDays.reduce(0, +)) / Double(normalCaffDays.count)
            let diff = avgNormal - avgHigh
            if abs(diff) > 0.7 {
                findings.append(Finding(
                    icon: "bolt.fill",
                    title: "High Caffeine Days Correlate with Lower Mood",
                    body: "On days with 300mg+ caffeine, your mood averages \(String(format: "%.1f", avgHigh))/10 vs \(String(format: "%.1f", avgNormal))/10 on normal days.",
                    strength: min(abs(diff) / 4.0, 1.0),
                    direction: .negative,
                    color: .amber))
            }
        }

        if findings.isEmpty { findings.append(tooFewDataFinding) }
        return findings.sorted { $0.strength > $1.strength }
    }

    private static var tooFewDataFinding: Finding {
        Finding(icon: "chart.line.uptrend.xyaxis",
            title: "Keep Logging to Unlock Correlations",
            body: "You need at least 5 days of sleep data for patterns to emerge. The more you log, the more precise your personal insights become.",
            strength: 0, direction: .neutral, color: .sky)
    }
}

// MARK: - Correlation View
struct CorrelationView: View {
    @Query(sort: \SleepEntry.date, order: .reverse)    var sleepEntries: [SleepEntry]
    @Query(sort: \CaffeineEntry.date, order: .reverse) var caffeineEntries: [CaffeineEntry]
    @Query(sort: \MoodEntry.date, order: .reverse)     var moodEntries: [MoodEntry]
    @State private var appeared = false

    private var findings: [CorrelationService.Finding] {
        CorrelationService.analyze(sleeps: Array(sleepEntries.prefix(30)),
            caffeines: Array(caffeineEntries.prefix(60)),
            moods: Array(moodEntries.prefix(30)))
    }

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header explanation
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.mint).frame(width: 44, height: 44).opacity(0.1)
                            Image(systemName: "sparkles").font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.mint)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Personal Patterns")
                                .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
                            Text("Based on your actual data — not generic advice. More days logged = more accurate findings.")
                                .font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink1).lineSpacing(3)
                        }
                    }
                    .padding(16)
                    .background(cardBackground)
                    .stagger(appeared: appeared, delay: 0)

                    // Data coverage
                    dataCoverageRow
                        .stagger(appeared: appeared, delay: 0.05)

                    // Findings
                    VStack(spacing: 12) {
                        ForEach(Array(findings.enumerated()), id: \.element.id) { i, finding in
                            FindingCard(finding: finding)
                                .stagger(appeared: appeared, delay: 0.1 + Double(i) * 0.07)
                        }
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 20)
            }
        }
        .navigationTitle("Smart Analysis")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surface0, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { withAnimation { appeared = true } }
    }

    private var dataCoverageRow: some View {
        HStack(spacing: 0) {
            coveragePill("moon.fill", "\(min(sleepEntries.count, 30))", "sleep days", .sky)
            Divider().frame(height: 30).background(Color.surfaceLine)
            coveragePill("cup.and.heat.waves.fill", "\(min(caffeineEntries.count, 60))", "caffeine logs", .amber)
            Divider().frame(height: 30).background(Color.surfaceLine)
            coveragePill("face.smiling", "\(min(moodEntries.count, 30))", "mood logs", .lilac)
        }
        .padding(.vertical, 12)
        .background(cardBackground)
    }

    private func coveragePill(_ icon: String, _ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 11)).foregroundStyle(color)
                Text(value).font(.system(size: 16, weight: .black, design: .rounded)).foregroundStyle(Color.ink0)
            }
            Text(label).font(.system(size: 9, design: .rounded)).foregroundStyle(Color.ink2)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FindingCard: View {
    let finding: CorrelationService.Finding
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(finding.color.opacity(0.12)).frame(width: 42, height: 42)
                    Image(systemName: finding.icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(finding.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(finding.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
                    Text(finding.body)
                        .font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink1).lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if finding.strength > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Signal strength")
                            .font(.system(size: 10, design: .rounded)).foregroundStyle(Color.ink2)
                        Spacer()
                        Text(finding.strength > 0.7 ? "Strong" : finding.strength > 0.4 ? "Moderate" : "Weak")
                            .font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(finding.color)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.05))
                            RoundedRectangle(cornerRadius: 3).fill(finding.color)
                                .frame(width: geo.size.width * finding.strength)
                        }
                    }.frame(height: 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18).fill(Color.surface1)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(finding.color.opacity(0.15), lineWidth: 1))
        )
    }
}

