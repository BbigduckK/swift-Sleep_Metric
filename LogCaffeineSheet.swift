import SwiftUI
import SwiftData

private struct DrinkOption: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let mg: Double
}

private let drinkOptions: [DrinkOption] = [
    DrinkOption(name: "Espresso",     icon: "cup.and.saucer.fill",                   mg: 63),
    DrinkOption(name: "Drip Coffee",  icon: "mug.fill",                              mg: 95),
    DrinkOption(name: "Americano",    icon: "mug.fill",                              mg: 120),
    DrinkOption(name: "Latte",        icon: "cup.and.saucer.fill",                   mg: 75),
    DrinkOption(name: "Cold Brew",    icon: "takeoutbag.and.cup.and.straw.fill",     mg: 200),
    DrinkOption(name: "Energy Drink", icon: "bolt.fill",                             mg: 160),
    DrinkOption(name: "Green Tea",    icon: "leaf.fill",                             mg: 30),
    DrinkOption(name: "Black Tea",    icon: "cup.and.saucer.fill",                   mg: 50),
    DrinkOption(name: "Pre-Workout",  icon: "dumbbell.fill",                         mg: 250),
    DrinkOption(name: "Custom",       icon: "slider.horizontal.3",                   mg: 0),
]

struct LogCaffeineSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selected: DrinkOption? = nil
    @State private var customMg: Double = 100
    @State private var time = Date()
    @State private var timeTouched = false
    @State private var showConfirm = false
    @State private var saved = false

    private var mgToLog: Double {
        guard let s = selected else { return 0 }
        return s.name == "Custom" ? customMg : s.mg
    }

    private var isAfter2pm: Bool {
        Calendar.current.component(.hour, from: time) >= 14
    }

    private var isValid: Bool { selected != nil }

    private var missingFields: [String] {
        var m: [String] = []
        if selected == nil { m.append("drink type") }
        return m
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Live Summary Banner ──
                        if let s = selected {
                            VStack(spacing: 6) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.amber.opacity(0.14))
                                            .frame(width: 52, height: 52)
                                        Image(systemName: s.icon)
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundStyle(Color.amber)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(s.name)
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.ink0)
                                        Text("\(Int(mgToLog))mg caffeine · \(timeFormatter.string(from: time))")
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundStyle(Color.ink2)
                                    }
                                    Spacer()
                                    // Late caffeine badge
                                    if isAfter2pm {
                                        Image(systemName: "moon.zzz.fill")
                                            .foregroundStyle(Color.coral)
                                            .font(.system(size: 18))
                                    }
                                }
                                .padding(16)

                                if isAfter2pm {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(Color.coral)
                                            .font(.system(size: 12))
                                        Text("After 2 PM — may delay sleep onset by 1–2 hours")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(Color.coral.opacity(0.9))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.surface1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(isAfter2pm ? Color.coral.opacity(0.25) : Color.amber.opacity(0.25), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal)
                            .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity),
                                                    removal: .opacity))
                            .animation(.spring(response: 0.4), value: selected?.id)
                        } else {
                            // Empty state prompt
                            HStack(spacing: 10) {
                                Image(systemName: "hand.tap.fill")
                                    .foregroundStyle(Color.amber)
                                Text("Select a drink below to get started")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(Color.ink2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(cardBackground)
                            .padding(.horizontal)
                        }

                        // ── Drink Grid ──
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "SELECT DRINK")
                                .padding(.horizontal)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(drinkOptions) { drink in
                                    DrinkCard(drink: drink, isSelected: selected?.id == drink.id) {
                                        withAnimation(.spring(response: 0.3)) { selected = drink }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // ── Custom mg Slider ──
                        if selected?.name == "Custom" {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("Custom Amount")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundStyle(Color.ink2)
                                    Spacer()
                                    Text("\(Int(customMg)) mg")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.amber)
                                }
                                Slider(value: $customMg, in: 10...500, step: 5)
                                    .tint(.amber)
                                HStack {
                                    Text("10mg").font(.system(size: 10, design: .rounded)).foregroundStyle(Color.ink2)
                                    Spacer()
                                    Text("500mg").font(.system(size: 10, design: .rounded)).foregroundStyle(Color.ink2)
                                }
                            }
                            .padding(16)
                            .background(cardBackground)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }

                        // ── Time Picker ──
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(Color.amber)
                                Text("TIME")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .tracking(1.5)
                                    .foregroundStyle(Color.ink2)
                                Spacer()
                                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .onChange(of: time) { _, _ in
                                        withAnimation { timeTouched = true }
                                    }
                            }
                            .padding(16)

                            if timeTouched {
                                Divider().background(Color.surfaceLine)
                                HStack {
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.amber)
                                        Text("Time set to \(timeFormatter.string(from: time))")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(Color.amber)
                                    }
                                    .padding(12)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .background(cardBackground)
                        .padding(.horizontal)

                        // ── Validation Warning ──
                        if !missingFields.isEmpty {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(Color.amber)
                                Text("Please select a drink type to continue.")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(Color.ink1)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.amber.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.amber.opacity(0.2), lineWidth: 1))
                            )
                            .padding(.horizontal)
                        }

                        // ── Log Button ──
                        PrimaryButton(
                            label: saved ? "Logged!" : "Log Caffeine",
                            icon: saved ? "checkmark" : "plus",
                            color: isValid ? .amber : Color.white.opacity(0.15)
                        ) {
                            if isValid { showConfirm = true }
                        }
                        .padding(.horizontal)
                        .disabled(saved || !isValid)
                    }
                    .padding(.bottom, 40)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Log Caffeine")
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
            .confirmationDialog("Log this caffeine entry?", isPresented: $showConfirm, titleVisibility: .visible) {
                Button("Log \(selected?.name ?? "") — \(Int(mgToLog))mg at \(timeFormatter.string(from: time))") {
                    saveCaffeine()
                }
                if isAfter2pm {
                    Button("Log anyway (late caffeine warning)") { saveCaffeine() }
                }
                Button("Edit", role: .cancel) {}
            } message: {
                Text(isAfter2pm
                     ? "⚠️ This entry is after 2 PM and may affect your sleep quality tonight."
                     : "\(selected?.name ?? "") · \(Int(mgToLog))mg · \(timeFormatter.string(from: time))")
            }
        }
        .modifier(SheetBackgroundModifier())
    }

    private func saveCaffeine() {
        guard let s = selected else { return }
        let entry = CaffeineEntry(date: Date(), time: time, mg: mgToLog, drinkName: s.name)
        context.insert(entry)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
    }
}

private struct DrinkCard: View {
    let drink: DrinkOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: drink.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isSelected ? .black : Color.amber)
                Text(drink.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .black : Color.ink1)
                if drink.mg > 0 {
                    Text("\(Int(drink.mg))mg")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(isSelected ? Color.black.opacity(0.6) : Color.ink2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.amber : Color.surface1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.clear : Color.surfaceLine, lineWidth: 1)
                    )
            )
        }
    }
}

