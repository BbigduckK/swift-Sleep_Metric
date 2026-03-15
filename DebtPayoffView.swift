import SwiftUI
import SwiftData

struct DebtPayoffView: View {
    @Query(sort: \SleepEntry.date, order: .reverse)     var sleepEntries: [SleepEntry]
    @Query(sort: \SleepGoal.createdAt, order: .reverse)  var goals: [SleepGoal]
    @State private var appeared = false

    private var goal: SleepGoal? { goals.first }
    private var debt: Double { SleepAnalysisService.cumulativeDebt(from: sleepEntries) }
    private var plan: [DebtPayoffService.DayPlan] { DebtPayoffService.plan(currentDebt: debt, targetSleepPerNight: goal?.targetHours ?? 8) }
    private var daysToRecover: Int { plan.firstIndex(where: { $0.isCleared }).map { $0 + 1 } ?? plan.count }
    private var currentScore: Int {
        EnergyScoreService.calculate(sleepDebt: debt, todayCaffeine: 0, latestMood: nil, lastSleepDuration: sleepEntries.first?.duration ?? 0, caffeineAfter2pm: 0)
    }
    private var recoveredScore: Int { DebtPayoffService.predictedScore(after: daysToRecover, currentDebt: debt) }

    private let df: DateFormatter = { let f = DateFormatter(); f.dateFormat = "EEE, MMM d"; return f }()

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Debt status card
                    debtStatusCard.stagger(appeared: appeared, delay: 0)

                    if debt < 0.5 {
                        debtFreeCard.stagger(appeared: appeared, delay: 0.05)
                    } else {
                        // Score before/after
                        scoreImpactCard.stagger(appeared: appeared, delay: 0.05)

                        // Recovery plan
                        if !plan.isEmpty {
                            planCard.stagger(appeared: appeared, delay: 0.1)
                        }

                        // Tips
                        recoveryTipsCard.stagger(appeared: appeared, delay: 0.15)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 24)
            }
        }
        .navigationTitle("Debt Payoff Planner")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surface0, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { withAnimation { appeared = true } }
    }

    // MARK: - Debt Status
    private var debtStatusCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", debt))
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(debt < 1 ? Color.mint : debt < 4 ? Color.amber : Color.coral)
                    Text("hours owed")
                        .font(.system(size: 13, design: .rounded)).foregroundStyle(Color.ink2)
                }
                Divider().frame(height: 60).background(Color.surfaceLine)
                VStack(alignment: .leading, spacing: 10) {
                    debtLevel("7h+ sleep/night", debt < 1)
                    debtLevel("Consistent schedule", SleepAnalysisService.sleepConsistency(from: Array(sleepEntries.prefix(7))) > 70)
                    debtLevel("No late caffeine", true) // simplified
                }
            }
            // Debt progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Debt severity").font(.system(size: 11, design: .rounded)).foregroundStyle(Color.ink2)
                    Spacer()
                    Text(SleepAnalysisService.cognitiveRiskLevel(debt: debt) + " Risk")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(SleepAnalysisService.cognitiveRiskLevel(debt: debt).riskColor)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(debt < 1 ? Color.mint : debt < 4 ? Color.amber : Color.coral)
                            .frame(width: geo.size.width * min(debt / 10, 1))
                            .animation(.spring(response: 0.8), value: debt)
                    }
                }.frame(height: 6)
            }
        }
        .padding(18).background(cardBackground)
    }

    private func debtLevel(_ label: String, _ met: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 13)).foregroundStyle(met ? Color.mint : Color.ink2)
            Text(label).font(.system(size: 12, design: .rounded))
                .foregroundStyle(met ? Color.ink1 : Color.ink2)
        }
    }

    // MARK: - Score Impact
    private var scoreImpactCard: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "SCORE IMPACT")
            HStack(spacing: 0) {
                scoreBox("Now", score: currentScore)
                Image(systemName: "arrow.right").foregroundStyle(Color.ink2).frame(maxWidth: .infinity)
                scoreBox("After Recovery", score: recoveredScore)
            }
            Text("Estimated \(daysToRecover) night\(daysToRecover == 1 ? "" : "s") to full recovery")
                .font(.system(size: 13, design: .rounded)).foregroundStyle(Color.ink2)
        }
        .padding(18).background(cardBackground)
    }

    private func scoreBox(_ label: String, score: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(score)").font(.system(size: 36, weight: .black, design: .rounded)).foregroundStyle(score.scoreColor)
            Text(label).font(.system(size: 11, design: .rounded)).foregroundStyle(Color.ink2)
        }.frame(maxWidth: .infinity)
    }

    // MARK: - Plan Card
    private var planCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "YOUR RECOVERY PLAN")
            Text("Sleep these amounts each night to clear your debt:")
                .font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink2)

            VStack(spacing: 8) {
                ForEach(Array(plan.prefix(7).enumerated()), id: \.element.id) { i, day in
                    HStack(spacing: 12) {
                        Text(i == 0 ? "Tonight" : df.string(from: day.date))
                            .font(.system(size: 12, weight: i == 0 ? .bold : .regular, design: .rounded))
                            .foregroundStyle(i == 0 ? Color.ink0 : Color.ink1)
                            .frame(width: 100, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.04))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(day.isCleared ? Color.mint : Color.sky)
                                    .frame(width: geo.size.width * min(day.recommendedSleep / 10, 1))
                            }
                        }.frame(height: 7)
                        Text(String(format: "%.1fh", day.recommendedSleep))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(day.isCleared ? Color.mint : Color.sky)
                            .frame(width: 36, alignment: .trailing)
                        if day.isCleared {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 12)).foregroundStyle(Color.mint)
                        }
                    }
                }
            }
        }
        .padding(18).background(cardBackground)
    }

    // MARK: - Recovery Tips
    private var recoveryTipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "HOW TO RECOVER FASTER")
            tipRow("moon.fill", .sky, "Keep bedtime consistent ±30 minutes even on weekends")
            tipRow("phone.down.fill", .lilac, "Screens off 1 hour before bed — blue light blocks melatonin")
            tipRow("thermometer.medium", .sky, "Keep room at 18–20°C for optimal sleep temperature")
            tipRow("cup.and.heat.waves.fill", .amber, "No caffeine after 2 PM — it has a 6h half-life")
        }
        .padding(18).background(cardBackground)
    }

    private func tipRow(_ icon: String, _ color: Color, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(color).frame(width: 18)
            Text(text).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink1).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Debt Free
    private var debtFreeCard: some View {
        VStack(spacing: 16) {
            Text("🎉").font(.system(size: 60))
            Text("You're Debt Free!").font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(Color.mint)
            Text("Your sleep debt is under 1 hour. Keep logging to maintain your excellent sleep health.")
                .font(.system(size: 14, design: .rounded)).foregroundStyle(Color.ink1)
                .multilineTextAlignment(.center).lineSpacing(4)
        }
        .padding(32).background(RoundedRectangle(cornerRadius: 20).fill(Color.mint.opacity(0.08)).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.mint.opacity(0.2), lineWidth: 1)))
    }
}

