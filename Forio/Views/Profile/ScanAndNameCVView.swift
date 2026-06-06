import SwiftUI
import SwiftData
import VisionKit

struct ScanAndNameCVView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var onSaved: (CVProfile) -> Void

    @State private var step: Step = .scan
    @State private var showScanner = false
    @State private var showDocPicker = false
    @State private var showPasteSheet = false
    @State private var isExtracting = false
    @State private var extractedProfile: ExtractedProfile?
    @State private var cvName = ""
    @State private var selectedPersona: UserPersona = .experienced
    @State private var errorMessage: String?
    @State private var showError = false

    enum Step { case scan, name }

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea(.all)

            switch step {
            case .scan: scanStep
            case .name: nameStep
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerView { result in
                showScanner = false
                guard case .success(let scan) = result else { return }
                let images = (0..<min(scan.pageCount, 10)).map { scan.imageOfPage(at: $0) }
                // Wait for scanner cover to fully dismiss before extracting
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    extractFromImages(images)
                }
            }
        }
        .sheet(isPresented: $showDocPicker) {
            PDFPickerView { text in extractFromText(text) }
        }
        .sheet(isPresented: $showPasteSheet) {
            PasteTextView { text in extractFromText(text) }
        }
        .alert("Extraction failed", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "Please try again")
        }
    }

    // MARK: - Scan step

    private var scanStep: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Spacer()
                Text("Import a CV")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Color.clear.frame(width: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)

            if isExtracting {
                extractingView
            } else {
                Spacer()

                VStack(spacing: 10) {
                    importCard(icon: "camera.fill",
                               title: "Scan CV pages",
                               subtitle: "Point camera at any CV",
                               isFeatured: true) { showScanner = true }

                    importCard(icon: "doc.fill",
                               title: "Upload PDF",
                               subtitle: "Pick from Files or iCloud",
                               isFeatured: false) { showDocPicker = true }

                    importCard(icon: "doc.on.clipboard.fill",
                               title: "Paste CV text",
                               subtitle: "Copy and paste text",
                               isFeatured: false) { showPasteSheet = true }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .safeAreaPadding(.top)
    }

    private var extractingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.goldFaint).frame(width: 80, height: 80)
                ProgressView().tint(AppTheme.gold).scaleEffect(1.5)
            }
            Text("Reading CV…")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
            Text("AI is extracting your profile")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textMuted)
            Spacer()
        }
    }

    // MARK: - Name step

    private var nameStep: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { step = .scan }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(AppTheme.textMuted)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Spacer()
                Text("Name your CV")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Color.clear.frame(width: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Success banner
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.success)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CV read successfully")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppTheme.success)
                            if let p = extractedProfile {
                                Text("\(p.experience.count) roles · \(p.skills.count) skills extracted")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.textMuted)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.successFaint)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .stroke(AppTheme.success.opacity(0.3), lineWidth: 0.5))

                    // CV name field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("GIVE THIS CV A NAME")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                            .kerning(0.5)
                        TextField("e.g. React CV, .NET CV, Mobile CV", text: $cvName)
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(14)
                            .background(AppTheme.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                                .stroke(cvName.isEmpty ? AppTheme.bgBorder : AppTheme.goldBorder,
                                        lineWidth: 0.5))
                    }

                    // Quick name suggestions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("QUICK NAMES")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                            .kerning(0.5)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["React CV", ".NET CV", "Mobile CV", "Full Stack CV",
                                         "Senior Dev CV", "Contractor CV"], id: \.self) { name in
                                    Button(action: { cvName = name }) {
                                        Text(name)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(cvName == name ? AppTheme.gold : AppTheme.textMuted)
                                            .padding(.horizontal, 12).padding(.vertical, 6)
                                            .background(cvName == name ? AppTheme.goldFaint : AppTheme.bgCard)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .overlay(RoundedRectangle(cornerRadius: 20)
                                                .stroke(cvName == name ? AppTheme.goldBorder : AppTheme.bgBorder,
                                                        lineWidth: 0.5))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Persona
                    VStack(alignment: .leading, spacing: 8) {
                        Text("THIS CV IS FOR")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)
                            .kerning(0.5)
                        HStack(spacing: 8) {
                            ForEach(UserPersona.allCases, id: \.self) { persona in
                                Button(action: { selectedPersona = persona }) {
                                    VStack(spacing: 4) {
                                        Text(persona.emoji).font(.system(size: 18))
                                        Text(persona.displayName.components(separatedBy: " ").first ?? "")
                                            .font(.system(size: 9))
                                            .foregroundStyle(selectedPersona == persona
                                                             ? AppTheme.gold : AppTheme.textMuted)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedPersona == persona ? AppTheme.goldFaint : AppTheme.bgCard)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                                    .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                                        .stroke(selectedPersona == persona ? AppTheme.goldBorder : AppTheme.bgBorder,
                                                lineWidth: selectedPersona == persona ? 1 : 0.5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }

            // Save button
            Button(action: { saveCVProfile() }) {
                Text("Save this CV →")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "0A0A0F"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(cvName.isEmpty ? AppTheme.gold.opacity(0.4) : AppTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            }
            .disabled(cvName.isEmpty)
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
            .padding(.top, 12)
        }
        .safeAreaPadding(.top)
    }

    // MARK: - Import card

    private func importCard(icon: String, title: String, subtitle: String,
                             isFeatured: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(isFeatured ? AppTheme.gold.opacity(0.2) : AppTheme.bgElevated)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 18))
                        .foregroundStyle(isFeatured ? AppTheme.gold : AppTheme.textSecond)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isFeatured ? AppTheme.gold : AppTheme.textPrimary)
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(AppTheme.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12))
                    .foregroundStyle(isFeatured ? AppTheme.gold : AppTheme.textMuted)
            }
            .padding(16)
            .background(isFeatured ? AppTheme.goldFaint : AppTheme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(isFeatured ? AppTheme.goldBorder : AppTheme.bgBorder,
                        lineWidth: isFeatured ? 1 : 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Extract

    private func extractFromImages(_ images: [UIImage]) {
        isExtracting = true
        Task { @MainActor in
            do {
                extractedProfile = try await AIService.shared.extractProfile(from: images)
                cvName = suggestName(from: extractedProfile)
                step = .name
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isExtracting = false
        }
    }

    private func extractFromText(_ text: String) {
        isExtracting = true
        Task { @MainActor in
            do {
                extractedProfile = try await AIService.shared.extractProfile(from: text)
                cvName = suggestName(from: extractedProfile)
                step = .name
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isExtracting = false
        }
    }

    private func suggestName(from profile: ExtractedProfile?) -> String {
        guard let p = profile else { return "" }
        // Auto-suggest based on top skills
        let skills = p.skills.map { $0.lowercased() }
        if skills.contains(where: { $0.contains(".net") || $0.contains("c#") }) { return ".NET CV" }
        if skills.contains(where: { $0.contains("react native") || $0.contains("ios") || $0.contains("swift") }) { return "Mobile CV" }
        if skills.contains(where: { $0.contains("react") || $0.contains("vue") || $0.contains("angular") }) { return "React CV" }
        if skills.contains(where: { $0.contains("node") || $0.contains("python") || $0.contains("java") }) { return "Full Stack CV" }
        return "My CV"
    }

    // MARK: - Save

    private func saveCVProfile() {
        guard let extracted = extractedProfile else { return }
        let profile = CVProfile.from(extracted: extracted, name: cvName, persona: selectedPersona)
        modelContext.insert(profile)
        try? modelContext.save()
        onSaved(profile)
        dismiss()
    }
}
