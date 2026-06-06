import SwiftUI

struct ExtractionProgressView: View {
    let steps: [ExtractionStep]

    @State private var pulse = false

    var completedCount: Int { steps.filter { $0.isDone }.count }
    var progress: Double { steps.isEmpty ? 0 : Double(completedCount) / Double(steps.count) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(AppTheme.goldFaint)
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulse ? 1.08 : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                    Text("✦")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.gold)
                        .rotationEffect(.degrees(pulse ? 20 : -20))
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                }
                .onAppear { pulse = true }

                VStack(spacing: 8) {
                    Text("Reading your CV")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Extracting your details…")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textMuted)
                }

                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppTheme.bgElevated)
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppTheme.gold)
                                .frame(width: geo.size.width * progress, height: 4)
                                .animation(.easeInOut(duration: 0.5), value: progress)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 40)
                }

                // Step checklist
                VStack(spacing: 0) {
                    ForEach(steps) { step in
                        stepRow(step)
                        if step.id != steps.last?.id {
                            Divider()
                                .background(AppTheme.bgElevated)
                                .padding(.horizontal, 40)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
    }

    private func stepRow(_ step: ExtractionStep) -> some View {
        HStack(spacing: 12) {
            ZStack {
                if step.isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                        .font(.system(size: 18))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .stroke(AppTheme.bgBorder, lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(AppTheme.gold, lineWidth: 1.5)
                                .rotationEffect(.degrees(pulse ? 360 : 0))
                                .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: pulse)
                                .frame(width: 18, height: 18)
                        )
                }
            }
            .frame(width: 24)
            .animation(.spring(duration: 0.4), value: step.isDone)

            Text(step.label)
                .font(.system(size: 14))
                .foregroundStyle(step.isDone ? AppTheme.textPrimary : AppTheme.textMuted)
                .animation(.easeInOut, value: step.isDone)

            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 40)
    }
}
