import SwiftUI

// MARK: - Color System
extension Color {
    static let surface0     = Color(red: 0.04, green: 0.05, blue: 0.08)
    static let surface1     = Color(red: 0.07, green: 0.09, blue: 0.13)
    static let surface2     = Color(red: 0.10, green: 0.13, blue: 0.18)
    static let surfaceLine  = Color(white: 1, opacity: 0.06)
    static let amber        = Color(red: 1.00, green: 0.75, blue: 0.20)
    static let mint         = Color(red: 0.20, green: 0.95, blue: 0.72)
    static let coral        = Color(red: 1.00, green: 0.38, blue: 0.35)
    static let sky          = Color(red: 0.35, green: 0.75, blue: 1.00)
    static let lilac        = Color(red: 0.72, green: 0.55, blue: 1.00)
    static let ink0         = Color(white: 0.96)
    static let ink1         = Color(white: 0.62)
    static let ink2         = Color(white: 0.32)
    
    // Aliases for backward compat
    static let bgDeep        = Color.surface0
    static let bgCard        = Color.surface1
    static let bgCardBorder  = Color.surfaceLine
    static let bgSheet       = Color.surface1
    static let accentGold    = Color.amber
    static let accentRed     = Color.coral
    static let accentGreen   = Color.mint
    static let accentBlue    = Color.sky
    static let accentPurple  = Color.lilac
    static let textPrimary   = Color.ink0
    static let textSecondary = Color.ink1
    static let textMuted     = Color.ink2
}

extension Int {
    var scoreColor: Color {
        switch self {
        case 75...100: return Color(red: 0.0, green: 0.78, blue: 0.74)
        case 45..<75:  return .amber
        default:       return .coral
        }
    }
    var moodEmoji: String {
        switch self {
        case 1...2: return "😞"; case 3...4: return "😕"
        case 5...6: return "😐"; case 7...8: return "🙂"
        default: return "😄"
        }
    }
    var moodLabel: String {
        switch self {
        case 1...2: return "Very Low"; case 3...4: return "Low"
        case 5...6: return "Neutral";  case 7...8: return "Good"
        default: return "Excellent"
        }
    }
}

extension String {
    var riskColor: Color {
        switch self {
        case "Low": 
            return Color(red: 0.0, green: 0.78, blue: 0.74)
        case "Mild": 
            return .sky
        case "Moderate": 
            return .amber
        default: 
            return .coral
        }
    }
}

// MARK: - Card Backgrounds
var cardBackground: some View {
    RoundedRectangle(cornerRadius: 20)
        .fill(Color.surface1)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.surfaceLine, lineWidth: 1))
}

var elevatedCard: some View {
    RoundedRectangle(cornerRadius: 20)
        .fill(Color.surface2)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.surfaceLine, lineWidth: 1))
}

// MARK: - Energy Ring
struct EnergyRing: View {
    var score: Int
    var animatedScore: Double
    var size: CGFloat = 190
    var lineWidth: CGFloat = 14
    
    private var lw: CGFloat { lineWidth }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(score.scoreColor.opacity(0.06))
                .frame(width: size + 40, height: size + 40)
                .blur(radius: 20)
            
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: lw)
                .frame(width: size, height: size)
            
            ForEach(0..<20) { i in
                Rectangle()
                    .fill(Color.white.opacity(i % 5 == 0 ? 0.15 : 0.06))
                    .frame(width: i % 5 == 0 ? 2 : 1, height: i % 5 == 0 ? 6 : 3)
                    .offset(y: -(size / 2 + lw * 0.8))
                    .rotationEffect(.degrees(Double(i) * 18))
            }
            
            Circle()
                .trim(from: 0, to: max(0.005, animatedScore / 100))
                .stroke(
                    AngularGradient(
                        colors: [score.scoreColor.opacity(0.4), score.scoreColor],
                        center: .center,
                        startAngle: .degrees(-90), endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lw, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.3, dampingFraction: 0.72), value: animatedScore)
            
            Circle()
                .fill(score.scoreColor)
                .frame(width: lw * 0.85, height: lw * 0.85)
                .shadow(color: score.scoreColor, radius: 5)
                .offset(y: -(size / 2))
                .rotationEffect(.degrees(-90 + (animatedScore / 100) * 360))
                .animation(.spring(response: 1.3, dampingFraction: 0.72), value: animatedScore)
            
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: size * 0.28, weight: .black, design: .rounded))
                    .foregroundStyle(score.scoreColor)
                    .shadow(color: score.scoreColor.opacity(0.35), radius: 10)
                Text("SCORE")
                    .font(.system(size: size * 0.055, weight: .black, design: .rounded))
                    .tracking(4).foregroundStyle(Color.ink2)
            }
        }
    }
}

// MARK: - Streak Badge
struct StreakBadge: View {
    let streak: Int
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: 6) {
            Text("🔥")
                .font(.system(size: 14))
                .scaleEffect(pulse ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(streak) day streak")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color.amber)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(
            Capsule().fill(Color.amber.opacity(0.11))
                .overlay(Capsule().stroke(Color.amber.opacity(0.28), lineWidth: 1))
        )
        .onAppear { pulse = true }
    }
}

// MARK: - Risk Badge
struct RiskBadge: View {
    let risk: String
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(risk.riskColor).frame(width: 6, height: 6)
            Text(risk).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(risk.riskColor)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(risk.riskColor.opacity(0.1)).overlay(Capsule().stroke(risk.riskColor.opacity(0.2), lineWidth: 1)))
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .tracking(3).foregroundStyle(Color.ink2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let label: String; let icon: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon).font(.system(size: 15, weight: .bold))
                Text(label).font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color.surface0)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(color).clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Sheet Modifier
struct SheetBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View { content.background(Color.surface1) }
}

// MARK: - Sleep Bar Row
struct SleepBarRow: View {
    let entry: SleepEntry; let max: Double
    private var barColor: Color {
        if entry.duration >= 7 {
            return Color(red: 0.0, green: 0.78, blue: 0.74)
        } else if entry.duration >= 5 {
            return Color.amber
        } else {
            return Color.coral
        }
    }
    
    private var dayLabel: String { let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: entry.date).uppercased() }
    
    var body: some View {
        HStack(spacing: 10) {
            Text(dayLabel).font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(Color.ink2).frame(width: 28, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.04))
                    RoundedRectangle(cornerRadius: 4).fill(barColor)
                        .frame(width: geo.size.width * Swift.min(entry.duration / max, 1))
                        .animation(.spring(response: 0.7), value: entry.duration)
                }
            }.frame(height: 7)
            Text(String(format: "%.1fh", entry.duration)).font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(barColor).frame(width: 34, alignment: .trailing)
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String; let title: String; let message: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 40, weight: .semibold)).foregroundStyle(Color.ink2)
            Text(title).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(Color.ink1)
            Text(message).font(.system(size: 13, design: .rounded)).foregroundStyle(Color.ink2)
                .multilineTextAlignment(.center).lineSpacing(3)
        }.padding(.horizontal, 36)
    }
}

// MARK: - Research Tip Card
struct TipCard: View {
    let tip: SleepTip
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(tip.color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: tip.icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(tip.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tip.category.uppercased())
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(2).foregroundStyle(tip.color)
                    Spacer()
                    Text("Research").font(.system(size: 9, design: .rounded)).foregroundStyle(Color.ink2)
                }
                Text(tip.title).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Color.ink0)
                Text(tip.body).font(.system(size: 12, design: .rounded)).foregroundStyle(Color.ink1).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(Color.surface1)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(tip.color.opacity(0.2), lineWidth: 1))
        )
    }
}

// MARK: - Stagger modifier
extension View {
    func stagger(appeared: Bool, delay: Double) -> some View {
        self.opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)
            .animation(.easeOut(duration: 0.45).delay(delay), value: appeared)
    }
}


