import SwiftUI

// MARK: - Onboarding Page Model
private struct OnboardingPage: Identifiable {
    let id: Int
    let type: PageType

    enum PageType {
        case splash
        case sleepDebt
        case cognitiveImpact
        case caffeine
        case whyApp
        case howItWorks
        case ready
    }
}

private let allPages: [OnboardingPage] = [
    OnboardingPage(id: 0, type: .splash),
    OnboardingPage(id: 1, type: .sleepDebt),
    OnboardingPage(id: 2, type: .cognitiveImpact),
    OnboardingPage(id: 3, type: .caffeine),
    OnboardingPage(id: 4, type: .whyApp),
    OnboardingPage(id: 5, type: .howItWorks),
    OnboardingPage(id: 6, type: .ready),
]

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var page = 0

    private var accentForPage: Color {
        switch page {
        case 0: return .amber
        case 1: return .coral
        case 2: return .coral
        case 3: return .amber
        case 4: return .sky
        case 5: return .mint
        default: return .amber
        }
    }

    var body: some View {
        ZStack {
            Color.surface0.ignoresSafeArea()

            Circle()
                .fill(accentForPage.opacity(0.07))
                .frame(width: 600, height: 600)
                .blur(radius: 120)
                .offset(x: 80, y: -180)
                .animation(.easeInOut(duration: 0.9), value: page)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar
                TabView(selection: $page) {
                    ForEach(allPages) { p in
                        pageContent(p).tag(p.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: page)
                bottomBar
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(allPages) { p in
                    Capsule()
                        .fill(p.id <= page ? accentForPage : Color.white.opacity(0.12))
                        .frame(width: p.id == page ? 18 : 5, height: 5)
                        .animation(.spring(response: 0.35), value: page)
                }
            }
            Spacer()
            if page < allPages.count - 1 {
                Button("Skip") {
                    withAnimation { page = allPages.count - 1 }
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.ink2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.45)) {
                    if page < allPages.count - 1 {
                        page += 1
                    } else {
                        NotificationService.requestPermission()
                        NotificationService.scheduleDailyReminders()
                        hasCompletedOnboarding = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(page < allPages.count - 1 ? "Continue" : "Start Tracking")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Image(systemName: page < allPages.count - 1 ? "arrow.right" : "bolt.fill")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(Color.surface0)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(accentForPage)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .animation(.easeInOut(duration: 0.3), value: accentForPage)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .padding(.top, 16)
        }
        .background(
            LinearGradient(
                colors: [Color.surface0.opacity(0), Color.surface0],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Page Router
    @ViewBuilder
    private func pageContent(_ p: OnboardingPage) -> some View {
        switch p.type {
        case .splash:          SplashPage()
        case .sleepDebt:       SleepDebtPage()
        case .cognitiveImpact: CognitiveImpactPage()
        case .caffeine:        CaffeinePage()
        case .whyApp:          WhyAppPage()
        case .howItWorks:      HowItWorksPage()
        case .ready:           ReadyPage()
        }
    }
}

// MARK: - Page 0: Splash
private struct SplashPage: View {
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.amber.opacity(0.06 + Double(i) * 0.04), lineWidth: 1)
                            .frame(width: CGFloat(140 + i * 44), height: CGFloat(140 + i * 44))
                            .scaleEffect(appeared ? 1 : 0.6)
                            .animation(.spring(response: 0.8).delay(Double(i) * 0.1), value: appeared)
                    }
                    ZStack {
                        Circle()
                            .fill(Color.amber.opacity(0.12))
                            .frame(width: 100, height: 100)
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(Color.amber)
                    }
                    .scaleEffect(appeared ? 1 : 0.5)
                    .animation(.spring(response: 0.7).delay(0.1), value: appeared)
                }
                .padding(.bottom, 44)

                VStack(spacing: 14) {
                    Text("Sleep Metric")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(Color.ink0)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                    Text("Most people are running on a\nsleep deficit they can't see.")
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(Color.ink1)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)

                    Text("This app changes that.")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.amber)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)
                }
                .padding(.horizontal, 32)
                Spacer(minLength: 120)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Page 1: What is Sleep Debt
private struct SleepDebtPage: View {
    @State private var appeared = false
    @State private var barAnimate = false

    private let bars: [(label: String, hours: Double, deficit: Double)] = [
        ("MON", 7.5, 0.5), ("TUE", 6.0, 2.0), ("WED", 5.5, 2.5),
        ("THU", 7.0, 1.0), ("FRI", 4.5, 3.5), ("SAT", 8.5, 0.0), ("SUN", 6.5, 1.5),
    ]
    private var totalDebt: Double { bars.reduce(0) { $0 + $1.deficit } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    onboardTagLabel("THE PROBLEM", color: .coral)
                    Text("What is\nSleep Debt?")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Color.ink0)
                        .lineSpacing(2)
                }
                .padding(.top, 16)
                .staggerIn(appeared, delay: 0)

                Text("Sleep debt is the cumulative gap between the sleep your body needs and the sleep it actually gets. Unlike financial debt, you can't always feel it — but it compounds silently, day after day.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Color.ink1)
                    .lineSpacing(5)
                    .staggerIn(appeared, delay: 0.1)

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("EXAMPLE WEEK")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(Color.ink2)
                        Spacer()
                        HStack(spacing: 10) {
                            onboardLegendDot(color: .sky, label: "Sleep")
                            onboardLegendDot(color: .coral.opacity(0.55), label: "Deficit")
                        }
                    }
                    VStack(spacing: 9) {
                        ForEach(Array(bars.enumerated()), id: \.offset) { i, bar in
                            HStack(spacing: 10) {
                                Text(bar.label)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.ink2)
                                    .frame(width: 30, alignment: .leading)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.04))
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(bar.hours >= 7 ? Color.mint : Color.sky)
                                            .frame(width: barAnimate ? geo.size.width * (bar.hours / 10) : 0)
                                            .animation(.spring(response: 0.7).delay(Double(i) * 0.07), value: barAnimate)
                                        if bar.deficit > 0 {
                                            HStack(spacing: 0) {
                                                Color.clear
                                                    .frame(width: barAnimate ? geo.size.width * (bar.hours / 10) : 0)
                                                    .animation(.spring(response: 0.7).delay(Double(i) * 0.07), value: barAnimate)
                                                RoundedRectangle(cornerRadius: 5)
                                                    .fill(Color.coral.opacity(0.35))
                                                    .frame(width: barAnimate ? geo.size.width * (bar.deficit / 10) : 0)
                                                    .animation(.spring(response: 0.7).delay(0.3 + Double(i) * 0.07), value: barAnimate)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 10)
                                Text(String(format: "%.1fh", bar.hours))
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(bar.hours >= 7 ? Color.mint : Color.ink2)
                                    .frame(width: 32, alignment: .trailing)
                            }
                        }
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Color.coral)
                        Text("Total debt this week: **\(String(format: "%.1f", totalDebt)) hours**")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Color.ink1)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.coral.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.coral.opacity(0.18), lineWidth: 1))
                    )
                }
                .padding(16)
                .background(cardBackground)
                .staggerIn(appeared, delay: 0.15)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            withAnimation { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { barAnimate = true }
        }
    }
}

// MARK: - Page 2: Cognitive Impact
private struct CognitiveImpactPage: View {
    @State private var appeared = false

    private let impacts: [(icon: String, title: String, detail: String, threshold: String)] = [
        ("brain.head.profile", "Memory & Focus", "After 17 hours awake, cognitive performance equals 0.05% BAC — legally impaired in most countries.", "17h awake"),
        ("bolt.slash.fill", "Reaction Time", "One week of 6h/night degrades reaction time as much as 24 hours of total sleep deprivation.", "6h × 7 days"),
        ("heart.slash.fill", "Mood & Emotion", "Sleep debt amplifies emotional reactivity by up to 60%, making stress significantly harder to manage.", "> 2h debt"),
        ("cross.case.fill", "Immune System", "Sleeping under 6h triples your risk of catching a cold compared to 7+ hours of sleep.", "< 6h/night"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    onboardTagLabel("THE IMPACT", color: .coral)
                    Text("What Sleep\nDebt Does to You")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Color.ink0)
                        .lineSpacing(2)
                }
                .padding(.top, 16)
                .staggerIn(appeared, delay: 0)

                Text("The effects are measurable, scientifically documented — and most people experience them every day without knowing the cause.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Color.ink1)
                    .lineSpacing(5)
                    .staggerIn(appeared, delay: 0.1)

                VStack(spacing: 10) {
                    ForEach(Array(impacts.enumerated()), id: \.offset) { i, item in
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.coral.opacity(0.10))
                                    .frame(width: 42, height: 42)
                                Image(systemName: item.icon)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Color.coral)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.ink0)
                                    Spacer()
                                    Text(item.threshold)
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color.coral.opacity(0.8))
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Capsule().fill(Color.coral.opacity(0.10)))
                                }
                                Text(item.detail)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(Color.ink1)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(14)
                        .background(cardBackground)
                        .staggerIn(appeared, delay: 0.15 + Double(i) * 0.08)
                    }
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "books.vertical.fill")
                        .foregroundStyle(Color.ink2).font(.system(size: 12))
                    Text("Based on peer-reviewed research from Harvard Medical School, University of Pennsylvania, and the National Sleep Foundation.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.ink2).lineSpacing(3)
                }
                .staggerIn(appeared, delay: 0.5)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Page 3: Caffeine
private struct CaffeinePage: View {
    @State private var appeared = false
    @State private var timelineAnimate = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    onboardTagLabel("DID YOU KNOW", color: .amber)
                    Text("Caffeine Has a\n6-Hour Half-Life")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Color.ink0)
                        .lineSpacing(2)
                }
                .padding(.top, 16)
                .staggerIn(appeared, delay: 0)

                Text("Half the caffeine from a 2 PM coffee is still in your bloodstream at 8 PM — blocking the receptors that make you feel sleepy, even if you don't feel wired.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Color.ink1)
                    .lineSpacing(5)
                    .staggerIn(appeared, delay: 0.1)

                VStack(alignment: .leading, spacing: 14) {
                    Text("CAFFEINE DECAY (200mg at 2 PM)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(2).foregroundStyle(Color.ink2)
                    CaffeineTimeline(animate: timelineAnimate)
                }
                .padding(16)
                .background(cardBackground)
                .staggerIn(appeared, delay: 0.15)

                VStack(alignment: .leading, spacing: 12) {
                    Text("The Vicious Cycle")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.ink0)
                    cycleStepView("1", "Poor sleep → feel exhausted next day", .coral)
                    cycleStepView("2", "Drink more caffeine to get through the day", .amber)
                    cycleStepView("3", "Late caffeine blocks deep sleep that night", .amber)
                    cycleStepView("4", "Sleep debt grows — repeat indefinitely 🔁", .coral)
                }
                .padding(16)
                .background(cardBackground)
                .staggerIn(appeared, delay: 0.25)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            withAnimation { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { timelineAnimate = true }
        }
    }

    private func cycleStepView(_ num: String, _ text: String, _ color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 26, height: 26)
                Text(num)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(color)
            }
            Text(text)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Color.ink1)
        }
    }
}

private struct CaffeineTimeline: View {
    let animate: Bool
    private let events: [(time: String, level: Double, isWarning: Bool)] = [
        ("2 PM",  1.00, false),
        ("5 PM",  0.50, false),
        ("8 PM",  0.25, true),
        ("11 PM", 0.125, true),
        ("2 AM",  0.06, true),
    ]
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                ForEach([0.25, 0.5, 0.75], id: \.self) { level in
                    Rectangle()
                        .fill(Color.white.opacity(0.04)).frame(height: 1)
                        .offset(y: -geo.size.height * CGFloat(level))
                }
                if animate {
                    Path { path in
                        let pts = events.enumerated().map { i, e in
                            CGPoint(x: geo.size.width * CGFloat(i) / CGFloat(events.count - 1),
                                    y: geo.size.height * (1 - e.level))
                        }
                        path.move(to: CGPoint(x: 0, y: geo.size.height))
                        path.addLine(to: pts[0])
                        pts.dropFirst().forEach { path.addLine(to: $0) }
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [Color.amber.opacity(0.22), .clear], startPoint: .top, endPoint: .bottom))
                    .transition(.opacity).animation(.easeIn(duration: 0.6), value: animate)
                }
                Path { path in
                    let pts = events.enumerated().map { i, e in
                        CGPoint(x: geo.size.width * CGFloat(i) / CGFloat(events.count - 1),
                                y: geo.size.height * (1 - e.level))
                    }
                    path.move(to: pts[0])
                    pts.dropFirst().forEach { path.addLine(to: $0) }
                }
                .trim(from: 0, to: animate ? 1 : 0)
                .stroke(Color.amber, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .animation(.easeInOut(duration: 1.0), value: animate)

                ForEach(Array(events.enumerated()), id: \.offset) { i, event in
                    let x = geo.size.width * CGFloat(i) / CGFloat(events.count - 1)
                    let y = geo.size.height * (1 - event.level)
                    VStack(spacing: 4) {
                        if event.isWarning {
                            Image(systemName: "moon.zzz")
                                .font(.system(size: 8)).foregroundStyle(Color.coral.opacity(0.7))
                        }
                        Circle()
                            .fill(event.isWarning ? Color.coral : Color.amber)
                            .frame(width: 7, height: 7)
                            .overlay(Circle().stroke(Color.surface1, lineWidth: 1.5))
                        Text(event.time)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(event.isWarning ? Color.coral : Color.ink2)
                    }
                    .position(x: x, y: y)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut.delay(0.8 + Double(i) * 0.1), value: animate)
                }
            }
        }
        .frame(height: 130)
    }
}

// MARK: - Page 4: Why This App
private struct WhyAppPage: View {
    @State private var appeared = false

    private let reasons: [(icon: String, color: Color, title: String, body: String)] = [
        ("eye.slash.fill",       .coral,    "You Can't Feel It",       "Sleep debt is invisible until it's severe. By the time you feel impaired, you've already been running below optimal for days."),
        ("chart.xyaxis.line",    .sky,   "Data Beats Guessing",     "Tracking sleep, caffeine timing, and mood together reveals connections you'd never notice on your own."),
        ("arrow.triangle.2.circlepath", .lilac, "Patterns Repeat", "Your worst energy days follow predictable patterns. Once you see them, you can break them."),
        ("trophy.fill",          .amber,   "Small Changes Win",       "Shifting bedtime 30 minutes earlier or cutting caffeine at 2 PM instead of 4 PM can add 1+ hour of quality sleep per night."),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    onboardTagLabel("WHY THIS APP", color: .sky)
                    Text("See What Your\nBody Can't Tell You")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Color.ink0)
                        .lineSpacing(2)
                }
                .padding(.top, 16)
                .staggerIn(appeared, delay: 0)

                Text("The gap between how you think you're performing and how you're actually performing grows with every missed hour of sleep. Sleep Metric closes that gap.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Color.ink1)
                    .lineSpacing(5)
                    .staggerIn(appeared, delay: 0.1)

                VStack(spacing: 10) {
                    ForEach(Array(reasons.enumerated()), id: \.offset) { i, reason in
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(reason.color.opacity(0.12)).frame(width: 44, height: 44)
                                Image(systemName: reason.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(reason.color)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reason.title)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.ink0)
                                Text(reason.body)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(Color.ink1)
                                    .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(14).background(cardBackground)
                        .staggerIn(appeared, delay: 0.15 + Double(i) * 0.08)
                    }
                }
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Page 5: How It Works
private struct HowItWorksPage: View {
    @State private var appeared = false

    private let steps: [(num: String, icon: String, color: Color, title: String, body: String)] = [
        ("01", "moon.fill",               .sky,   "Log Your Sleep",    "Enter bedtime and wake time each morning. Takes 10 seconds. Sleep debt is calculated automatically."),
        ("02", "cup.and.heat.waves.fill", .amber,   "Track Caffeine",    "Log drinks from a preset list. Anything after 2 PM gets flagged with a warning."),
        ("03", "face.smiling.fill",       .lilac, "Check Your Mood",   "A quick 1–10 mood score each evening, with an optional note. Correlates with your sleep quality over time."),
        ("04", "bolt.heart.fill",         .mint,  "Read Your Score",   "Your Energy Score updates daily — combining sleep debt, caffeine timing, and mood into one clear number."),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    onboardTagLabel("HOW IT WORKS", color: .mint)
                    Text("Three Inputs.\nOne Score.")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Color.ink0)
                        .lineSpacing(2)
                }
                .padding(.top, 16)
                .staggerIn(appeared, delay: 0)

                Text("Logging takes under a minute a day. The patterns it reveals are worth far more than that.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Color.ink1)
                    .lineSpacing(5)
                    .staggerIn(appeared, delay: 0.1)

                VStack(spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 0) {
                                ZStack {
                                    Circle().fill(step.color.opacity(0.14)).frame(width: 40, height: 40)
                                    Image(systemName: step.icon)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(step.color)
                                }
                                if i < steps.count - 1 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.07))
                                        .frame(width: 1.5, height: 28)
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(step.num)
                                        .font(.system(size: 10, weight: .black, design: .rounded))
                                        .foregroundStyle(step.color.opacity(0.6))
                                    Text(step.title)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.ink0)
                                }
                                Text(step.body)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(Color.ink1)
                                    .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                                    .padding(.bottom, i < steps.count - 1 ? 18 : 0)
                            }
                        }
                        .staggerIn(appeared, delay: 0.15 + Double(i) * 0.1)
                    }
                }
                .padding(16).background(cardBackground)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { withAnimation { appeared = true } }
    }
}

// MARK: - Page 6: Ready
private struct ReadyPage: View {
    @State private var appeared = false
    @State private var pulse = false

    private let perks: [String] = [
        "Personalised energy score updated daily",
        "Smart insights based on your own patterns",
        "Daily reminders so you never miss a log",
        "Sleep history & trends over time",
        "Caffeine warnings before they hurt your sleep",
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer(minLength: 30)
                ZStack {
                    ForEach(0..<2) { i in
                        Circle()
                            .stroke(Color.mint.opacity(pulse ? 0.04 : 0.10), lineWidth: 1)
                            .frame(width: CGFloat(160 + i * 50), height: CGFloat(160 + i * 50))
                            .scaleEffect(pulse ? 1.04 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(Double(i) * 0.3), value: pulse)
                    }
                    EnergyRing(score: 87, animatedScore: appeared ? 87 : 0, size: 160)
                }
                .padding(.bottom, 32)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.7)
                .animation(.spring(response: 0.7).delay(0.1), value: appeared)

                VStack(spacing: 10) {
                    Text("You're Ready.")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Color.ink0)
                    Text("Log for 3 days and your first\npersonalised insights will appear.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(Color.ink1)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(.easeOut.delay(0.2), value: appeared)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)

                VStack(alignment: .leading, spacing: 13) {
                    ForEach(Array(perks.enumerated()), id: \.offset) { i, perk in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.mint)
                            Text(perk)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(Color.ink1)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : -12)
                        .animation(.easeOut(duration: 0.4).delay(0.3 + Double(i) * 0.07), value: appeared)
                    }
                }
                .padding(18).background(cardBackground)
                .padding(.horizontal, 24)

                Spacer(minLength: 100)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            withAnimation { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { pulse = true }
        }
    }
}

// MARK: - Shared Helpers (file-private)
private func onboardTagLabel(_ text: String, color: Color) -> some View {
    HStack(spacing: 6) {
        RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 3, height: 14)
        Text(text)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .tracking(2).foregroundStyle(color)
    }
}

private func onboardLegendDot(color: Color, label: String) -> some View {
    HStack(spacing: 5) {
        Circle().fill(color).frame(width: 7, height: 7)
        Text(label).font(.system(size: 10, design: .rounded)).foregroundStyle(Color.ink2)
    }
}

private extension View {
    func staggerIn(_ appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.easeOut(duration: 0.45).delay(delay), value: appeared)
    }
}

