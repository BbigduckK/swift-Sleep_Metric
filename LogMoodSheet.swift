import SwiftUI
import SwiftData

struct LogMoodSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var score: Int = 5
    @State private var note: String = ""
    @State private var scoreTouched = false
    @State private var showConfirm = false
    @State private var saved = false
    @FocusState private var noteFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Live Mood Preview Banner ──
                        VStack(spacing: 10) {
                            Text(score.moodEmoji)
                                .font(.system(size: 72))
                                .animation(.spring(response: 0.4), value: score)

                            VStack(spacing: 4) {
                                Text(score.moodLabel)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.ink0)
                                    .animation(.easeOut, value: score)

                                HStack(spacing: 6) {
                                    ForEach(1...10, id: \.self) { i in
                                        Circle()
                                            .fill(i <= score ? moodSliderColor : Color.white.opacity(0.1))
                                            .frame(width: i == score ? 9 : 5, height: i == score ? 9 : 5)
                                            .animation(.spring(response: 0.25), value: score)
                                    }
                                }

                                Text("\(score) out of 10")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(moodSliderColor.opacity(0.8))
                                    .animation(.easeOut, value: score)
                            }

                            // Context message
                            if scoreTouched {
                                Text(moodContextMessage)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(Color.ink2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    .animation(.easeOut, value: score)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.surface1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(moodSliderColor.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)

                        // ── Slider Card ──
                        VStack(spacing: 14) {
                            SectionHeader(title: "HOW ARE YOU FEELING?")

                            Slider(value: Binding(
                                get: { Double(score) },
                                set: { newVal in
                                    score = Int(newVal.rounded())
                                    withAnimation { scoreTouched = true }
                                }
                            ), in: 1...10, step: 1)
                            .tint(moodSliderColor)

                            // Number labels
                            HStack(spacing: 0) {
                                ForEach(1...10, id: \.self) { i in
                                    VStack(spacing: 2) {
                                        Text("\(i)")
                                            .font(.system(size: i == score ? 13 : 10, weight: i == score ? .bold : .regular, design: .rounded))
                                            .foregroundStyle(i == score ? moodSliderColor : Color.ink2)
                                    }
                                    .animation(.spring(response: 0.25), value: score)
                                    .frame(maxWidth: .infinity)
                                }
                            }

                            // Quick tap moods
                            HStack(spacing: 8) {
                                quickMoodButton(emoji: "😞", label: "Very Low", value: 2)
                                quickMoodButton(emoji: "😕", label: "Low",      value: 4)
                                quickMoodButton(emoji: "😐", label: "Okay",     value: 6)
                                quickMoodButton(emoji: "🙂", label: "Good",     value: 8)
                                quickMoodButton(emoji: "😄", label: "Great",    value: 10)
                            }
                        }
                        .padding(18)
                        .background(cardBackground)
                        .padding(.horizontal)

                        // ── Note ──
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "ADD A NOTE (OPTIONAL)")
                            ZStack(alignment: .topLeading) {
                                if note.isEmpty {
                                    Text("What's affecting your mood today?")
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundStyle(Color.ink2)
                                        .padding(14)
                                        .allowsHitTesting(false)
                                }
                                TextField("", text: $note, axis: .vertical)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(Color.ink0)
                                    .lineLimit(3...6)
                                    .focused($noteFocused)
                                    .padding(14)
                            }
                            .background(cardBackground)
                        }
                        .padding(.horizontal)

                        // ── Summary before save ──
                        if scoreTouched {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("Your entry")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .tracking(1.5)
                                        .foregroundStyle(Color.ink2)
                                    Spacer()
                                }
                                HStack(spacing: 14) {
                                    Text(score.moodEmoji).font(.system(size: 28))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("\(score.moodLabel) · \(score)/10")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color.ink0)
                                        if !note.isEmpty {
                                            Text("\"\(note)\"")
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundStyle(Color.ink2)
                                                .lineLimit(1)
                                        } else {
                                            Text("No note added")
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundStyle(Color.ink2)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(moodSliderColor)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(moodSliderColor.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(moodSliderColor.opacity(0.2), lineWidth: 1))
                            )
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }

                        // ── Validation hint if not touched ──
                        if !scoreTouched {
                            HStack(spacing: 10) {
                                Image(systemName: "hand.draw.fill")
                                    .foregroundStyle(Color.lilac)
                                Text("Slide to set your mood score before saving.")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(Color.ink1)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.lilac.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.lilac.opacity(0.2), lineWidth: 1))
                            )
                            .padding(.horizontal)
                        }

                        // ── Save Button ──
                        PrimaryButton(
                            label: saved ? "Saved!" : "Save Mood",
                            icon: saved ? "checkmark" : "face.smiling",
                            color: scoreTouched ? moodSliderColor : Color.white.opacity(0.15)
                        ) {
                            if scoreTouched { showConfirm = true }
                        }
                        .padding(.horizontal)
                        .disabled(saved || !scoreTouched)
                    }
                    .padding(.bottom, 40)
                    .padding(.top, 8)
                }
                .onTapGesture { noteFocused = false }
            }
            .navigationTitle("Log Mood")
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
            .confirmationDialog("Save mood entry?", isPresented: $showConfirm, titleVisibility: .visible) {
                Button("Save \(score.moodLabel) (\(score)/10)") { saveMood() }
                Button("Edit", role: .cancel) {}
            } message: {
                Text(note.isEmpty
                     ? "\(score.moodEmoji) \(score.moodLabel) — \(score) out of 10"
                     : "\(score.moodEmoji) \(score.moodLabel) — \"\(note)\"")
            }
        }
        .modifier(SheetBackgroundModifier())
    }

    // MARK: - Helpers

    private var moodSliderColor: Color {
        switch score {
        case 1...3: return .coral
        case 4...5: return .amber
        case 6...7: return .sky
        default:    return .mint
        }
    }

    private var moodContextMessage: String {
        switch score {
        case 1...2: return "Rough day. Rest and recovery may help."
        case 3...4: return "Below average. Try to wind down early tonight."
        case 5...6: return "Feeling neutral — pretty normal for a weekday."
        case 7...8: return "Good energy today! Note what's working."
        case 9...10: return "Excellent! You're at your best."
        default: return ""
        }
    }

    private func quickMoodButton(emoji: String, label: String, value: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                score = value
                scoreTouched = true
            }
        } label: {
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 20))
                Text(label)
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(score == value ? moodSliderColor : Color.ink2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(score == value ? moodSliderColor.opacity(0.14) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(score == value ? moodSliderColor.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
    }

    private func saveMood() {
        let entry = MoodEntry(date: Date(), score: score, note: note)
        context.insert(entry)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
    }
}

