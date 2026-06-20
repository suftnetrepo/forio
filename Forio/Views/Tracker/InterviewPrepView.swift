import SwiftUI
import SwiftData

// MARK: - Interview Prep

struct InterviewPrepView: View {
    let application: JobApplication
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var questions: [InterviewQuestion] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var currentIndex = 0
    @State private var showAnswer = false
    @State private var fontSize: CGFloat = 17
    @State private var showFontSlider = false

    private let currentPromptVersion = 2

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                if isLoading { loadingView }
                else if let err = error { errorView(err) }
                else if !questions.isEmpty { questionScreen }
            }
        }
        .task { await load() }
    }

    // MARK: Nav Bar

    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .bold))
                    Text("Close").font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(AppTheme.textMuted)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(AppTheme.bgCard).clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.bgBorder, lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Spacer()

            if !questions.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) { showFontSlider.toggle() }
                }) {
                    Text("AA")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(showFontSlider ? AppTheme.gold : AppTheme.textMuted)
                        .frame(width: 36, height: 36)
                        .background(showFontSlider ? AppTheme.goldFaint : AppTheme.bgCard)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(showFontSlider ? AppTheme.goldBorder : AppTheme.bgBorder, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 10)

                VStack(spacing: 1) {
                    Text("\(currentIndex + 1) of \(questions.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("questions")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textDisabled)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 10)
    }

    // MARK: Loading

    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.goldFaint).frame(width: 88, height: 88)
                ProgressView().tint(AppTheme.gold).scaleEffect(1.4)
            }
            VStack(spacing: 10) {
                Text("Preparing your interview")
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(AppTheme.textPrimary)
                Text("Generating 20 questions tailored to\nthis role and your CV")
                    .font(.system(size: 15)).foregroundStyle(AppTheme.textMuted)
                    .multilineTextAlignment(.center).lineSpacing(4)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: Error

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 52)).foregroundStyle(AppTheme.danger)
            Text("Something went wrong")
                .font(.system(size: 20, weight: .bold)).foregroundStyle(AppTheme.textPrimary)
            Text(msg).font(.system(size: 14)).foregroundStyle(AppTheme.textMuted).multilineTextAlignment(.center)
            Button("Try again") { Task { await load() } }
                .buttonStyle(GoldButtonStyle()).padding(.horizontal, 40)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: Question Screen

    private var questionScreen: some View {
        let q = questions[currentIndex]
        return VStack(spacing: 0) {

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(AppTheme.bgBorder).frame(height: 2)
                    Rectangle().fill(AppTheme.gold)
                        .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(questions.count), height: 2)
                        .animation(.spring(response: 0.4), value: currentIndex)
                }
            }
            .frame(height: 2)

            // Font size slider
            if showFontSlider {
                HStack(spacing: 12) {
                    Text("A").font(.system(size: 11)).foregroundStyle(AppTheme.textMuted)
                    Slider(value: $fontSize, in: 13...24, step: 1).tint(AppTheme.gold)
                    Text("A").font(.system(size: 17)).foregroundStyle(AppTheme.textMuted)
                }
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(AppTheme.bgCard)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Category + difficulty row
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Text(q.categoryEmoji).font(.system(size: 12))
                    Text(q.categoryLabel)
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(AppTheme.gold)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(AppTheme.goldFaint).clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.goldBorder, lineWidth: 0.5))

                HStack(spacing: 4) {
                    Circle().fill(q.difficultyColor).frame(width: 5, height: 5)
                    Text(q.difficulty.capitalized)
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(q.difficultyColor)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(q.difficultyColor.opacity(0.1)).clipShape(Capsule())

                Spacer()
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)

            // Scrollable content with fixed answer card — no gap, nav never pushed off
            ScrollView {
                VStack(spacing: 10) {

                    // ── QUESTION ──
                    VStack(alignment: .leading, spacing: 8) {
                        Text("QUESTION")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.textDisabled).tracking(1)
                        Text(q.text)
                            .font(.system(size: fontSize, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLg).stroke(AppTheme.bgBorder, lineWidth: 0.5))
                    .padding(.horizontal, 20)

                    // ── TIPS ──
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 13)).foregroundStyle(AppTheme.gold).padding(.top, 1)
                        Text(tipText(for: q))
                            .font(.system(size: max(13, fontSize - 3)))
                            .foregroundStyle(AppTheme.textSecond).lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.goldFaint)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd).stroke(AppTheme.goldBorder, lineWidth: 0.5))
                    .padding(.horizontal, 20)

                    // ── LIVE CODING ADVICE ──
                    if q.isLiveCoding && !q.liveCodingAdvice.isEmpty {
                        liveCodingSection(q: q).padding(.horizontal, 20)
                    }

                    // ── SAMPLE ANSWER FLIP CARD ──
                    // Fixed height so it's always fully visible, never creates a gap
                    answerCard(q: q)
                        .padding(.horizontal, 20)
                        .frame(height: 180)
                        .padding(.bottom, 16)
                }
                .padding(.top, 4)
                .padding(.bottom, 100) // clears the bottom nav bar
            }
            // Nav pinned at bottom — never pushed off screen
            .overlay(alignment: .bottom) { bottomNav }
        }
    }

    // MARK: Live Coding Section

    private func liveCodingSection(q: InterviewQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(Color.purple.opacity(0.15)).frame(width: 28, height: 28)
                    Text("⌨️").font(.system(size: 14))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("LIVE CODING TIPS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.purple).tracking(1)
                    Text("How to handle this in a live session")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }

            Rectangle().fill(Color.purple.opacity(0.15)).frame(height: 0.5)

            // Parse newline-separated advice into bullet rows
            let lines = q.liveCodingAdvice
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.purple.opacity(0.6))
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)
                        Text(line.hasPrefix("•") ? String(line.dropFirst()).trimmingCharacters(in: .whitespaces) : line)
                            .font(.system(size: max(12, fontSize - 4)))
                            .foregroundStyle(AppTheme.textSecond)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.purple.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
            .stroke(Color.purple.opacity(0.2), lineWidth: 0.5))
    }

    // MARK: Answer Flip Card

    private func answerCard(q: InterviewQuestion) -> some View {
        ZStack {
            lockedFace
                .rotation3DEffect(.degrees(showAnswer ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .opacity(showAnswer ? 0 : 1)

            answerFace(q: q)
                .rotation3DEffect(.degrees(showAnswer ? 0 : -180), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .opacity(showAnswer ? 1 : 0)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                showAnswer.toggle()
            }
        }
    }

    private var lockedFace: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(AppTheme.textDisabled)
                Text("SAMPLE ANSWER")
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(AppTheme.textDisabled).tracking(1)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap.fill").font(.system(size: 11))
                    Text("Tap to flip").font(.system(size: 11))
                }
                .foregroundStyle(AppTheme.textDisabled)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(AppTheme.bgElevated)

            Rectangle().fill(AppTheme.bgBorder).frame(height: 0.5)

            VStack(spacing: 10) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 28)).foregroundStyle(AppTheme.textDisabled)
                Text("Tap to reveal a sample answer")
                    .font(.system(size: 14)).foregroundStyle(AppTheme.textDisabled)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
        }
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLg).stroke(AppTheme.bgBorder, lineWidth: 0.5))
    }

    private func answerFace(q: InterviewQuestion) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 11)).foregroundStyle(AppTheme.success)
                Text("SAMPLE ANSWER")
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(AppTheme.success).tracking(1)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap.fill").font(.system(size: 11))
                    Text("Tap to flip back").font(.system(size: 11))
                }
                .foregroundStyle(AppTheme.textDisabled)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(AppTheme.success.opacity(0.08))

            Rectangle().fill(AppTheme.success.opacity(0.15)).frame(height: 0.5)

            Text(q.suggestedAnswer.isEmpty
                 ? "Think of a specific project from your experience. Describe what you built, the technologies used, the challenges you faced, and the outcome you delivered. Keep it to 2-3 minutes."
                 : q.suggestedAnswer)
                .font(.system(size: max(13, fontSize - 2)))
                .foregroundStyle(AppTheme.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
        }
        .background(AppTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLg).stroke(AppTheme.success.opacity(0.3), lineWidth: 0.5))
    }

    // MARK: Helpers

    private func tipText(for q: InterviewQuestion) -> String {
        switch q.category {
        case "behavioral":
            return "Use a specific real example. Lead with the outcome — what did you achieve? Keep to 2 minutes max."
        case "technical":
            return "Name the exact tools, frameworks or patterns you used. Show your decision-making process, not just the result."
        case "situational":
            return "Be concrete about what YOU specifically did. Avoid 'we' — focus on your individual contribution and the result."
        case "live_coding":
            return "Read the problem twice before writing anything. Ask one clarifying question. Talk through your approach first."
        default:
            return "Be specific, stay concise, and tie your answer directly back to this role."
        }
    }

    // MARK: Bottom Navigation

    private var bottomNav: some View {
        HStack(spacing: 12) {
            Button(action: { prev() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(currentIndex > 0 ? AppTheme.textPrimary : AppTheme.textDisabled)
                    .frame(width: 52, height: 52)
                    .background(currentIndex > 0 ? AppTheme.bgCard : AppTheme.bgElevated)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.bgBorder, lineWidth: 0.5))
            }
            .buttonStyle(.plain).disabled(currentIndex == 0)

            Button(action: { next() }) {
                HStack(spacing: 8) {
                    if currentIndex < questions.count - 1 {
                        Text("Next Question").font(.system(size: 15, weight: .semibold))
                        Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold))
                    } else {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 16))
                        Text("Finish").font(.system(size: 15, weight: .semibold))
                    }
                }
                .foregroundStyle(AppTheme.buttonFg)
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(currentIndex < questions.count - 1 ? AppTheme.gold : AppTheme.success)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            }
            .buttonStyle(.plain)

            Button(action: { skipForward() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(currentIndex < questions.count - 1 ? AppTheme.textPrimary : AppTheme.textDisabled)
                    .frame(width: 52, height: 52)
                    .background(currentIndex < questions.count - 1 ? AppTheme.bgCard : AppTheme.bgElevated)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.bgBorder, lineWidth: 0.5))
            }
            .buttonStyle(.plain).disabled(currentIndex >= questions.count - 1)
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 36)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Rectangle().fill(AppTheme.bgBorder).frame(height: 0.5) }
    }

    // MARK: Navigation

    private func next() {
        if currentIndex < questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) { showAnswer = false; currentIndex += 1 }
        } else { dismiss() }
    }

    private func prev() {
        guard currentIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) { showAnswer = false; currentIndex -= 1 }
    }

    private func skipForward() {
        guard currentIndex < questions.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) { showAnswer = false; currentIndex += 1 }
    }

    // MARK: Load — cache aware, version aware

    private func load() async {
        // Valid cache: must have promptVersion == 2, 15+ questions,
        // and first answer must NOT contain STAR coaching language
        if let existing = application.interviewSessions?
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first(where: { isValidSession($0) }) {
            withAnimation {
                self.questions = existing.questions.sorted { $0.order < $1.order }
                self.isLoading = false
            }
            return
        }

        // Generate fresh questions
        isLoading = true; error = nil; currentIndex = 0; showAnswer = false
        let cvContent = application.document?.displayCV ?? ""
        do {
            let qs = try await AIService.shared.generateInterviewQuestions(
                jobDescription: application.jobDescription,
                cvContent: cvContent,
                count: 20
            )
            let session = InterviewSession(jobTitle: application.jobTitle, company: application.company)
            session.questions = qs
            session.promptVersion = currentPromptVersion
            modelContext.insert(session)
            if application.interviewSessions == nil { application.interviewSessions = [] }
            application.interviewSessions?.append(session)
            try? modelContext.save()
            withAnimation { self.questions = qs; self.isLoading = false }
        } catch {
            self.error = error.localizedDescription; self.isLoading = false
        }
    }

    /// Returns true only if the session has real answers (not STAR coaching) and enough questions
    private func isValidSession(_ session: InterviewSession) -> Bool {
        guard session.questions.count >= 15 else { return false }
        let firstAnswer = session.questions.first?.suggestedAnswer ?? ""
        // Reject if answer looks like meta-coaching rather than a real spoken answer
        let starKeywords = ["Use STAR", "STAR method", "Describe the", "Situation, Task", "coaching"]
        for keyword in starKeywords {
            if firstAnswer.contains(keyword) { return false }
        }
        // Reject if answer is very short (real answers are 3-5 sentences)
        return firstAnswer.count > 100
    }
}
