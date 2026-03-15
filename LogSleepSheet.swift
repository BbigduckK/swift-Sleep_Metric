import SwiftUI
import SwiftData

struct LogSleepSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var bedtime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showConfirm = false
    @State private var saved = false

    // Track if user has touched each picker
    @State private var bedtimeTouched = false
    @State private var wakeTouched = false

    private var duration: Double {
        var diff = wakeTime.timeIntervalSince(bedtime) / 3600
        if diff <= 0 { diff += 24 }
        return min(max(diff, 0), 24)
    }

    private var durationColor: Color {
        duration >= 7 ? .mint : duration >= 5 ? .amber : .coral
    }

    private var durationLabel: String {
        switch duration {
        case 8...: return "Excellent — above optimal 🌟"
        case 7..<8: return "Good — within healthy range ✅"
        case 5..<7: return "Below optimal — debt forming ⚠️"
        default:   return "Very low — significant debt 🔴"
        }
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }

    // Validation — both pickers must be touched or duration must make sense
    private var isValid: Bool { duration > 0 && duration <= 16 }

    private var missingFields: [String] {
        var missing: [String] = []
        if !bedtimeTouched { missing.append("Bedtime") }
        if !wakeTouched    { missing.append("Wake time") }
        return missing
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Live Summary Card ──
                        VStack(spacing: 10) {
                            Text(String(format: "%.1f", duration))
                                .font(.system(size: 64, weight: .black, design: .rounded))
                                .foregroundStyle(durationColor)
                                .animation(.spring(response: 0.4), value: duration)
                            Text("hours of sleep")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(Color.ink2)

                            // Quality bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.06))
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(durationColor)
                                        .frame(width: geo.size.width * min(duration / 10, 1))
                                        .animation(.spring(response: 0.5), value: duration)
                                }
                            }
                            .frame(height: 6)
                            .padding(.horizontal, 24)

                            Text(durationLabel)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(durationColor.opacity(0.9))
                                .animation(.easeOut, value: duration)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal)
                        .background(cardBackground)
                        .padding(.horizontal)

                        // ── Time Selection Card ──
                        VStack(spacing: 0) {
                            // Bedtime row
                            VStack(spacing: 6) {
                                HStack {
                                    Image(systemName: "moon.fill")
                                        .foregroundStyle(Color.sky)
                                        .frame(width: 22)
                                    Text("BEDTIME")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .tracking(1.5)
                                        .foregroundStyle(Color.ink2)
                                    Spacer()
                                    DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        .onChange(of: bedtime) { _, _ in
                                            withAnimation { bedtimeTouched = true }
                                        }
                                }
                                .padding(.horizontal, 18)
                                .padding(.top, 16)

                                // Live display
                                if bedtimeTouched {
                                    HStack {
                                        Spacer()
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color.sky)
                                            Text("Set to \(timeFormatter.string(from: bedtime))")
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundStyle(Color.sky)
                                        }
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.bottom, 8)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }

                            Divider()
                                .background(Color.surfaceLine)
                                .padding(.horizontal, 18)

                            // Wake time row
                            VStack(spacing: 6) {
                                HStack {
                                    Image(systemName: "sun.horizon.fill")
                                        .foregroundStyle(Color.amber)
                                        .frame(width: 22)
                                    Text("WAKE TIME")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .tracking(1.5)
                                        .foregroundStyle(Color.ink2)
                                    Spacer()
                                    DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        .onChange(of: wakeTime) { _, _ in
                                            withAnimation { wakeTouched = true }
                                        }
                                }
                                .padding(.horizontal, 18)
                                .padding(.top, 16)

                                if wakeTouched {
                                    HStack {
                                        Spacer()
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color.amber)
                                            Text("Set to \(timeFormatter.string(from: wakeTime))")
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundStyle(Color.amber)
                                        }
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.bottom, 8)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(.bottom, 16)
                        }
                        .background(cardBackground)
                        .padding(.horizontal)

                        // ── Sleep Summary Preview ──
                        VStack(spacing: 10) {
                            summaryRow(
                                icon: "moon.fill", color: .sky,
                                label: "Bedtime",
                                value: timeFormatter.string(from: bedtime)
                            )
                            Divider().background(Color.surfaceLine)
                            summaryRow(
                                icon: "sun.horizon.fill", color: .amber,
                                label: "Wake time",
                                value: timeFormatter.string(from: wakeTime)
                            )
                            Divider().background(Color.surfaceLine)
                            summaryRow(
                                icon: "clock.fill", color: durationColor,
                                label: "Total sleep",
                                value: String(format: "%.1f hours", duration)
                            )

                            let debt = SleepAnalysisService.dailyDebt(for: duration)
                            if debt > 0 {
                                Divider().background(Color.surfaceLine)
                                summaryRow(
                                    icon: "exclamationmark.triangle.fill", color: .coral,
                                    label: "Sleep debt added",
                                    value: String(format: "+%.1f hours", debt)
                                )
                            }
                        }
                        .padding(16)
                        .background(cardBackground)
                        .padding(.horizontal)

                        // ── Validation Warning ──
                        if !missingFields.isEmpty {
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(Color.sky)
                                Text("Tip: Adjust the pickers above to match your actual times.")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(Color.ink1)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.sky.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.sky.opacity(0.2), lineWidth: 1))
                            )
                            .padding(.horizontal)
                        }

                        // ── Save Button ──
                        PrimaryButton(
                            label: saved ? "Saved!" : "Save Sleep",
                            icon: saved ? "checkmark" : "moon.fill",
                            color: .sky
                        ) {
                            showConfirm = true
                        }
                        .padding(.horizontal)
                        .disabled(saved || !isValid)
                    }
                    .padding(.bottom, 40)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.surface1, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.ink2)
                        .font(.system(size: 15, design: .rounded))
                }
            }
            // ── Confirm Dialog ──
            .confirmationDialog("Save this sleep entry?", isPresented: $showConfirm, titleVisibility: .visible) {
                Button("Save \(String(format: "%.1f", duration))h of sleep") { saveSleep() }
                Button("Edit", role: .cancel) {}
            } message: {
                Text("Bedtime \(timeFormatter.string(from: bedtime)) → Wake \(timeFormatter.string(from: wakeTime)) · \(String(format: "%.1f", duration)) hours")
            }
        }
        .modifier(SheetBackgroundModifier())
    }

    private func summaryRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Color.ink1)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.ink0)
        }
    }

    private func saveSleep() {
        let entry = SleepEntry(date: Date(), duration: duration, bedtime: bedtime, wakeTime: wakeTime)
        context.insert(entry)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
    }
}

