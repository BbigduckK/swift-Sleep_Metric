import SwiftUI
import SwiftData

// MARK: - Chronotype Model
struct Chronotype {
    let id: String
    let name: String
    let animal: String        // emoji
    let tagline: String
    let description: String
    let color: Color
    let idealBedtime: String
    let idealWake: String
    let peakFocus: String
    let peakExercise: String
    let caffeineAdvice: String
    let population: String
    let traits: [String]
    let tips: [String]

    static let lion = Chronotype(
        id: "lion", name: "Lion", animal: "🦁", tagline: "Early Riser · Morning Powerhouse",
        description: "Lions wake early and naturally, dominate mornings with laser focus, and fade by evening. You're likely in leadership roles and highly productive before noon.",
        color: .amber,
        idealBedtime: "10:00–10:30 PM", idealWake: "5:30–6:00 AM",
        peakFocus: "8 AM – 12 PM", peakExercise: "5–7 AM",
        caffeineAdvice: "First coffee at 8 AM (skip 6–7:30 AM cortisol peak). Stop by 12 PM.",
        population: "~15% of people",
        traits: ["Optimistic & goal-oriented", "Productive in mornings", "Struggles staying up late", "Health-conscious"],
        tips: ["Schedule creative and analytical work before noon", "Avoid evening social obligations if possible", "Your body naturally rises — don't fight it with alarm clocks on weekends"]
    )
    static let bear = Chronotype(
        id: "bear", name: "Bear", animal: "🐻", tagline: "Solar-Synced · The Most Common Type",
        description: "Bears follow the sun. You wake somewhat easily, hit your stride mid-morning, slump after lunch, then catch a second wind in the late afternoon. Most of society is built for Bears.",
        color: .sky,
        idealBedtime: "11:00 PM", idealWake: "7:00 AM",
        peakFocus: "10 AM – 2 PM", peakExercise: "7:30–9 AM or 5–7 PM",
        caffeineAdvice: "First coffee at 9:30 AM. Nap-friendly at 1–2 PM (20 min max). Cut off by 2 PM.",
        population: "~55% of people",
        traits: ["Friendly & social", "Steady energy through the day", "Post-lunch slump around 1–2 PM", "Adaptable to most schedules"],
        tips: ["Leverage your 10 AM–2 PM peak for deep work", "A 20-min nap at 1 PM boosts afternoon performance", "Avoid late-night screens — your melatonin rises on schedule around 10 PM"]
    )
    static let wolf = Chronotype(
        id: "wolf", name: "Wolf", animal: "🐺", tagline: "Night Owl · Creative & Intense",
        description: "Wolves come alive at night. Mornings are painful. Your creativity and social energy peak in the evenings, and you naturally push bedtime past midnight.",
        color: .lilac,
        idealBedtime: "12:00–1:00 AM", idealWake: "7:30–8:00 AM",
        peakFocus: "5 PM – 12 AM", peakExercise: "6–8 PM",
        caffeineAdvice: "First coffee no earlier than 11 AM. Use sparingly — you're already alert at night. Cut off by 4 PM.",
        population: "~15% of people",
        traits: ["Creative & risk-taking", "Introspective and intense", "Struggles with early schedules", "Social energy peaks at night"],
        tips: ["Protect your evening peak — do your best creative work then", "Use bright light therapy in the morning to shift your clock earlier if needed", "Avoid early-morning meetings when possible"]
    )
    static let dolphin = Chronotype(
        id: "dolphin", name: "Dolphin", animal: "🐬", tagline: "Light Sleeper · Anxious Achiever",
        description: "Dolphins are light, fitful sleepers who wake at every sound. You're often intelligent and detail-oriented, but sleep deprivation is your constant battle.",
        color: .mint,
        idealBedtime: "11:30 PM", idealWake: "6:30 AM",
        peakFocus: "10 AM – 12 PM (brief window)", peakExercise: "7:30 AM",
        caffeineAdvice: "Minimize caffeine — your nervous system is already over-sensitised. Max 1 cup before noon.",
        population: "~10% of people",
        traits: ["Intelligent & detail-oriented", "Anxious and hypervigilant", "Light, interrupted sleep", "Perfectionist tendencies"],
        tips: ["Strict sleep hygiene matters more for you than anyone else", "Keep your room cool and dark — you're highly sensitive to environment", "Avoid news or stressful content within 2 hours of bed"]
    )

    static func from(id: String) -> Chronotype {
        switch id {
        case "lion": return .lion; case "wolf": return .wolf; case "dolphin": return .dolphin
        default: return .bear
        }
    }
}

// MARK: - Quiz Questions (based on Morningness-Eveningness Questionnaire, MEQ)
struct QuizQuestion: Identifiable {
    let id: Int
    let text: String
    let options: [String]
    // scores[i] → lion, bear, wolf, dolphin weights
    let weights: [[Int]]  // weights[optionIndex][chronotypeIndex (0=lion,1=bear,2=wolf,3=dolphin)]
}

let chronotypeQuestions: [QuizQuestion] = [
    QuizQuestion(id: 0, text: "If you could choose freely, what time would you wake up?",
        options: ["Before 6 AM", "6–7:30 AM", "7:30–9 AM", "After 9 AM"],
        weights: [[4,1,0,1],[3,3,1,2],[1,3,3,2],[0,1,4,1]]),
    QuizQuestion(id: 1, text: "How do you feel in the first 30 minutes after waking?",
        options: ["Alert and ready", "Slightly groggy but fine", "Quite groggy for a while", "Very groggy, need an hour"],
        weights: [[4,2,0,1],[2,3,1,2],[0,2,3,1],[0,1,4,3]]),
    QuizQuestion(id: 2, text: "At what time does your body feel most mentally sharp?",
        options: ["Before 10 AM", "10 AM – 1 PM", "1–5 PM", "Evening or later"],
        weights: [[4,2,0,1],[2,4,1,2],[0,2,3,1],[0,1,4,1]]),
    QuizQuestion(id: 3, text: "You have an important exam or meeting. When would you perform best?",
        options: ["7–9 AM", "10 AM – 12 PM", "3–5 PM", "7–9 PM"],
        weights: [[4,2,1,2],[3,4,1,2],[1,2,3,2],[0,1,4,1]]),
    QuizQuestion(id: 4, text: "How do you feel about going to bed at 11 PM?",
        options: ["Too late — I'm already tired", "Fine, that's about right", "Still wide awake", "Way too early"],
        weights: [[4,1,0,0],[2,4,1,2],[0,2,4,1],[0,1,3,3]]),
    QuizQuestion(id: 5, text: "How tired do you feel by 10 PM?",
        options: ["Very tired, often asleep", "Somewhat tired", "Just starting to unwind", "Still energised"],
        weights: [[4,2,0,1],[3,4,1,2],[0,2,3,1],[0,1,4,2]]),
    QuizQuestion(id: 6, text: "What best describes your relationship with sleep?",
        options: ["Deep sleeper, hard to wake me", "Sleep well, wake when needed", "Light sleeper, wake easily", "Inconsistent — sometimes great, sometimes terrible"],
        weights: [[3,3,0,0],[2,3,1,1],[0,1,3,4],[1,2,2,3]]),
    QuizQuestion(id: 7, text: "When do you feel most creative or inspired?",
        options: ["Early morning", "Mid-morning", "Afternoon", "Evening or late night"],
        weights: [[4,2,0,1],[3,3,1,1],[1,2,3,1],[0,1,4,2]]),
    QuizQuestion(id: 8, text: "On weekends with no alarm, when do you naturally wake?",
        options: ["Same time as weekdays (before 7)", "7–8:30 AM", "8:30–10 AM", "After 10 AM"],
        weights: [[4,2,0,2],[3,4,1,2],[1,2,3,1],[0,1,4,1]]),
    QuizQuestion(id: 9, text: "How would you describe your energy throughout the day?",
        options: ["High in morning, drops by afternoon", "Steady with a mid-afternoon dip", "Slow start, builds through the day", "Unpredictable — hard to say"],
        weights: [[4,1,0,0],[2,4,1,2],[0,2,4,1],[1,1,1,4]]),
]

// MARK: - Chronotype Quiz View
struct ChronotypeQuizView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ChronotypeResult.completedAt, order: .reverse) var results: [ChronotypeResult]
    @AppStorage("hasCompletedChronotype") private var hasCompletedChronotype = false

    @State private var currentQ = 0
    @State private var answers: [Int] = Array(repeating: -1, count: 10)
    @State private var showResult = false
    @State private var resultChronotype: Chronotype? = nil
    @State private var animDir: Int = 1  // 1 = forward, -1 = back

    var body: some View {
        ZStack {
            Color.surface1.ignoresSafeArea()

            // Ambient glow
            if let ct = resultChronotype {
                Circle().fill(ct.color.opacity(0.06)).frame(width: 500).blur(radius: 100).offset(y: -200).allowsHitTesting(false)
            } else {
                Circle().fill(Color.lilac.opacity(0.05)).frame(width: 500).blur(radius: 100).offset(y: -200).allowsHitTesting(false)
            }

            if showResult, let ct = resultChronotype {
                ChronotypeResultView(chronotype: ct) { dismiss() }
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            } else {
                quizBody
                    .transition(.asymmetric(insertion: .move(edge: animDir > 0 ? .trailing : .leading).combined(with: .opacity), removal: .opacity))
            }
        }
        .modifier(SheetBackgroundModifier())
        .onAppear {
            if let existing = results.first {
                resultChronotype = Chronotype.from(id: existing.chronotype)
                showResult = true
            }
        }
    }

    private var quizBody: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress
                VStack(spacing: 8) {
                    HStack {
                        Text("Question \(currentQ + 1) of \(chronotypeQuestions.count)")
                            .font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink2)
                        Spacer()
                        Text("\(Int((Double(currentQ) / Double(chronotypeQuestions.count)) * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Color.lilac)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.07))
                            RoundedRectangle(cornerRadius: 3).fill(Color.lilac)
                                .frame(width: geo.size.width * Double(currentQ) / Double(chronotypeQuestions.count))
                                .animation(.spring(response: 0.5), value: currentQ)
                        }
                    }.frame(height: 4)
                }
                .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 24)

                // Question
                let q = chronotypeQuestions[currentQ]
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Text(q.text)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(Color.ink0)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 16)
                            .id(currentQ) // forces re-render on question change

                        VStack(spacing: 10) {
                            ForEach(Array(q.options.enumerated()), id: \.offset) { i, opt in
                                optionButton(opt, index: i, questionID: currentQ)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Chronotype Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.surface1, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if currentQ > 0 {
                        Button { withAnimation { animDir = -1; currentQ -= 1 } } label: {
                            Image(systemName: "chevron.left").foregroundStyle(Color.ink1)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") { dismiss() }.foregroundStyle(Color.ink2)
                        .font(.system(size: 14, design: .rounded))
                }
            }
        }
    }

    private func optionButton(_ text: String, index: Int, questionID: Int) -> some View {
        let isSelected = answers[questionID] == index
        return Button {
            withAnimation(.spring(response: 0.3)) { answers[currentQ] = index }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.4)) {
                    animDir = 1
                    if currentQ < chronotypeQuestions.count - 1 {
                        currentQ += 1
                    } else {
                        finishQuiz()
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.lilac : Color.white.opacity(0.06))
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(isSelected ? Color.lilac : Color.surfaceLine, lineWidth: 1.5))
                    if isSelected {
                        Circle().fill(Color.surface1).frame(width: 8, height: 8)
                    }
                }
                Text(text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(isSelected ? Color.ink0 : Color.ink1)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.lilac.opacity(0.10) : Color.surface2)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.lilac.opacity(0.4) : Color.clear, lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }

    private func finishQuiz() {
        // Tally scores per chronotype: lion=0, bear=1, wolf=2, dolphin=3
        var scores = [0, 0, 0, 0]
        for (qi, answerIdx) in answers.enumerated() {
            guard answerIdx >= 0, qi < chronotypeQuestions.count else { continue }
            let w = chronotypeQuestions[qi].weights[min(answerIdx, chronotypeQuestions[qi].weights.count - 1)]
            for i in 0..<4 { scores[i] += w[i] }
        }
        let maxIdx = scores.indices.max(by: { scores[$0] < scores[$1] }) ?? 1
        let types = ["lion", "bear", "wolf", "dolphin"]
        let typeID = types[maxIdx]
        let ct = Chronotype.from(id: typeID)

        // Save result
        results.forEach { context.delete($0) }
        context.insert(ChronotypeResult(chronotype: typeID, answers: answers))
        hasCompletedChronotype = true

        withAnimation(.spring(response: 0.5)) {
            resultChronotype = ct
            showResult = true
        }
    }
}

// MARK: - Result View
struct ChronotypeResultView: View {
    let chronotype: Chronotype
    let onDone: () -> Void
    @State private var appeared = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()
                Circle().fill(chronotype.color.opacity(0.08)).frame(width: 500).blur(radius: 100).offset(y: -200).allowsHitTesting(false)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero
                        VStack(spacing: 10) {
                            Text(chronotype.animal).font(.system(size: 80))
                                .scaleEffect(appeared ? 1 : 0.3).animation(.spring(response: 0.7, dampingFraction: 0.6), value: appeared)
                            Text("You're a \(chronotype.name)").font(.system(size: 28, weight: .black, design: .rounded)).foregroundStyle(chronotype.color)
                            Text(chronotype.tagline).font(.system(size: 14, design: .rounded)).foregroundStyle(Color.ink2)
                            Text(chronotype.population).font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1)
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(Capsule().fill(chronotype.color.opacity(0.1)).overlay(Capsule().stroke(chronotype.color.opacity(0.3), lineWidth: 1)))
                                .foregroundStyle(chronotype.color)
                        }
                        .padding(.top, 12)
                        .opacity(appeared ? 1 : 0).animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                        // Description
                        Text(chronotype.description)
                            .font(.system(size: 14, design: .rounded)).foregroundStyle(Color.ink1).lineSpacing(5).multilineTextAlignment(.center).padding(.horizontal, 8)
                            .stagger(appeared: appeared, delay: 0.3)

                        // Schedule card
                        scheduleCard.stagger(appeared: appeared, delay: 0.35)

                        // Traits
                        traitsCard.stagger(appeared: appeared, delay: 0.40)

                        // Optimisation tips
                        tipsCard.stagger(appeared: appeared, delay: 0.45)

                        // Done
                        Button(action: onDone) {
                            Text("Save My Chronotype")
                                .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Color.surface0)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(chronotype.color).clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 8)
                        .stagger(appeared: appeared, delay: 0.50)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24).padding(.bottom, 32)
                }
            }
            .navigationTitle("Your Chronotype")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.surface1, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear { withAnimation { appeared = true } }
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "YOUR OPTIMAL SCHEDULE")
            VStack(spacing: 10) {
                schedRow("moon.fill",             .sky,          "Ideal Bedtime",    chronotype.idealBedtime)
                schedRow("sun.horizon.fill",       .amber,        "Ideal Wake",       chronotype.idealWake)
                schedRow("brain.head.profile",     chronotype.color, "Peak Focus",   chronotype.peakFocus)
                schedRow("figure.run",             .mint,         "Best Exercise",    chronotype.peakExercise)
                schedRow("cup.and.heat.waves.fill", .amber,       "Caffeine",         chronotype.caffeineAdvice)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.surface2).overlay(RoundedRectangle(cornerRadius: 20).stroke(chronotype.color.opacity(0.2), lineWidth: 1)))
    }

    private func schedRow(_ icon: String, _ color: Color, _ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(color).frame(width: 18).padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 10, weight: .black, design: .rounded)).tracking(1).foregroundStyle(Color.ink2)
                Text(value).font(.system(size: 13, design: .rounded)).foregroundStyle(Color.ink0).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var traitsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "YOUR TRAITS")
            ForEach(chronotype.traits, id: \.self) { trait in
                HStack(spacing: 8) {
                    Circle().fill(chronotype.color).frame(width: 5, height: 5)
                    Text(trait).font(.system(size: 13, design: .rounded)).foregroundStyle(Color.ink1)
                }
            }
        }
        .padding(18).background(cardBackground)
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "OPTIMISE YOUR TYPE")
            ForEach(Array(chronotype.tips.enumerated()), id: \.offset) { i, tip in
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        Circle().fill(chronotype.color.opacity(0.12)).frame(width: 22, height: 22)
                        Text("\(i+1)").font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(chronotype.color)
                    }
                    Text(tip).font(.system(size: 13, design: .rounded)).foregroundStyle(Color.ink1).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18).background(cardBackground)
    }
}

