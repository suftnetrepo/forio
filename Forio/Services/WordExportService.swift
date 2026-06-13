import Foundation
import UIKit

// MARK: - Word Export Service
// Generates a .doc file (HTML-based, opens in Word/Pages perfectly)

enum WordExportService {

    static func export(
        cvContent: String,
        coverLetter: String,
        jobTitle: String,
        company: String,
        exportType: ExportType
    ) -> URL? {
        let content = exportType == .cv ? cvContent : coverLetter
        let filename = exportType == .cv
            ? "CV_\(company.replacingOccurrences(of: " ", with: "_")).doc"
            : "CoverLetter_\(company.replacingOccurrences(of: " ", with: "_")).doc"

        let html = buildHTML(content: content, exportType: exportType)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try html.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("❌ Word export error: \(error)")
            return nil
        }
    }

    enum ExportType { case cv, coverLetter }

    // MARK: - HTML → Word

    private static func buildHTML(content: String, exportType: ExportType) -> String {
        let body = convertToHTML(content)

        return """
        <html xmlns:o='urn:schemas-microsoft-com:office:office'
              xmlns:w='urn:schemas-microsoft-com:office:word'
              xmlns='http://www.w3.org/TR/REC-html40'>
        <head>
        <meta charset="utf-8">
        <style>
            body {
                font-family: Arial, sans-serif;
                font-size: 10.5pt;
                color: #1a1a1a;
                margin: 2cm 2.5cm;
                line-height: 1.4;
            }
            h1 {
                font-size: 18pt;
                font-weight: bold;
                color: #1a1a1a;
                margin: 0 0 2pt 0;
                border-bottom: none;
            }
            .tagline {
                font-size: 11pt;
                color: #444;
                margin: 0 0 2pt 0;
            }
            .contact {
                font-size: 9.5pt;
                color: #666;
                margin: 0 0 14pt 0;
                border-bottom: 2pt solid #1a1a1a;
                padding-bottom: 8pt;
            }
            h2 {
                font-size: 10pt;
                font-weight: bold;
                color: #1a1a2e;
                text-transform: uppercase;
                letter-spacing: 0.8pt;
                background-color: #f0f0f4;
                padding: 4pt 6pt;
                margin: 14pt 0 6pt 0;
                border-left: 3pt solid #1a1a2e;
            }
            h3 {
                font-size: 10.5pt;
                font-weight: bold;
                color: #1a1a1a;
                margin: 8pt 0 3pt 0;
            }
            p {
                margin: 3pt 0;
                font-size: 10pt;
            }
            ul {
                margin: 4pt 0 4pt 0;
                padding-left: 18pt;
            }
            li {
                font-size: 10pt;
                margin: 2pt 0;
            }
            .tech {
                font-style: italic;
                color: #555;
                font-size: 9.5pt;
                margin-top: 3pt;
            }
        </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    // MARK: - Convert CV text to HTML

    private static func convertToHTML(_ raw: String) -> String {
        var html = ""
        let lines = raw.components(separatedBy: "\n")
        var inList = false
        var nameSet = false
        var taglineSet = false
        var contactSet = false

        func closeList() {
            if inList { html += "</ul>\n"; inList = false }
        }

        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty {
                closeList()
                html += "<br>\n"
                continue
            }

            // Markdown headings
            if t.hasPrefix("# ") {
                closeList()
                html += "<h1>\(escape(String(t.dropFirst(2))))</h1>\n"
                nameSet = true
            } else if t.hasPrefix("## ") {
                closeList()
                html += "<h2>\(escape(String(t.dropFirst(3))))</h2>\n"
            } else if t.hasPrefix("### ") {
                closeList()
                html += "<h3>\(escape(String(t.dropFirst(4))))</h3>\n"
            } else if t.hasPrefix("- ") || t.hasPrefix("• ") {
                if !inList { html += "<ul>\n"; inList = true }
                html += "<li>\(escape(String(t.dropFirst(2))))</li>\n"

            // First lines — name, tagline, contact (check BEFORE all-caps header)
            } else if !nameSet {
                html += "<h1>\(escape(t))</h1>\n"; nameSet = true
            } else if !taglineSet && !t.contains("@") && !t.contains("|") {
                html += "<p class='tagline'>\(escape(t))</p>\n"; taglineSet = true
            } else if !contactSet && (t.contains("@") || (t.contains("|") && (t.contains("+") || t.contains("."))) ) {
                closeList()
                html += "<p class='contact'>\(escape(t))</p>\n"; contactSet = true

            // ALL CAPS section header
            } else if isAllCaps(t) {
                closeList()
                html += "<h2>\(escape(t))</h2>\n"

            // Job title line with dates
            } else if t.contains(" | ") && (t.contains("–") || t.contains("-") || t.contains("Present")) {
                closeList()
                html += "<h3>\(escape(t))</h3>\n"

            // Tech line
            } else if t.lowercased().hasPrefix("technology:") {
                closeList()
                html += "<p class='tech'>\(escape(t))</p>\n"

            } else {
                closeList()
                html += "<p>\(escape(t))</p>\n"
            }
        }
        closeList()
        return html
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func isAllCaps(_ text: String) -> Bool {
        guard text.count >= 4, text.count <= 60 else { return false }
        let upper = text.uppercased()
        guard upper == text else { return false }
        return text.filter({ $0.isLetter }).count >= 3
    }
}
