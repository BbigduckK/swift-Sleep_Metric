import SwiftUI
import SwiftData

// MARK: - Sleep Goal Setup View
struct SleepGoalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SleepGoal.createdAt, order: .reverse) var goals: [SleepGoal]

    @State private var targetHours: Double = 8.0
    @State private var bedtimeDate = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeDate    = Calendar.current.date(bySettingHour: 7,  minute: 0, second: 0, of: Date()) ?? Date()
    @State private var saved = false
    @State private var appeared = false

    private var calculatedHours: Double {
        var diff = wakeDate.timeIntervalSince(bedtimeDate) / 3600
        if diff <= 0 { diff += 24 }
        return min(max(diff, 0), 16)
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {

                        // Goal preview ring
                        ZStack {
                            Circle().stroke(Color.surfaceLine, lineWidth: 12).frame(width: 140, height: 140)
                            Circle()
                                .trim(from: 0, to: min(targetHours / 10, 1))
                                .stroke(AngularGradient(colors: [Color.amber.opacity(0.5), Color.amber],
                                    center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .frame(width: 140, height: 140).rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.6), value: targetHours)
                            VStack(spacing: 2) {
                                Text(String(format: "%.1f", targetHours))
                                    .font(.system(size: 32, weight: .black, design: .rounded)).foregroundStyle(Color.amber)
                                Text("HOURS").font(.system(size: 10, weight: .black, design: .rounded)).tracking(3).foregroundStyle(Color.ink2)
                            }
                        }
                        .padding(.top, 8)
                        .stagger(appeared: appeared, delay: 0)

                        // Recommended badge
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill").font(.system(size: 12)).foregroundStyle(Color.mint)
                            Text(targetHours >= 7 && targetHours <= 9 ? "Within NSF recommended range (7–9h)" : targetHours < 7 ? "Below recommended minimum (7h)" : "Above typical needs")
                                .font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink1)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Color.mint.opacity(0.08)).overlay(Capsule().stroke(Color.mint.opacity(0.2), lineWidth: 1)))
                        .stagger(appeared: appeared, delay: 0.05)

                        // Target hours slider
                        VStack(spacing: 12) {
                            SectionHeader(title: "SLEEP TARGET")
                            HStack {
                                Text("5h").font(.system(size: 11, design: .rounded)).foregroundStyle(Color.ink2)
                                Slider(value: $targetHours, in: 5...10, step: 0.5)
                                    .tint(.amber)
                                    .onChange(of: targetHours) { _, _ in syncTimesToHours() }
                                Text("10h").font(.system(size: 11, design: .rounded)).foregroundStyle(Color.ink2)
                            }
                        }
                        .padding(16).background(cardBackground)
                        .stagger(appeared: appeared, delay: 0.1)

                        // Bedtime + wake pickers
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "moon.fill").foregroundStyle(Color.sky).frame(width: 22)
                                Text("TARGET BEDTIME").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1.5).foregroundStyle(Color.ink2)
                                Spacer()
                                DatePicker("", selection: $bedtimeDate, displayedComponents: .hourAndMinute)
                                    .labelsHidden().colorScheme(.dark)
                                    .onChange(of: bedtimeDate) { _, _ in targetHours = calculatedHours }
                            }
                            .padding(16)
                            Divider().background(Color.surfaceLine)
                            HStack {
                                Image(systemName: "sun.horizon.fill").foregroundStyle(Color.amber).frame(width: 22)
                                Text("TARGET WAKE TIME").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1.5).foregroundStyle(Color.ink2)
                                Spacer()
                                DatePicker("", selection: $wakeDate, displayedComponents: .hourAndMinute)
                                    .labelsHidden().colorScheme(.dark)
                                    .onChange(of: wakeDate) { _, _ in targetHours = calculatedHours }
                            }
                            .padding(16)
                        }
                        .background(cardBackground)
                        .stagger(appeared: appeared, delay: 0.15)

                        // Summary
                        VStack(spacing: 8) {
                            summaryRow("moon.fill", .sky, "Bedtime", timeFormatter.string(from: bedtimeDate))
                            Divider().background(Color.surfaceLine)
                            summaryRow("sun.horizon.fill", .amber, "Wake time", timeFormatter.string(from: wakeDate))
                            Divider().background(Color.surfaceLine)
                            summaryRow("clock.fill", .mint, "Total sleep", String(format: "%.1f hours", targetHours))
                        }
                        .padding(16).background(cardBackground)
                        .stagger(appeared: appeared, delay: 0.2)

                        PrimaryButton(label: saved ? "Goal Saved!" : "Set Sleep Goal",
                            icon: saved ? "checkmark" : "target", color: .amber) { saveGoal() }
                        .disabled(saved)
                        .stagger(appeared: appeared, delay: 0.25)
                    }
                    .padding(.horizontal, 24).padding(.bottom, 40).padding(.top, 8)
                }
            }
            .navigationTitle("Sleep Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.surface1, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Color.amber)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
        .modifier(SheetBackgroundModifier())
        .onAppear {
            if let existing = goals.first {
                targetHours = existing.targetHours
                bedtimeDate = existing.targetBedtime
                wakeDate = existing.targetWakeTime
            }
            withAnimation { appeared = true }
        }
    }

    private func syncTimesToHours() {
        // When slider moves, shift wake time keeping bedtime fixed
        if let newWake = Calendar.current.date(byAdding: .second, value: Int(targetHours * 3600), to: bedtimeDate) {
            wakeDate = newWake
        }
    }

    private func summaryRow(_ icon: String, _ color: Color, _ label: String, _ value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).frame(width: 20)
            Text(label).font(.system(size: 13, design: .rounded)).foregroundStyle(Color.ink1)
            Spacer()
            Text(value).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(Color.ink0)
        }
    }

    private func saveGoal() {
        // Remove old goals
        goals.forEach { context.delete($0) }
        let cal = Calendar.current
        let goal = SleepGoal(
            targetHours: targetHours,
            targetBedtimeHour: cal.component(.hour, from: bedtimeDate),
            targetBedtimeMinute: cal.component(.minute, from: bedtimeDate),
            targetWakeHour: cal.component(.hour, from: wakeDate),
            targetWakeMinute: cal.component(.minute, from: wakeDate)
        )
        context.insert(goal)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss() }
    }
}

// MARK: - Nap Tracker View
struct NapTrackerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \NapEntry.date, order: .reverse) var naps: [NapEntry]
    @State private var showLogNap = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Science card
                    napScienceCard
                        .stagger(appeared: appeared, delay: 0)

                    // Log button
                    Button { showLogNap = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundStyle(Color.lilac)
                            Text("Log a Nap").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(Color.ink2)
                        }
                        .padding(16).background(cardBackground)
                    }
                    .buttonStyle(.plain)
                    .stagger(appeared: appeared, delay: 0.05)

                    if naps.isEmpty {
                        EmptyStateView(icon: "zzz", title: "No naps logged", message: "Log a nap to track how it affects your energy and nighttime sleep.")
                        .padding(.vertical, 40).stagger(appeared: appeared, delay: 0.1)
                    } else {
                        // Recent naps
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "RECENT NAPS")
                            ForEach(Array(naps.prefix(14).enumerated()), id: \.element.id) { i, nap in
                                NapCard(nap: nap)
                                    .stagger(appeared: appeared, delay: 0.1 + Double(i) * 0.05)
                            }
                        }
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 20)
            }
        }
        .navigationTitle("Nap Tracker")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.surface0, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showLogNap) { LogNapSheet() }
        .onAppear { withAnimation { appeared = true } }
    }

    private var napScienceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "NAP SCIENCE")
            HStack(spacing: 10) {
                napZone("10–20 min", "Power nap", "Boosts alertness, no sleep inertia", .mint, "bolt.fill")
                napZone("30 min", "Avoid", "Risk of sleep inertia on wake", .coral, "exclamationmark.triangle.fill")
                napZone("90 min", "Full cycle", "Memory boost, complete sleep cycle", .sky, "brain.head.profile")
            }
        }
        .padding(16).background(cardBackground)
    }

    private func napZone(_ time: String, _ label: String, _ desc: String, _ color: Color, _ icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(color)
            Text(time).font(.system(size: 12, weight: .black, design: .rounded)).foregroundStyle(Color.ink0)
            Text(label).font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(color)
            Text(desc).font(.system(size: 9, design: .rounded)).foregroundStyle(Color.ink2).multilineTextAlignment(.center).lineSpacing(2)
        }
        .frame(maxWidth: .infinity).padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.07)).overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.15), lineWidth: 1)))
    }
}

private struct NapCard: View {
    let nap: NapEntry
    private let tf: DateFormatter = { let f = DateFormatter(); f.dateFormat = "h:mm a"; return f }()
    private let df: DateFormatter = { let f = DateFormatter(); f.dateFormat = "EEE, MMM d"; return f }()

    private var durationLabel: String {
        let mins = Int(nap.duration * 60)
        if mins < 60 { return "\(mins) min" }
        return String(format: "%.1fh", nap.duration)
    }
    private var napColor: Color {
        let mins = Int(nap.duration * 60)
        if mins <= 20 { return .mint }
        if mins <= 40 { return .coral }
        return .sky
    }
    private var napAdvice: String {
        let mins = Int(nap.duration * 60)
        if mins <= 20 { return "Ideal power nap ✓" }
        if mins <= 40 { return "Watch for grogginess" }
        if mins >= 80 { return "Full sleep cycle" }
        return "Good length"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(napColor.opacity(0.1)).frame(width: 46, height: 46)
                Image(systemName: "zzz").font(.system(size: 18, weight: .semibold)).foregroundStyle(napColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(df.string(from: nap.date)).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
                    Spacer()
                    Text(durationLabel).font(.system(size: 15, weight: .black, design: .rounded)).foregroundStyle(napColor)
                }
                Text("\(tf.string(from: nap.startTime)) – \(tf.string(from: nap.endTime))")
                    .font(.system(size: 11, design: .rounded)).foregroundStyle(Color.ink2)
                Text(napAdvice).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(napColor.opacity(0.8))
            }
        }
        .padding(14).background(cardBackground)
    }
}

// MARK: - Log Nap Sheet
struct LogNapSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var startTime = Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime   = Calendar.current.date(bySettingHour: 13, minute: 20, second: 0, of: Date()) ?? Date()
    @State private var quality: Int = 3
    @State private var note = ""
    @State private var showConfirm = false
    @State private var saved = false

    private var duration: Double {
        var diff = endTime.timeIntervalSince(startTime) / 3600
        if diff <= 0 { diff += 24 }
        return min(max(diff, 0), 4)
    }
    private var durationMins: Int { Int(duration * 60) }
    private var napTip: String {
        if durationMins <= 20 { return "Perfect power nap zone 🟢" }
        if durationMins <= 30 { return "Watch for sleep inertia on waking ⚠️" }
        if durationMins >= 85 && durationMins <= 100 { return "Full 90-min sleep cycle 🔵" }
        return "Between power nap and full cycle — may cause grogginess"
    }
    private let tf: DateFormatter = { let f = DateFormatter(); f.dateFormat = "h:mm a"; return f }()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Duration display
                        VStack(spacing: 6) {
                            Text("\(durationMins)")
                                .font(.system(size: 64, weight: .black, design: .rounded))
                                .foregroundStyle(durationMins <= 20 ? Color.mint : durationMins <= 35 ? Color.coral : Color.sky)
                                .animation(.spring(response: 0.4), value: durationMins)
                            Text("minutes")
                                .font(.system(size: 15, design: .rounded)).foregroundStyle(Color.ink2)
                            Text(napTip).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink1)
                                .multilineTextAlignment(.center).padding(.horizontal, 20)
                                .animation(.easeOut, value: durationMins)
                        }
                        .padding(.vertical, 16)

                        // Time pickers
                        VStack(spacing: 0) {
                            pickerRow("Start Time", icon: "play.fill", color: .lilac, binding: $startTime)
                            Divider().background(Color.surfaceLine)
                            pickerRow("End Time", icon: "stop.fill", color: .lilac, binding: $endTime)
                        }
                        .background(cardBackground)

                        // Quality
                        VStack(spacing: 12) {
                            SectionHeader(title: "NAP QUALITY")
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { i in
                                    Button { withAnimation { quality = i } } label: {
                                        VStack(spacing: 4) {
                                            Text(["😴","😕","😐","🙂","😄"][i-1]).font(.system(size: 22))
                                            Text("\(i)").font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundStyle(quality >= i ? Color.lilac : Color.ink2)
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(RoundedRectangle(cornerRadius: 12)
                                            .fill(quality == i ? Color.lilac.opacity(0.15) : Color.surface2)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(quality == i ? Color.lilac.opacity(0.4) : Color.clear, lineWidth: 1.5)))
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16).background(cardBackground)

                        // Note
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "NOTE (OPTIONAL)")
                            TextField("How did you feel after?", text: $note, axis: .vertical)
                                .font(.system(size: 14, design: .rounded)).foregroundStyle(Color.ink0)
                                .lineLimit(2...4).padding(12).background(cardBackground)
                        }

                        PrimaryButton(label: saved ? "Saved!" : "Log Nap", icon: saved ? "checkmark" : "zzz", color: .lilac) {
                            showConfirm = true
                        }
                        .disabled(saved)
                    }
                    .padding(.horizontal, 24).padding(.bottom, 40).padding(.top, 8)
                }
            }
            .navigationTitle("Log Nap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.surface1, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.ink2).font(.system(size: 15, design: .rounded))
                }
            }
            .confirmationDialog("Save nap entry?", isPresented: $showConfirm, titleVisibility: .visible) {
                Button("Save \(durationMins)-min nap at \(tf.string(from: startTime))") { saveNap() }
                Button("Edit", role: .cancel) {}
            } message: { Text("\(tf.string(from: startTime)) – \(tf.string(from: endTime)) · \(durationMins) minutes") }
        }
        .modifier(SheetBackgroundModifier())
    }

    private func pickerRow(_ label: String, icon: String, color: Color, binding: Binding<Date>) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).frame(width: 22)
            Text(label).font(.system(size: 12, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(Color.ink2)
            Spacer()
            DatePicker("", selection: binding, displayedComponents: .hourAndMinute).labelsHidden().colorScheme(.dark)
        }.padding(16)
    }

    private func saveNap() {
        let entry = NapEntry(date: Date(), duration: duration, startTime: startTime, endTime: endTime, quality: quality, note: note)
        context.insert(entry)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
    }
}

