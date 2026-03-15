import Foundation
import HealthKit
import SwiftData

// MARK: - HealthKit Service
// NOTE: Requires HealthKit capability in Xcode project settings
// Add NSHealthShareUsageDescription to Info.plist or via Signing & Capabilities

@MainActor
class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    private let store = HKHealthStore()

    @Published var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published var isAuthorized = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date? = nil
    @Published var errorMessage: String? = nil

    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: [sleepType])
            isAuthorized = true
        } catch {
            errorMessage = "HealthKit access denied: \(error.localizedDescription)"
        }
    }

    /// Fetch sleep sessions from HealthKit for the last N days and insert into SwiftData
    func syncSleep(context: ModelContext, days: Int = 30) async {
        guard isAvailable, isAuthorized else { return }
        isSyncing = true
        defer { isSyncing = false }

        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date())
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(sampleType: sleepType, predicate: predicate,
                                          limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, results, error in
                    if let error { continuation.resume(throwing: error); return }
                    continuation.resume(returning: results ?? [])
                }
                store.execute(query)
            }

            // Fetch existing HK-sourced entries to avoid duplicates
            let descriptor = FetchDescriptor<SleepEntry>(
                predicate: #Predicate { $0.source == "healthkit" }
            )
            let existing = (try? context.fetch(descriptor)) ?? []
            let existingDates = Set(existing.map { calendar.startOfDay(for: $0.date) })

            for sample in samples {
                guard let categorySample = sample as? HKCategorySample,
                      categorySample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                      categorySample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                      categorySample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                      categorySample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                else { continue }

                let sleepDate = calendar.startOfDay(for: categorySample.endDate)
                guard !existingDates.contains(sleepDate) else { continue }

                let duration = categorySample.endDate.timeIntervalSince(categorySample.startDate) / 3600
                guard duration > 1.0 && duration < 16.0 else { continue }

                let entry = SleepEntry(
                    date: sleepDate,
                    duration: duration,
                    bedtime: categorySample.startDate,
                    wakeTime: categorySample.endDate,
                    source: "healthkit"
                )
                context.insert(entry)
            }

            try? context.save()
            lastSyncDate = Date()
        } catch {
            errorMessage = "Sync failed: \(error.localizedDescription)"
        }
    }

    func checkAuthorization() {
        guard isAvailable else { return }
        let status = store.authorizationStatus(for: sleepType)
        isAuthorized = status == .sharingAuthorized
    }
}

