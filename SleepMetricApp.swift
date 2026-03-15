import SwiftUI
import SwiftData

@main
struct SleepMetricApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedPersonalization") private var hasCompletedPersonalization = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    OnboardingView()
                } else if !hasCompletedPersonalization {
                    PersonalizationOnboardingView()
                } else {
                    ContentView()
                }
            }
        }
        .modelContainer(for: [
            SleepEntry.self, CaffeineEntry.self, MoodEntry.self,
            NapEntry.self, SleepGoal.self,
            ChallengeProgress.self, EarnedBadge.self, PersonalRecord.self,
            JournalEntry.self, ChronotypeResult.self, OnboardingProfile.self
        ])
    }
}

