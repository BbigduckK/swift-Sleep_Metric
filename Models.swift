import Foundation
import SwiftData

@Model class SleepEntry {
    var date: Date; var duration: Double; var bedtime: Date; var wakeTime: Date; var source: String
    init(date: Date, duration: Double, bedtime: Date, wakeTime: Date, source: String = "manual") {
        self.date = date; self.duration = duration; self.bedtime = bedtime; self.wakeTime = wakeTime; self.source = source
    }
}

@Model class CaffeineEntry {
    var date: Date; var time: Date; var mg: Double; var drinkName: String
    init(date: Date, time: Date, mg: Double, drinkName: String = "Coffee") {
        self.date = date; self.time = time; self.mg = mg; self.drinkName = drinkName
    }
}

@Model class MoodEntry {
    var date: Date; var score: Int; var note: String
    init(date: Date, score: Int, note: String = "") { self.date = date; self.score = score; self.note = note }
}

@Model class NapEntry {
    var date: Date; var duration: Double; var startTime: Date; var endTime: Date; var quality: Int; var note: String
    init(date: Date, duration: Double, startTime: Date, endTime: Date, quality: Int = 3, note: String = "") {
        self.date = date; self.duration = duration; self.startTime = startTime; self.endTime = endTime; self.quality = quality; self.note = note
    }
}

@Model class SleepGoal {
    var targetHours: Double; var targetBedtimeHour: Int; var targetBedtimeMinute: Int
    var targetWakeHour: Int; var targetWakeMinute: Int; var createdAt: Date
    init(targetHours: Double = 8.0, targetBedtimeHour: Int = 23, targetBedtimeMinute: Int = 0, targetWakeHour: Int = 7, targetWakeMinute: Int = 0) {
        self.targetHours = targetHours; self.targetBedtimeHour = targetBedtimeHour
        self.targetBedtimeMinute = targetBedtimeMinute; self.targetWakeHour = targetWakeHour
        self.targetWakeMinute = targetWakeMinute; self.createdAt = Date()
    }
    var targetBedtime: Date { Calendar.current.date(bySettingHour: targetBedtimeHour, minute: targetBedtimeMinute, second: 0, of: Date()) ?? Date() }
    var targetWakeTime: Date { Calendar.current.date(bySettingHour: targetWakeHour, minute: targetWakeMinute, second: 0, of: Date()) ?? Date() }
}

@Model class ChallengeProgress {
    var challengeID: String; var startDate: Date; var completedDays: Int; var isCompleted: Bool; var completedAt: Date?
    init(challengeID: String, startDate: Date = Date()) {
        self.challengeID = challengeID; self.startDate = startDate; self.completedDays = 0; self.isCompleted = false
    }
}

@Model class EarnedBadge {
    var badgeID: String; var earnedAt: Date
    init(badgeID: String, earnedAt: Date = Date()) { self.badgeID = badgeID; self.earnedAt = earnedAt }
}

@Model class PersonalRecord {
    var recordType: String; var value: Double; var achievedAt: Date
    init(recordType: String, value: Double, achievedAt: Date = Date()) {
        self.recordType = recordType; self.value = value; self.achievedAt = achievedAt
    }
}

// MARK: - Journal Entry
@Model class JournalEntry {
    var date: Date
    var text: String           // user's free-text
    var energyScore: Int       // snapshot of score at time of writing
    var sleepHours: Double     // snapshot
    var moodScore: Int         // snapshot (0 = none)
    var aiInsight: String      // AI-generated pattern observation (optional, empty until generated)
    var tags: [String]         // auto-detected stress/recovery tags

    init(date: Date = Date(), text: String, energyScore: Int, sleepHours: Double, moodScore: Int) {
        self.date = date; self.text = text; self.energyScore = energyScore
        self.sleepHours = sleepHours; self.moodScore = moodScore
        self.aiInsight = ""; self.tags = []
    }
}

// MARK: - Chronotype Result (single persistent record)
@Model class ChronotypeResult {
    var chronotype: String      // "lion" | "bear" | "wolf" | "dolphin"
    var answers: [Int]          // raw quiz answers (10 values)
    var completedAt: Date

    init(chronotype: String, answers: [Int]) {
        self.chronotype = chronotype; self.answers = answers; self.completedAt = Date()
    }
}

// MARK: - Onboarding Profile (goals + sleep problems captured during personalised onboarding)
@Model class OnboardingProfile {
    var primaryGoal: String        // "fall_asleep", "stay_asleep", "afternoon_energy", "consistency", "reduce_debt"
    var sleepProblems: [String]    // multi-select
    var wakeTime: String           // "early" | "normal" | "late"
    var caffeineHabit: String      // "none" | "moderate" | "heavy"
    var completedAt: Date

    init(primaryGoal: String, sleepProblems: [String], wakeTime: String, caffeineHabit: String) {
        self.primaryGoal = primaryGoal; self.sleepProblems = sleepProblems
        self.wakeTime = wakeTime; self.caffeineHabit = caffeineHabit; self.completedAt = Date()
    }
}

