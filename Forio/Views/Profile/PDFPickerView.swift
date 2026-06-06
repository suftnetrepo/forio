import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct PDFPickerView: UIViewControllerRepresentable {
    var onTextExtracted: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTextExtracted: onTextExtracted)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .plainText])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onTextExtracted: (String) -> Void

        init(onTextExtracted: @escaping (String) -> Void) {
            self.onTextExtracted = onTextExtracted
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            // Start security-scoped access
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            if url.pathExtension.lowercased() == "pdf" {
                extractTextFromPDF(url)
            } else {
                // Plain text file
                if let text = try? String(contentsOf: url, encoding: .utf8) {
                    DispatchQueue.main.async { self.onTextExtracted(text) }
                }
            }
        }

        private func extractTextFromPDF(_ url: URL) {
            guard let pdf = PDFDocument(url: url) else { return }
            var fullText = ""
            for i in 0..<pdf.pageCount {
                if let page = pdf.page(at: i) {
                    fullText += page.string ?? ""
                    fullText += "\n"
                }
            }
            let trimmed = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
            DispatchQueue.main.async {
                self.onTextExtracted(trimmed.isEmpty ? "" : trimmed)
            }
        }
    }
}
