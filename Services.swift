import Foundation
import UserNotifications
import SwiftUI
import SwiftData

// MARK: - Sleep Analysis Service
struct SleepAnalysisService {
    static let optimalSleep: Double = 8.0
    static func dailyDebt(for sleep: Double) -> Double { max(0, optimalSleep - sleep) }
    static func cumulativeDebt(from sleeps: [SleepEntry]) -> Double {
        let recent = Array(sleeps.prefix(7))
        guard !recent.isEmpty else { return 0 }
        return recent.enumerated().reduce(0.0) { sum, item in
            sum + dailyDebt(for: item.element.duration) * max(1.0 - Double(item.offset) * 0.1, 0.4)
        }
    }
    static func cognitiveRiskLevel(debt: Double) -> String {
        switch debt { case 0..<1: return "Minimal"; case 1..<3: return "Mild"; case 3..<7: return "Moderate"; default: return "High" }
    }
    static func sleepConsistency(from sleeps: [SleepEntry]) -> Double {
        guard sleeps.count >= 2 else { return 100 }
        let times = sleeps.prefix(7).map { e -> Double in
            let c = Calendar.current.dateComponents([.hour, .minute], from: e.bedtime)
            return Double((c.hour ?? 0) * 60 + (c.minute ?? 0))
        }
        let mean = times.reduce(0, +) / Double(times.count)
        let stdDev = sqrt(times.map { pow($0 - mean, 2) }.reduce(0, +) / Double(times.count))
        return max(0, 100 - stdDev * 2)
    }
}

// MARK: - Energy Score Service
struct EnergyScoreService {
    static func calculate(sleepDebt: Double, todayCaffeine: Double, latestMood: Int?,
                          lastSleepDuration: Double, caffeineAfter2pm: Double) -> Int {
        var score = 100.0
        score -= min(sleepDebt * 6, 40)
        if lastSleepDuration >= 7.5 { score += 5 } else if lastSleepDuration < 5 { score -= 15 }
        if let mood = latestMood { score += (Double(mood) - 5.0) * 2.0 }
        score -= min(caffeineAfter2pm / 100 * 5, 15)
        return max(0, min(Int(score.rounded()), 100))
    }
}

// MARK: - Streak Service
struct StreakService {
    static func currentStreak(sleeps: [SleepEntry], caffeines: [CaffeineEntry], moods: [MoodEntry]) -> Int {
        let calendar = Calendar.current
        var allDates = Set<Date>()
        sleeps.forEach   { allDates.insert(calendar.startOfDay(for: $0.date)) }
        caffeines.forEach { allDates.insert(calendar.startOfDay(for: $0.date)) }
        moods.forEach    { allDates.insert(calendar.startOfDay(for: $0.date)) }
        guard !allDates.isEmpty else { return 0 }
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        if !allDates.contains(checkDate) { checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate }
        while allDates.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }
    static func longestStreak(sleeps: [SleepEntry], caffeines: [CaffeineEntry], moods: [MoodEntry]) -> Int {
        let calendar = Calendar.current
        var allDates = Set<Date>()
        sleeps.forEach   { allDates.insert(calendar.startOfDay(for: $0.date)) }
        caffeines.forEach { allDates.insert(calendar.startOfDay(for: $0.date)) }
        moods.forEach    { allDates.insert(calendar.startOfDay(for: $0.date)) }
        guard !allDates.isEmpty else { return 0 }
        let sorted = allDates.sorted()
        var longest = 1, current = 1
        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i-1], to: sorted[i]).day ?? 0
            if diff == 1 { current += 1; longest = max(longest, current) } else { current = 1 }
        }
        return longest
    }
    static func todayCompletion(sleeps: [SleepEntry], caffeines: [CaffeineEntry], moods: [MoodEntry]) -> (sleep: Bool, caffeine: Bool, mood: Bool) {
        let today = Calendar.current.startOfDay(for: Date())
        return (sleeps.contains { Calendar.current.startOfDay(for: $0.date) == today },
                caffeines.contains { Calendar.current.startOfDay(for: $0.date) == today },
                moods.contains { Calendar.current.startOfDay(for: $0.date) == today })
    }
}

// MARK: - Debt Payoff Service
struct DebtPayoffService {
    /// Returns a day-by-day plan to pay off sleep debt
    static func plan(currentDebt: Double, targetSleepPerNight: Double, goalDays: Int = 14) -> [DayPlan] {
        guard currentDebt > 0 else { return [] }
        var remainingDebt = currentDebt
        var plans: [DayPlan] = []
        let cal = Calendar.current
        for day in 0..<goalDays {
            guard remainingDebt > 0.1 else { break }
            // Recovery: sleep extra 1h above optimal until debt is cleared
            let base = SleepAnalysisService.optimalSleep
            let extra = min(remainingDebt, 1.5)          // max 1.5h bonus per night
            let recommended = min(base + extra, 9.5)
            let debtRepaid = max(0, recommended - base)
            remainingDebt = max(0, remainingDebt - debtRepaid)
            let date = cal.date(byAdding: .day, value: day, to: Date()) ?? Date()
            plans.append(DayPlan(date: date, recommendedSleep: recommended,
                                 debtAfter: remainingDebt, isCleared: remainingDebt < 0.1))
        }
        return plans
    }

    /// Predict score after following the plan for N days
    static func predictedScore(after days: Int, currentDebt: Double) -> Int {
        let plans = plan(currentDebt: currentDebt, targetSleepPerNight: SleepAnalysisService.optimalSleep)
        if plans.count > days { return EnergyScoreService.calculate(sleepDebt: plans[min(days, plans.count-1)].debtAfter, todayCaffeine: 0, latestMood: nil, lastSleepDuration: 8, caffeineAfter2pm: 0) }
        return EnergyScoreService.calculate(sleepDebt: 0, todayCaffeine: 0, latestMood: nil, lastSleepDuration: 8, caffeineAfter2pm: 0)
    }

    struct DayPlan: Identifiable {
        let id = UUID()
        let date: Date; let recommendedSleep: Double; let debtAfter: Double; let isCleared: Bool
    }
}

// MARK: - What If Simulator Service
struct WhatIfService {
    struct Scenario {
        var bedtimeHour: Double   // e.g. 23.0 = 11 PM
        var wakeHour: Double      // e.g. 7.0
        var caffeineAfter2pm: Double
        var moodScore: Int
    }

    static func simulate(scenario: Scenario, currentDebt: Double) -> SimResult {
        var sleep = scenario.wakeHour - scenario.bedtimeHour
        if sleep < 0 { sleep += 24 }
        sleep = min(max(sleep, 0), 12)

        let newDebt = max(0, currentDebt - max(0, sleep - SleepAnalysisService.optimalSleep) + SleepAnalysisService.dailyDebt(for: sleep))
        let score = EnergyScoreService.calculate(
            sleepDebt: newDebt, todayCaffeine: 0,
            latestMood: scenario.moodScore,
            lastSleepDuration: sleep,
            caffeineAfter2pm: scenario.caffeineAfter2pm
        )
        let fallAsleepDelay = scenario.caffeineAfter2pm > 100 ? 60.0 : scenario.caffeineAfter2pm > 0 ? 30.0 : 0.0
        let effectiveSleep = max(0, sleep - fallAsleepDelay / 60.0)

        return SimResult(projectedSleep: sleep, effectiveSleep: effectiveSleep,
                        projectedScore: score, newDebt: newDebt, fallAsleepDelay: fallAsleepDelay)
    }

    struct SimResult {
        let projectedSleep: Double; let effectiveSleep: Double
        let projectedScore: Int; let newDebt: Double; let fallAsleepDelay: Double
    }
}

// MARK: - Sleep Challenge Definitions
struct SleepChallenge: Identifiable {
    let id: String
    let icon: String; let title: String; let description: String
    let durationDays: Int; let color: Color
    let requirement: Requirement

    enum Requirement {
        case noCaffeineAfter2pm(days: Int)
        case bedtimeBefore(hour: Int, days: Int)
        case sleepAtLeast(hours: Double, days: Int)
        case noLateBedtime(midnightDays: Int)
        case logAllThree(days: Int)
        case moodAbove(score: Int, days: Int)
    }

    static let all: [SleepChallenge] = [
        SleepChallenge(id: "caffeine_curfew", icon: "cup.and.heat.waves.fill",
            title: "Caffeine Curfew", description: "No caffeine after 2 PM for 5 days straight",
            durationDays: 5, color: .amber,
            requirement: .noCaffeineAfter2pm(days: 5)),

        SleepChallenge(id: "early_bird", icon: "sun.horizon.fill",
            title: "Early Bird", description: "Bed before 11 PM every night for a week",
            durationDays: 7, color: .sky,
            requirement: .bedtimeBefore(hour: 23, days: 7)),

        SleepChallenge(id: "sleep_champion", icon: "moon.stars.fill",
            title: "Sleep Champion", description: "Sleep 7.5+ hours for 5 consecutive nights",
            durationDays: 5, color: .mint,
            requirement: .sleepAtLeast(hours: 7.5, days: 5)),

        SleepChallenge(id: "consistent_logger", icon: "checkmark.seal.fill",
            title: "Consistent Logger", description: "Log sleep, caffeine and mood every day for 7 days",
            durationDays: 7, color: .lilac,
            requirement: .logAllThree(days: 7)),

        SleepChallenge(id: "mood_booster", icon: "face.smiling.fill",
            title: "Mood Booster", description: "Log mood 7+ for 5 consecutive days",
            durationDays: 5, color: .mint,
            requirement: .moodAbove(score: 7, days: 5)),

        SleepChallenge(id: "night_owl_rehab", icon: "moon.zzz.fill",
            title: "Night Owl Rehab", description: "No sleeping past midnight for 10 days",
            durationDays: 10, color: .coral,
            requirement: .noLateBedtime(midnightDays: 10)),
    ]

    func evaluateProgress(sleeps: [SleepEntry], caffeines: [CaffeineEntry], moods: [MoodEntry], since startDate: Date) -> Int {
        let cal = Calendar.current
        let sinceDay = cal.startOfDay(for: startDate)
        switch requirement {
        case .noCaffeineAfter2pm(let days):
            var count = 0
            for d in 0..<days {
                let day = cal.date(byAdding: .day, value: d, to: sinceDay) ?? sinceDay
                let ds = cal.startOfDay(for: day)
                let hasLate = caffeines.contains {
                    cal.startOfDay(for: $0.date) == ds && cal.component(.hour, from: $0.time) >= 14
                }
                if !hasLate { count += 1 } else { break }
            }
            return count
        case .bedtimeBefore(let hour, let days):
            var count = 0
            for d in 0..<days {
                let day = cal.date(byAdding: .day, value: d, to: sinceDay) ?? sinceDay
                let ds = cal.startOfDay(for: day)
                if let s = sleeps.first(where: { cal.startOfDay(for: $0.date) == ds }) {
                    if cal.component(.hour, from: s.bedtime) < hour { count += 1 } else { break }
                } else { break }
            }
            return count
        case .sleepAtLeast(let hours, let days):
            var count = 0
            for d in 0..<days {
                let day = cal.date(byAdding: .day, value: d, to: sinceDay) ?? sinceDay
                let ds = cal.startOfDay(for: day)
                if let s = sleeps.first(where: { cal.startOfDay(for: $0.date) == ds }), s.duration >= hours { count += 1 } else { break }
            }
            return count
        case .logAllThree(let days):
            var count = 0
            for d in 0..<days {
                let day = cal.date(byAdding: .day, value: d, to: sinceDay) ?? sinceDay
                let ds = cal.startOfDay(for: day)
                let hasSleep = sleeps.contains { cal.startOfDay(for: $0.date) == ds }
                let hasCaff  = caffeines.contains { cal.startOfDay(for: $0.date) == ds }
                let hasMood  = moods.contains { cal.startOfDay(for: $0.date) == ds }
                if hasSleep && hasCaff && hasMood { count += 1 } else { break }
            }
            return count
        case .moodAbove(let score, let days):
            var count = 0
            for d in 0..<days {
                let day = cal.date(byAdding: .day, value: d, to: sinceDay) ?? sinceDay
                let ds = cal.startOfDay(for: day)
                if let m = moods.first(where: { cal.startOfDay(for: $0.date) == ds }), m.score >= score { count += 1 } else { break }
            }
            return count
        case .noLateBedtime(let days):
            var count = 0
            for d in 0..<days {
                let day = cal.date(byAdding: .day, value: d, to: sinceDay) ?? sinceDay
                let ds = cal.startOfDay(for: day)
                if let s = sleeps.first(where: { cal.startOfDay(for: $0.date) == ds }) {
                    let h = cal.component(.hour, from: s.bedtime)
                    if h < 24 && h >= 18 { count += 1 } else { break }
                } else { break }
            }
            return count
        }
    }
}

// MARK: - Badge Definitions
struct BadgeDefinition: Identifiable {
    let id: String; let icon: String; let title: String; let description: String; let color: Color

    static let all: [BadgeDefinition] = [
        BadgeDefinition(id: "first_log",    icon: "star.fill",          title: "First Step",       description: "Logged your first sleep entry",      color: .amber),
        BadgeDefinition(id: "streak_3",     icon: "flame.fill",         title: "On Fire",          description: "3-day logging streak",               color: .coral),
        BadgeDefinition(id: "streak_7",     icon: "flame.fill",         title: "Week Warrior",     description: "7-day logging streak",               color: .amber),
        BadgeDefinition(id: "streak_30",    icon: "flame.fill",         title: "Unstoppable",      description: "30-day logging streak",              color: .mint),
        BadgeDefinition(id: "early_bird",   icon: "sun.horizon.fill",   title: "Early Bird",       description: "Completed Early Bird challenge",      color: .sky),
        BadgeDefinition(id: "caffeine_curfew", icon: "cup.and.heat.waves.fill", title: "Caffeine Clean", description: "Completed Caffeine Curfew",   color: .amber),
        BadgeDefinition(id: "sleep_champ",  icon: "moon.stars.fill",    title: "Sleep Champion",   description: "Completed Sleep Champion challenge", color: .mint),
        BadgeDefinition(id: "logger",       icon: "checkmark.seal.fill",title: "Dedicated Logger", description: "Completed Consistent Logger",        color: .lilac),
        BadgeDefinition(id: "perfect_week", icon: "trophy.fill",        title: "Perfect Week",     description: "Hit sleep goal every day for a week",color: .amber),
        BadgeDefinition(id: "score_90",     icon: "bolt.fill",          title: "Energy Master",    description: "Achieved an Energy Score of 90+",    color: .mint),
        BadgeDefinition(id: "debt_free",    icon: "checkmark.circle.fill", title: "Debt Free",     description: "Reduced sleep debt to under 1h",     color: .mint),
        BadgeDefinition(id: "night_rehab",  icon: "moon.zzz.fill",      title: "Night Owl Rehab",  description: "Completed Night Owl Rehab",          color: .lilac),
    ]
    static func find(_ id: String) -> BadgeDefinition? { all.first { $0.id == id } }
}

// MARK: - Personal Records Service
struct PersonalRecordsService {
    struct RecordResult {
        let type: String; let oldValue: Double; let newValue: Double; let isNew: Bool
    }
    static func check(
        sleeps: [SleepEntry], caffeines: [CaffeineEntry], moods: [MoodEntry],
        currentScore: Int, currentStreak: Int, existing: [PersonalRecord]
    ) -> [RecordResult] {
        var results: [RecordResult] = []
        func check(_ type: String, _ newVal: Double) {
            let old = existing.first { $0.recordType == type }?.value ?? 0
            if newVal > old { results.append(RecordResult(type: type, oldValue: old, newValue: newVal, isNew: old == 0)) }
        }
        check("bestScore", Double(currentScore))
        check("longestStreak", Double(currentStreak))
        if let best = sleeps.max(by: { $0.duration < $1.duration }) { check("mostSleep", best.duration) }
        let consistency = SleepAnalysisService.sleepConsistency(from: Array(sleeps.prefix(7)))
        check("bestConsistency", consistency)
        if let bestMood = moods.max(by: { $0.score < $1.score }) { check("bestMood", Double(bestMood.score)) }
        return results
    }
    static let recordMeta: [String: (icon: String, label: String, color: Color, format: (Double) -> String)] = [
        "bestScore":       ("bolt.fill",                  "Best Energy Score",   .amber, { "\(Int($0))" }),
        "longestStreak":   ("flame.fill",                 "Longest Streak",      .coral, { "\(Int($0)) days" }),
        "mostSleep":       ("moon.stars.fill",            "Best Night's Sleep",  .sky,   { String(format: "%.1fh", $0) }),
        "bestConsistency": ("arrow.triangle.2.circlepath","Best Consistency",    .mint,  { "\(Int($0))%" }),
        "bestMood":        ("face.smiling.fill",          "Best Mood Score",     .lilac, { "\(Int($0))/10" }),
    ]
}

// MARK: - Smart Bedtime Reminder Service
struct SmartBedtimeService {
    /// Returns recommended bedtime tonight based on debt and goal
    static func recommendedBedtime(debt: Double, goal: SleepGoal?) -> Date {
        let targetHours = goal?.targetHours ?? SleepAnalysisService.optimalSleep
        let bonus = min(debt * 0.25, 1.0) // sleep up to 1h extra if in debt
        let totalSleep = targetHours + bonus
        let wakeHour = Double(goal?.targetWakeHour ?? 7) + Double(goal?.targetWakeMinute ?? 0) / 60
        var bedHour = wakeHour - totalSleep
        if bedHour < 0 { bedHour += 24 }
        let h = Int(bedHour); let m = Int((bedHour - Double(h)) * 60)
        return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
    }

    /// Schedules a smart bedtime reminder for tonight
    static func scheduleSmartReminder(debt: Double, goal: SleepGoal?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["smart_bedtime"])
        let bed = recommendedBedtime(debt: debt, goal: goal)
        // Remind 30 minutes before
        guard let reminderTime = Calendar.current.date(byAdding: .minute, value: -30, to: bed) else { return }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let content = UNMutableNotificationContent()
        content.title = "Bedtime in 30 minutes 🌙"
        content.body = debt > 2
            ? "You have \(String(format: "%.1f", debt))h of sleep debt. Aim for bed by \(formatTime(bed)) tonight."
            : "Based on your goal, aim for bed by \(formatTime(bed)) for a great tomorrow."
        content.sound = .default
        center.add(UNNotificationRequest(identifier: "smart_bedtime", content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)))
    }

    private static func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: date)
    }
}

// MARK: - Mood-Aware Notification Service
struct MoodAwareNotificationService {
    static func scheduleEveningNotification(recentMoods: [MoodEntry], streak: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["mood_aware_evening"])
        let content = UNMutableNotificationContent()
        content.sound = .default
        // Calculate avg mood of last 3 days
        let recent3 = Array(recentMoods.prefix(3))
        let avgMood = recent3.isEmpty ? 5.0 : Double(recent3.map(\.score).reduce(0, +)) / Double(recent3.count)
        if avgMood <= 3 {
            content.title = "Hey, take it easy 💙"
            content.body = "You've had a rough few days. Even logging tonight counts as a win. One step at a time."
        } else if avgMood <= 5 {
            content.title = "Check in with yourself 🌙"
            content.body = "How are you feeling tonight? Log your mood — patterns help you understand what affects your energy."
        } else if streak >= 7 {
            content.title = "You're on a roll 🔥"
            content.body = "\(streak)-day streak! Log tonight to keep the momentum going."
        } else {
            content.title = "End of day check-in 🌙"
            content.body = "Log your caffeine and mood to complete today's entry."
        }
        var comps = DateComponents(); comps.hour = 21; comps.minute = 0
        center.add(UNNotificationRequest(identifier: "mood_aware_evening", content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)))
    }
}

// MARK: - Score History Service
struct ScoreHistoryService {
    struct DayScore: Identifiable {
        let id = UUID(); let date: Date; let score: Int; let debt: Double
    }
    static func build(sleeps: [SleepEntry], caffeines: [CaffeineEntry], moods: [MoodEntry], days: Int = 30) -> [DayScore] {
        let cal = Calendar.current
        return (0..<days).compactMap { offset -> DayScore? in
            guard let day = cal.date(byAdding: .day, value: -(days - 1 - offset), to: cal.startOfDay(for: Date())) else { return nil }
            let ds = cal.startOfDay(for: day)
            let daySleeps = sleeps.filter { cal.startOfDay(for: $0.date) <= ds }
            guard !daySleeps.isEmpty else { return nil }
            let debt = SleepAnalysisService.cumulativeDebt(from: daySleeps)
            let todayCaff = caffeines.filter { cal.startOfDay(for: $0.date) == ds }.reduce(0) { $0 + $1.mg }
            let lateCaff = caffeines.filter { cal.startOfDay(for: $0.date) == ds && cal.component(.hour, from: $0.time) >= 14 }.reduce(0) { $0 + $1.mg }
            let mood = moods.first { cal.startOfDay(for: $0.date) == ds }?.score
            let lastSleep = daySleeps.first(where: { cal.startOfDay(for: $0.date) == ds })?.duration ?? daySleeps.first?.duration ?? 0
            let score = EnergyScoreService.calculate(sleepDebt: debt, todayCaffeine: todayCaff, latestMood: mood, lastSleepDuration: lastSleep, caffeineAfter2pm: lateCaff)
            return DayScore(date: day, score: score, debt: debt)
        }
    }
}

// MARK: - Sleep Tip Model
struct SleepTip: Identifiable {
    let id = UUID(); let icon: String; let title: String; let body: String
    let category: String; let color: Color; let triggerContext: TipContext
    enum TipContext { case always, afterLateCaffeine, highDebt, lowMood, goodSleep, bedtimeApproaching, morningAfterBadSleep }
}

// MARK: - Tips Library
struct TipsService {
    static let allTips: [SleepTip] = [
        SleepTip(icon: "clock.badge.xmark", title: "The 2 PM Caffeine Cutoff",
            body: "Caffeine has a 5–7 hour half-life. A 3 PM coffee means 50mg is still active at 9 PM, suppressing melatonin and delaying sleep onset by up to 90 minutes.",
            category: "Caffeine", color: .amber, triggerContext: .afterLateCaffeine),
        SleepTip(icon: "cup.and.heat.waves.fill", title: "First Coffee: Wait 90 Minutes",
            body: "Cortisol peaks 30–60 minutes after waking. Drinking coffee during this window reduces its effectiveness. Wait 90 minutes for maximum alertness boost.",
            category: "Caffeine", color: .amber, triggerContext: .always),
        SleepTip(icon: "drop.fill", title: "Caffeine Dehydrates You",
            body: "Caffeine is a mild diuretic. For every 100mg, drink an extra glass of water. Dehydration alone can reduce cognitive performance by 10–15%.",
            category: "Caffeine", color: .sky, triggerContext: .always),
        SleepTip(icon: "bed.double.fill", title: "You Can't Fully Repay Sleep Debt Overnight",
            body: "Research from U Penn shows that 10+ hours of sleep debt requires multiple recovery nights — not one long sleep. Consistency beats catch-up.",
            category: "Sleep Debt", color: .coral, triggerContext: .highDebt),
        SleepTip(icon: "moon.stars.fill", title: "The Power of Consistent Bedtime",
            body: "Keeping the same bedtime ±30 minutes daily can improve sleep quality by up to 40% without changing total sleep duration.",
            category: "Sleep", color: .sky, triggerContext: .always),
        SleepTip(icon: "thermometer.medium", title: "Temperature Drops = Better Sleep",
            body: "Your core body temperature needs to drop 1–3°F to initiate sleep. Keeping your room at 65–68°F (18–20°C) can reduce time to fall asleep by 30%.",
            category: "Environment", color: .sky, triggerContext: .bedtimeApproaching),
        SleepTip(icon: "sun.max.fill", title: "Morning Light Resets Your Clock",
            body: "10 minutes of bright outdoor light within 30 minutes of waking sets your circadian clock and improves alertness for the next 16 hours.",
            category: "Circadian", color: .amber, triggerContext: .morningAfterBadSleep),
        SleepTip(icon: "brain.head.profile", title: "Sleep Loss Amplifies Negative Emotions",
            body: "A UC Berkeley study found the amygdala is 60% more reactive after sleep deprivation. One extra hour of sleep can measurably improve emotional regulation.",
            category: "Mood", color: .lilac, triggerContext: .lowMood),
        SleepTip(icon: "figure.walk", title: "20 Minutes of Walking = Better Sleep",
            body: "Regular aerobic exercise improves sleep quality by 65% and reduces time to fall asleep by 55%. Evening walks are especially effective.",
            category: "Lifestyle", color: .mint, triggerContext: .always),
        SleepTip(icon: "moon.zzz.fill", title: "REM Sleep Processes Emotions",
            body: "The last 2 hours of sleep are mostly REM. Cutting sleep to 6h removes 50% of your REM — the stage for emotional processing and creativity.",
            category: "Sleep Science", color: .lilac, triggerContext: .highDebt),
        SleepTip(icon: "phone.down.fill", title: "Blue Light Delays Melatonin",
            body: "Screens delay melatonin production by 1.5–3 hours. Enable Night Mode after sunset, or use blue-light glasses 2 hours before bed.",
            category: "Environment", color: .sky, triggerContext: .bedtimeApproaching),
        SleepTip(icon: "checkmark.seal.fill", title: "Great Sleep Last Night?",
            body: "A full 7–9h sleep increases reaction time, working memory, and decision-making. Your brain literally flushed toxins via the glymphatic system while you slept.",
            category: "Recovery", color: .mint, triggerContext: .goodSleep),
        SleepTip(icon: "wind", title: "The 4-7-8 Breathing Trick",
            body: "Inhale 4 counts, hold 7, exhale 8. This activates the parasympathetic nervous system, lowering heart rate and helping you fall asleep 20% faster.",
            category: "Technique", color: .mint, triggerContext: .bedtimeApproaching),
    ]
    static func contextualTips(sleepDebt: Double, lastSleep: Double, latestMood: Int?, caffeineAfter2pm: Double, hour: Int) -> [SleepTip] {
        var tips: [SleepTip] = []
        if caffeineAfter2pm > 0  { tips += allTips.filter { $0.triggerContext == .afterLateCaffeine } }
        if sleepDebt >= 3        { tips += allTips.filter { $0.triggerContext == .highDebt } }
        if let m = latestMood, m <= 4 { tips += allTips.filter { $0.triggerContext == .lowMood } }
        if lastSleep >= 7.5      { tips += allTips.filter { $0.triggerContext == .goodSleep } }
        if hour >= 20            { tips += allTips.filter { $0.triggerContext == .bedtimeApproaching } }
        if hour >= 6 && hour <= 9 && lastSleep < 6 { tips += allTips.filter { $0.triggerContext == .morningAfterBadSleep } }
        tips += allTips.filter { $0.triggerContext == .always }
        var seen = Set<String>()
        return Array(tips.filter { seen.insert($0.title).inserted }.prefix(3))
    }
}

// MARK: - Insights Service
struct Insight: Identifiable { let id = UUID(); let icon: String; let title: String; let body: String; let category: InsightCategory }
enum InsightCategory { case sleep, caffeine, mood, trend }
struct InsightsService {
    static func generate(sleepEntries: [SleepEntry], caffeineEntries: [CaffeineEntry], moodEntries: [MoodEntry]) -> [Insight] {
        var insights: [Insight] = []
        let recentSleeps = Array(sleepEntries.prefix(7))
        let goodStreak = recentSleeps.prefix(while: { $0.duration >= 7 }).count
        if goodStreak >= 3 { insights.append(Insight(icon: "moon.stars.fill", title: "Great Sleep Streak", body: "You've slept 7+ hours for \(goodStreak) days in a row.", category: .sleep)) }
        let today = Calendar.current.startOfDay(for: Date())
        let lateCaff = caffeineEntries.filter { Calendar.current.startOfDay(for: $0.date) == today && Calendar.current.component(.hour, from: $0.time) >= 14 }
        if !lateCaff.isEmpty { insights.append(Insight(icon: "cup.and.heat.waves.fill", title: "Late Caffeine Today", body: "You had \(Int(lateCaff.reduce(0) { $0 + $1.mg }))mg after 2 PM. May delay sleep by 1–2 hours.", category: .caffeine)) }
        let recentMoods = Array(moodEntries.prefix(5))
        if recentMoods.count >= 3 {
            let avg = Double(recentMoods.map(\.score).reduce(0, +)) / Double(recentMoods.count)
            if avg < 4 { insights.append(Insight(icon: "heart.slash.fill", title: "Low Mood This Week", body: "Your mood averaged \(String(format: "%.1f", avg))/10. Sleep debt directly impacts emotional regulation.", category: .mood)) }
        }
        let consistency = SleepAnalysisService.sleepConsistency(from: recentSleeps)
        if consistency < 60 { insights.append(Insight(icon: "waveform.path.ecg", title: "Irregular Sleep Schedule", body: "Your bedtime varies significantly. Consistency improves quality independent of total hours.", category: .trend)) }
        if insights.isEmpty { insights.append(Insight(icon: "checkmark.seal.fill", title: "Looking Good", body: "Your energy metrics are on track.", category: .trend)) }
        return insights
    }
}

// MARK: - Notification Service
struct NotificationService {
    static func requestPermission() { UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in } }
    static func scheduleDailyReminders(morningHour: Int = 8, eveningHour: Int = 22) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["morning", "evening"])
        func add(_ id: String, _ title: String, _ body: String, _ hour: Int) {
            let content = UNMutableNotificationContent(); content.title = title; content.body = body; content.sound = .default
            var comps = DateComponents(); comps.hour = hour; comps.minute = 0
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)))
        }
        add("morning", "Good Morning ☀️", "Log last night's sleep to update your Energy Score.", morningHour)
        add("evening", "End of Day 🌙", "Log your caffeine and mood to keep your streak alive 🔥", eveningHour)
    }
}

// MARK: - Calendar helper
extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: comps) ?? date
    }
}

