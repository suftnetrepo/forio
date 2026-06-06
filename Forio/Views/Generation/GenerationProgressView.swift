import SwiftUI

struct GenerationProgressView: View {
    @Bindable var viewModel: GenerationViewModel
    @State private var pulse = false
    @State private var rotate = false

    var progress: Double {
        let done = viewModel.progressSteps.filter { $0.isDone }.count
        return viewModel.progressSteps.isEmpty ? 0
             : Double(done) / Double(viewModel.progressSteps.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                // Animated orb
                ZStack {
                    Circle()
                        .fill(AppTheme.goldFaint)
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulse ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                            value: pulse
                        )

                    Circle()
                        .trim(from: 0, to: 0.65)
                        .stroke(AppTheme.goldBorder, lineWidth: 1.5)
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(rotate ? 360 : 0))
                        .animation(
                            .linear(duration: 2.0).repeatForever(autoreverses: false),
                            value: rotate
                        )

                    Text("✦")
                        .font(.system(size: 36))
                        .foregroundStyle(AppTheme.gold)
                }
                .onAppear {
                    pulse = true
                    rotate = true
                }

                VStack(spacing: 8) {
                    Text("Crafting your CV")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("AI is tailoring every line to this job")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textMuted)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.bgElevated)
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.gold, AppTheme.goldLight],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 5)
                            .animation(.easeInOut(duration: 0.6), value: progress)
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 40)

                // Step list
                VStack(spacing: 0) {
                    ForEach(viewModel.progressSteps) { step in
                        stepRow(step)
                        if step.id != viewModel.progressSteps.last?.id {
                            Divider()
                                .background(AppTheme.bgElevated)
                                .padding(.horizontal, 40)
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Live AI insight
                if !viewModel.aiInsightText.isEmpty {
                    HStack(spacing: 8) {
                        Text("✦")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.gold)
                        Text(viewModel.aiInsightText)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textMuted)
                            .lineSpacing(2)
                        Spacer()
                    }
                    .padding(12)
                    .background(AppTheme.goldFaint)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                            .stroke(AppTheme.goldBorder, lineWidth: 0.5)
                    )
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.4), value: viewModel.aiInsightText)
                }
            }

            Spacer()
        }
    }

    private func stepRow(_ step: GenerationStep) -> some View {
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
                                .rotationEffect(.degrees(rotate ? 360 : 0))
                                .animation(
                                    .linear(duration: 1.0).repeatForever(autoreverses: false),
                                    value: rotate
                                )
                                .frame(width: 18, height: 18)
                        )
                }
            }
            .frame(width: 24)
            .animation(.spring(duration: 0.4), value: step.isDone)

            Text(step.label)
                .font(.system(size: 14))
                .foregroundStyle(step.isDone ? AppTheme.textPrimary : AppTheme.textMuted)

            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 40)
    }
}
