import SwiftUI
import SwiftData

struct WhatIfSimulatorView: View {
    @Query(sort: \SleepEntry.date, order: .reverse)     var sleepEntries: [SleepEntry]
    @Query(sort: \SleepGoal.createdAt, order: .reverse)  var goals: [SleepGoal]
    @State private var appeared = false

    // Scenario inputs
    @State private var bedtime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var caffeineAfter2pm: Double = 0
    @State private var moodScore: Int = 6
    @State private var showResult = false

    private var debt: Double { SleepAnalysisService.cumulativeDebt(from: sleepEntries) }
    private var currentScore: Int {
        EnergyScoreService.calculate(sleepDebt: debt, todayCaffeine: 0, latestMood: sleepEntries.isEmpty ? nil : 6,
            lastSleepDuration: sleepEntries.first?.duration ?? 0, caffeineAfter2pm: 0)
    }

    private var scenario: WhatIfService.Scenario {
        let bedH = Double(Calendar.current.component(.hour, from: bedtime)) + Double(Calendar.current.component(.minute, from: bedtime)) / 60
        let wakeH = Double(Calendar.current.component(.hour, from: wakeTime)) + Double(Calendar.current.component(.minute, from: wakeTime)) / 60
        return WhatIfService.Scenario(bedtimeHour: bedH, wakeHour: wakeH, caffeineAfter2pm: caffeineAfter2pm, moodScore: moodScore)
    }
    private var result: WhatIfService.SimResult { WhatIfService.simulate(scenario: scenario, currentDebt: debt) }

    private let tf: DateFormatter = { let f = DateFormatter(); f.dateFormat = "h:mm a"; return f }()

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Header
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.lilac.opacity(0.1)).frame(width: 44, height: 44)
                            Image(systemName: "questionmark.circle.fill").font(.system(size: 20)).foregroundStyle(Color.lilac)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Adjust the scenario below and see your predicted Energy Score before committing to it tonight.")
                                .font(.system(size: 13, design: .rounded)).foregroundStyle(Color.ink1).lineSpacing(3)
                        }
                    }
                    .padding(16).background(cardBackground)
                    .stagger(appeared: appeared, delay: 0)

                    // Scenario inputs
                    scenarioInputs.stagger(appeared: appeared, delay: 0.05)

                    // Result card (live preview)
                    resultCard.stagger(appeared: appeared, delay: 0.1)

                    // Comparison
                    comparisonCard.stagger(appeared: appeared, delay: 0.15)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 24)
            }
        }
        .navigationTitle("\"What If\" Simulator")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surface0, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { withAnimation { appeared = true } }
    }

    // MARK: - Inputs
    private var scenarioInputs: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "TONIGHT'S SCENARIO").padding(.bottom, 12)

            VStack(spacing: 0) {
                // Bedtime
                HStack {
                    Image(systemName: "moon.fill").foregroundStyle(Color.sky).frame(width: 22)
                    Text("BED AT").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1.5).foregroundStyle(Color.ink2)
                    Spacer()
                    DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute).labelsHidden().colorScheme(.dark)
                }.padding(16)

                Divider().background(Color.surfaceLine)

                // Wake time
                HStack {
                    Image(systemName: "sun.horizon.fill").foregroundStyle(Color.amber).frame(width: 22)
                    Text("WAKE AT").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1.5).foregroundStyle(Color.ink2)
                    Spacer()
                    DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute).labelsHidden().colorScheme(.dark)
                }.padding(16)

                Divider().background(Color.surfaceLine)

                // Caffeine after 2pm
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "cup.and.heat.waves.fill").foregroundStyle(Color.amber).frame(width: 22)
                        Text("LATE CAFFEINE (after 2 PM)").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(Color.ink2)
                        Spacer()
                        Text(caffeineAfter2pm == 0 ? "None" : "\(Int(caffeineAfter2pm))mg")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(caffeineAfter2pm > 0 ? Color.amber : Color.ink2)
                    }
                    Slider(value: $caffeineAfter2pm, in: 0...400, step: 25).tint(.amber)
                    HStack {
                        Text("None").font(.system(size: 9, design: .rounded)).foregroundStyle(Color.ink2)
                        Spacer()
                        Text("400mg").font(.system(size: 9, design: .rounded)).foregroundStyle(Color.ink2)
                    }
                }.padding(16)

                Divider().background(Color.surfaceLine)

                // Mood
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "face.smiling").foregroundStyle(Color.lilac).frame(width: 22)
                        Text("EXPECTED MOOD").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(Color.ink2)
                        Spacer()
                        Text("\(moodScore.moodEmoji) \(moodScore)/10")
                            .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Color.lilac)
                    }
                    Slider(value: Binding(get: { Double(moodScore) }, set: { moodScore = Int($0.rounded()) }), in: 1...10, step: 1).tint(.lilac)
                }.padding(16)
            }
            .background(cardBackground)
        }
    }

    // MARK: - Result Card
    private var resultCard: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "PREDICTED OUTCOME")

            HStack(spacing: 20) {
                // Big score
                VStack(spacing: 4) {
                    ZStack {
                        Circle().stroke(Color.surfaceLine, lineWidth: 10).frame(width: 110, height: 110)
                        Circle()
                            .trim(from: 0, to: CGFloat(result.projectedScore) / 100)
                            .stroke(AngularGradient(colors: [result.projectedScore.scoreColor.opacity(0.5), result.projectedScore.scoreColor],
                                center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 110, height: 110).rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.7), value: result.projectedScore)
                        VStack(spacing: 0) {
                            Text("\(result.projectedScore)").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(result.projectedScore.scoreColor)
                            Text("SCORE").font(.system(size: 9, weight: .black, design: .rounded)).tracking(3).foregroundStyle(Color.ink2)
                        }
                    }
                    let delta = result.projectedScore - currentScore
                    if delta != 0 {
                        HStack(spacing: 4) {
                            Image(systemName: delta > 0 ? "arrow.up" : "arrow.down").font(.system(size: 10, weight: .bold))
                            Text("\(abs(delta)) vs today").font(.system(size: 11, design: .rounded))
                        }
                        .foregroundStyle(delta > 0 ? Color.mint : Color.coral)
                    }
                }

                // Details
                VStack(alignment: .leading, spacing: 10) {
                    resultRow("clock.fill", .sky, "Sleep", String(format: "%.1fh", result.projectedSleep))
                    if result.fallAsleepDelay > 0 {
                        resultRow("zzz", .amber, "Fall asleep delay", "+\(Int(result.fallAsleepDelay))min")
                    }
                    resultRow("moon.fill", .sky, "Effective sleep", String(format: "%.1fh", result.effectiveSleep))
                    resultRow("flame.fill", .coral, "New debt", String(format: "%.1fh", result.newDebt))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Warning
            if result.effectiveSleep < 6 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.coral)
                    Text("This scenario results in significant sleep debt accumulation.")
                        .font(.system(size: 12, design: .rounded)).foregroundStyle(Color.coral)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.coral.opacity(0.08)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.coral.opacity(0.2), lineWidth: 1)))
            } else if result.effectiveSleep >= 7.5 {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.mint)
                    Text("Great scenario! This will help reduce your sleep debt.")
                        .font(.system(size: 12, design: .rounded)).foregroundStyle(Color.mint)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.mint.opacity(0.08)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mint.opacity(0.2), lineWidth: 1)))
            }
        }
        .padding(18).background(cardBackground)
    }

    private func resultRow(_ icon: String, _ color: Color, _ label: String, _ value: String) -> some View {
        HStack {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundStyle(color).frame(width: 16)
            Text(label).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink2)
            Spacer()
            Text(value).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
        }
    }

    // MARK: - Comparison
    private var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "SCENARIO EXAMPLES")
            VStack(spacing: 10) {
                exampleScenario("Ideal night", bedH: 22.5, wakeH: 7, caff: 0, result: "Score +15–20")
                exampleScenario("Late night, no caffeine", bedH: 1, wakeH: 7, caff: 0, result: "Score –20–30")
                exampleScenario("Afternoon coffee, normal bed", bedH: 23, wakeH: 7, caff: 150, result: "Score –8–12")
                exampleScenario("Late night + coffee", bedH: 1, wakeH: 7, caff: 200, result: "Score –35–45")
            }
        }
        .padding(18).background(cardBackground)
    }

    private func exampleScenario(_ label: String, bedH: Double, wakeH: Double, caff: Double, result: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink1)
            Spacer()
            Text(result).font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(result.contains("+") ? Color.mint : Color.coral)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.surface2))
    }
}

