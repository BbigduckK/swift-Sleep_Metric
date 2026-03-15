import SwiftUI
import SwiftData

struct PersonalizationOnboardingView: View {
    @AppStorage("hasCompletedPersonalization") private var hasCompletedPersonalization = false
    @Environment(\.modelContext) private var context

    @State private var page = 0
    @State private var primaryGoal = ""
    @State private var sleepProblems: Set<String> = []
    @State private var wakePreference = ""
    @State private var caffeineHabit = ""
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()
            Circle().fill(pageAccent.opacity(0.06)).frame(width: 600).blur(radius: 120).offset(y: -250).allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.7), value: page)

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") { finishPersonalization() }
                        .font(.system(size: 14, design: .rounded)).foregroundStyle(Color.ink2)
                        .padding(.trailing, 24).padding(.top, 16)
                }

                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<4) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(i <= page ? pageAccent : Color.white.opacity(0.12))
                            .frame(width: i == page ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.4), value: page)
                    }
                }
                .padding(.top, 8)

                TabView(selection: $page) {
                    goalPage.tag(0)
                    problemsPage.tag(1)
                    wakePage.tag(2)
                    caffeinePage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: page)
            }
        }
        .onAppear { withAnimation { appeared = true } }
    }

    private var pageAccent: Color {
        switch page { case 0: return .amber; case 1: return .coral; case 2: return .sky; default: return .mint }
    }

    // MARK: - Page 1: Primary Goal
    private var goalPage: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("🎯").font(.system(size: 52))
                Text("What's your main goal?")
                    .font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(Color.ink0)
                    .multilineTextAlignment(.center)
                Text("We'll personalise your dashboard and tips around this.")
                    .font(.system(size: 14, design: .rounded)).foregroundStyle(Color.ink2).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .opacity(appeared ? 1 : 0).animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

            VStack(spacing: 10) {
                goalOption("fall_asleep",      "Fall asleep faster",       "zzz",                    .sky)
                goalOption("stay_asleep",      "Stop waking up at night",  "moon.fill",              .lilac)
                goalOption("afternoon_energy", "Fix afternoon energy dip", "bolt.fill",              .amber)
                goalOption("consistency",      "Build a consistent schedule", "clock.fill",          .mint)
                goalOption("reduce_debt",      "Clear my sleep debt",      "scalemass.fill",         .coral)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0).animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

            Spacer()
        }
        .padding(.top, 24)
    }

    private func goalOption(_ id: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        let isSelected = primaryGoal == id
        return Button {
            withAnimation(.spring(response: 0.3)) { primaryGoal = id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation { page = 1 }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(color.opacity(isSelected ? 0.2 : 0.08)).frame(width: 38, height: 38)
                    Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(color)
                }
                Text(label).font(.system(size: 15, design: .rounded)).foregroundStyle(isSelected ? Color.ink0 : Color.ink1)
                Spacer()
                if isSelected { Image(systemName: "checkmark.circle.fill").foregroundStyle(color).font(.system(size: 16)) }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(isSelected ? color.opacity(0.10) : Color.surface1).overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? color.opacity(0.4) : Color.surfaceLine, lineWidth: isSelected ? 1.5 : 1)))
        }
        .buttonStyle(.plain).animation(.spring(response: 0.3), value: isSelected)
    }

    // MARK: - Page 2: Sleep Problems
    private let problemOptions: [(String, String, String, Color)] = [
        ("Racing mind",        "brain.head.profile",          "racing_mind",    .lilac),
        ("Irregular schedule", "clock.badge.exclamationmark", "irregular",      .coral),
        ("Late caffeine",      "cup.and.heat.waves.fill",     "caffeine",       .amber),
        ("Phone/screen time",  "iphone",                      "screens",        .sky),
        ("Work stress",        "briefcase.fill",              "stress",         .coral),
        ("Early wake-ups",     "alarm.fill",                  "early_wake",     .amber),
        ("Just want insights", "chart.line.uptrend.xyaxis",   "insights_only",  .mint),
    ]

    private var problemsPage: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("🌙").font(.system(size: 52))
                Text("Any sleep challenges?")
                    .font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(Color.ink0).multilineTextAlignment(.center)
                Text("Pick all that apply — or none.")
                    .font(.system(size: 14, design: .rounded)).foregroundStyle(Color.ink2)
            }
            .padding(.horizontal, 20)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(problemOptions, id: \.2) { label, icon, id, color in
                    problemChip(label, icon: icon, id: id, color: color)
                }
            }
            .padding(.horizontal, 24)

            Button {
                withAnimation { page = 2 }
            } label: {
                Text(sleepProblems.isEmpty ? "None of these" : "Continue →")
                    .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Color.surface0)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.coral).clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 24)
    }

    private func problemChip(_ label: String, icon: String, id: String, color: Color) -> some View {
        let sel = sleepProblems.contains(id)
        return Button { withAnimation(.spring(response: 0.3)) { if sel { sleepProblems.remove(id) } else { sleepProblems.insert(id) } } } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 18, weight: sel ? .bold : .regular)).foregroundStyle(sel ? color : Color.ink2)
                Text(label).font(.system(size: 12, weight: sel ? .bold : .regular, design: .rounded)).foregroundStyle(sel ? Color.ink0 : Color.ink2).multilineTextAlignment(.center).lineLimit(2)
            }
            .frame(maxWidth: .infinity).padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(sel ? color.opacity(0.10) : Color.surface1).overlay(RoundedRectangle(cornerRadius: 14).stroke(sel ? color.opacity(0.4) : Color.surfaceLine, lineWidth: sel ? 1.5 : 1)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Page 3: Wake Preference
    private var wakePage: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("⏰").font(.system(size: 52))
                Text("When do you usually wake up?")
                    .font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(Color.ink0).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                wakeOption("early", "Before 7 AM", "🌅  Early bird", .amber)
                wakeOption("normal", "7–8:30 AM", "☀️  Normal schedule", .sky)
                wakeOption("late", "After 8:30 AM", "🌙  Night owl", .lilac)
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .padding(.top, 24)
    }

    private func wakeOption(_ id: String, _ time: String, _ label: String, _ color: Color) -> some View {
        let sel = wakePreference == id
        return Button {
            withAnimation { wakePreference = id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { withAnimation { page = 3 } }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(label).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(sel ? Color.ink0 : Color.ink1)
                    Text(time).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink2)
                }
                Spacer()
                if sel { Image(systemName: "checkmark.circle.fill").foregroundStyle(color).font(.system(size: 18)) }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(sel ? color.opacity(0.10) : Color.surface1).overlay(RoundedRectangle(cornerRadius: 14).stroke(sel ? color.opacity(0.4) : Color.surfaceLine, lineWidth: sel ? 1.5 : 1)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Page 4: Caffeine
    private var caffeinePage: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("☕️").font(.system(size: 52))
                Text("How's your caffeine habit?")
                    .font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(Color.ink0).multilineTextAlignment(.center)
                Text("We'll tune your caffeine reminders and tips.")
                    .font(.system(size: 14, design: .rounded)).foregroundStyle(Color.ink2).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                caffOption("none",     "No caffeine",               "I avoid it",              .mint)
                caffOption("light",    "1–2 drinks/day",            "Occasional coffee or tea", .sky)
                caffOption("moderate", "2–4 drinks/day",            "Regular coffee drinker",  .amber)
                caffOption("heavy",    "4+ drinks or after 3 PM",   "Heavy user",              .coral)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 24)
    }

    private func caffOption(_ id: String, _ label: String, _ sub: String, _ color: Color) -> some View {
        let sel = caffeineHabit == id
        return Button {
            withAnimation { caffeineHabit = id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { finishPersonalization() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(label).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(sel ? Color.ink0 : Color.ink1)
                    Text(sub).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink2)
                }
                Spacer()
                if sel { Image(systemName: "checkmark.circle.fill").foregroundStyle(color).font(.system(size: 18)) }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(sel ? color.opacity(0.10) : Color.surface1).overlay(RoundedRectangle(cornerRadius: 14).stroke(sel ? color.opacity(0.4) : Color.surfaceLine, lineWidth: sel ? 1.5 : 1)))
        }
        .buttonStyle(.plain)
    }

    private func finishPersonalization() {
        let profile = OnboardingProfile(
            primaryGoal: primaryGoal.isEmpty ? "consistency" : primaryGoal,
            sleepProblems: Array(sleepProblems),
            wakeTime: wakePreference.isEmpty ? "normal" : wakePreference,
            caffeineHabit: caffeineHabit.isEmpty ? "moderate" : caffeineHabit
        )
        context.insert(profile)
        withAnimation { hasCompletedPersonalization = true }
    }
}

