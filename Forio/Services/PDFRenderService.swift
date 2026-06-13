import UIKit
import PDFKit

enum PDFRenderService {

    static func render(content: String, template: CVTemplate,
                       jobTitle: String, company: String) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            drawDocument(in: ctx, content: content, pageRect: pageRect,
                         style: templateStyle(for: template))
        }
    }

    // MARK: - Draw

    private static func drawDocument(in ctx: UIGraphicsPDFRendererContext,
                                      content: String, pageRect: CGRect, style: PDFStyle) {
        let margin: CGFloat = 50
        let contentWidth = pageRect.width - (margin * 2)
        var y: CGFloat = 0

        // Header band
        style.headerColor.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: pageRect.width, height: 70))
        if let accent = style.accentColor {
            accent.setFill()
            UIRectFill(CGRect(x: 0, y: 70, width: pageRect.width, height: 3))
        }

        y = 88
        let sections = parseContent(content)

        for section in sections {
            if y > pageRect.height - margin - 20 {
                ctx.beginPage()
                y = margin
            }

            switch section.type {

            case .name:
                // Large name in header band
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                    .foregroundColor: style.nameColor
                ]
                let str = NSAttributedString(string: section.text, attributes: attrs)
                str.draw(at: CGPoint(x: margin, y: 14))

            case .tagline:
                // Subtitle under name
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                    .foregroundColor: style.nameColor.withAlphaComponent(0.8)
                ]
                NSAttributedString(string: section.text, attributes: attrs)
                    .draw(at: CGPoint(x: margin, y: 38))

            case .contact:
                // Contact line under tagline
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9),
                    .foregroundColor: style.nameColor.withAlphaComponent(0.7)
                ]
                NSAttributedString(string: section.text, attributes: attrs)
                    .draw(at: CGPoint(x: margin, y: 54))

            case .heading:
                // ── PROMINENT SECTION HEADER ──
                y += 10
                // Ensure heading doesn't get orphaned — need room for heading + 2 lines after
                if y + 50 > pageRect.height - margin {
                    ctx.beginPage(); y = margin + 10
                }

                // Coloured background band for heading
                let headingBg = style.headingColor.withAlphaComponent(0.08)
                headingBg.setFill()
                UIRectFill(CGRect(x: margin - 4, y: y - 2, width: contentWidth + 8, height: 18))

                // Left accent bar
                style.headingColor.setFill()
                UIRectFill(CGRect(x: margin - 4, y: y - 2, width: 3, height: 18))

                // Heading text — bold, coloured, larger
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10.5, weight: .bold),
                    .foregroundColor: style.headingColor,
                    .kern: 0.8
                ]
                NSAttributedString(string: section.text.uppercased(), attributes: attrs)
                    .draw(at: CGPoint(x: margin + 4, y: y))
                y += 20

            case .subheading:
                y += 4
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                    .foregroundColor: style.bodyColor
                ]
                let str = NSAttributedString(string: section.text, attributes: attrs)
                let bounds = str.boundingRect(
                    with: CGSize(width: contentWidth, height: 200),
                    options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                // Keep at least 60pt after subheading to avoid orphan headers at bottom of page
                if y + bounds.height + 60 > pageRect.height - margin {
                    ctx.beginPage(); y = margin
                }
                str.draw(with: CGRect(x: margin, y: y, width: contentWidth, height: 200),
                         options: [.usesLineFragmentOrigin], context: nil)
                y += bounds.height + 4

            case .meta:
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 9.5),
                    .foregroundColor: style.metaColor
                ]
                let str = NSAttributedString(string: section.text, attributes: attrs)
                let bounds = str.boundingRect(
                    with: CGSize(width: contentWidth, height: 200),
                    options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                str.draw(with: CGRect(x: margin, y: y, width: contentWidth, height: 200),
                         options: [.usesLineFragmentOrigin], context: nil)
                y += bounds.height + 3

            case .body:
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                    .foregroundColor: style.bodyColor
                ]
                let str = NSAttributedString(string: section.text, attributes: attrs)
                let bounds = str.boundingRect(
                    with: CGSize(width: contentWidth, height: 1000),
                    options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                let neededHeight = bounds.height + 4
                if y + neededHeight > pageRect.height - margin {
                    ctx.beginPage(); y = margin
                }
                str.draw(with: CGRect(x: margin, y: y, width: contentWidth, height: neededHeight + 20),
                         options: [.usesLineFragmentOrigin], context: nil)
                y += neededHeight

            case .bullet:
                let bulletText = "•  " + section.text
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: style.bodyColor
                ]
                let str = NSAttributedString(string: bulletText, attributes: attrs)
                let bounds = str.boundingRect(
                    with: CGSize(width: contentWidth - 12, height: 1000),
                    options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                let neededHeight = bounds.height + 3
                if y + neededHeight > pageRect.height - margin {
                    ctx.beginPage(); y = margin
                }
                str.draw(with: CGRect(x: margin + 8, y: y, width: contentWidth - 12, height: neededHeight + 20),
                         options: [.usesLineFragmentOrigin], context: nil)
                y += neededHeight

            case .spacer:
                y += 6
            }
        }
    }

    // MARK: - Parser
    // Detects both markdown (##) and plain ALL-CAPS section headers

    private static let knownHeaders: Set<String> = [
        "PROFESSIONAL SUMMARY", "SUMMARY", "EXPERIENCE", "WORK EXPERIENCE",
        "PROFESSIONAL EXPERIENCE", "EDUCATION", "SKILLS", "CORE SKILLS",
        "CORE TECHNICAL SKILLS", "TECHNICAL SKILLS", "CERTIFICATIONS",
        "PROJECTS", "SELECTED PROJECT IMPACT", "ADDITIONAL INFORMATION",
        "ACHIEVEMENTS", "REFERENCES", "LANGUAGES", "INTERESTS",
        "KEY ACHIEVEMENTS", "PROFILE", "OBJECTIVE"
    ]

    private static func isAllCapsHeader(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 4, trimmed.count <= 60 else { return false }
        let upper = trimmed.uppercased()
        guard upper == trimmed else { return false }
        // Must contain mostly letters
        let letters = trimmed.filter { $0.isLetter }
        return letters.count >= 3
    }

    private static func parseContent(_ raw: String) -> [ContentSection] {
        var sections: [ContentSection] = []
        let lines = raw.components(separatedBy: "\n")
        var nameSet = false
        var taglineSet = false
        var contactSet = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                sections.append(ContentSection(type: .spacer, text: ""))
                continue
            }

            // Markdown headings
            if trimmed.hasPrefix("# ") {
                sections.append(ContentSection(type: .name, text: String(trimmed.dropFirst(2))))
                nameSet = true
            } else if trimmed.hasPrefix("## ") {
                sections.append(ContentSection(type: .heading, text: String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("### ") {
                sections.append(ContentSection(type: .subheading, text: String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") || trimmed.hasPrefix("· ") {
                let text = String(trimmed.dropFirst(2))
                sections.append(ContentSection(type: .bullet, text: text))
            } else if trimmed.hasPrefix("* ") && trimmed.hasSuffix(" *") {
                sections.append(ContentSection(type: .meta, text: String(trimmed.dropFirst(2).dropLast(2))))

            // First non-heading line = name (check BEFORE all-caps so "ABEL AGHORIGHOR" → name not heading)
            } else if !nameSet {
                sections.append(ContentSection(type: .name, text: trimmed))
                nameSet = true

            // Second line = tagline
            } else if nameSet && !taglineSet && !trimmed.contains("@") && !trimmed.contains("|") {
                sections.append(ContentSection(type: .tagline, text: trimmed))
                taglineSet = true

            // Third line = contact
            } else if !contactSet &&
                      (trimmed.contains("@") || (trimmed.contains("|") && trimmed.contains("+"))) {
                sections.append(ContentSection(type: .contact, text: trimmed))
                contactSet = true

            // Plain ALL-CAPS section headers
            } else if isAllCapsHeader(trimmed) {
                sections.append(ContentSection(type: .heading, text: trimmed))

            // Lines ending with dates pattern = subheading (job title line)
            } else if trimmed.contains(" | ") && (trimmed.contains("–") || trimmed.contains("-") || trimmed.contains("Present")) {
                sections.append(ContentSection(type: .subheading, text: trimmed))

            } else {
                sections.append(ContentSection(type: .body, text: trimmed))
            }
        }
        return sections
    }

    // MARK: - Template styles

    private static func templateStyle(for template: CVTemplate) -> PDFStyle {
        switch template {
        case .classicNavy:
            return PDFStyle(
                headerColor:  UIColor(red: 0.10, green: 0.10, blue: 0.20, alpha: 1),
                accentColor:  UIColor(red: 0.79, green: 0.66, blue: 0.30, alpha: 1),
                nameColor:    .white,
                headingColor: UIColor(red: 0.10, green: 0.10, blue: 0.22, alpha: 1),
                bodyColor:    UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1),
                metaColor:    UIColor(red: 0.79, green: 0.66, blue: 0.30, alpha: 1)
            )
        case .cleanMinimal:
            return PDFStyle(
                headerColor:  UIColor(red: 0.97, green: 0.97, blue: 0.96, alpha: 1),
                accentColor:  UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1),
                nameColor:    UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1),
                headingColor: UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1),
                bodyColor:    UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1),
                metaColor:    UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
            )
        case .boldTwoColumn:
            return PDFStyle(
                headerColor:  UIColor(red: 0.05, green: 0.23, blue: 0.18, alpha: 1),
                accentColor:  UIColor(red: 0.79, green: 0.66, blue: 0.30, alpha: 1),
                nameColor:    .white,
                headingColor: UIColor(red: 0.05, green: 0.23, blue: 0.18, alpha: 1),
                bodyColor:    UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1),
                metaColor:    UIColor(red: 0.05, green: 0.53, blue: 0.40, alpha: 1)
            )
        case .executiveGold:
            return PDFStyle(
                headerColor:  UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1),
                accentColor:  UIColor(red: 0.79, green: 0.66, blue: 0.30, alpha: 1),
                nameColor:    UIColor(red: 0.10, green: 0.07, blue: 0.00, alpha: 1),
                headingColor: UIColor(red: 0.60, green: 0.48, blue: 0.20, alpha: 1),
                bodyColor:    UIColor(red: 0.15, green: 0.12, blue: 0.05, alpha: 1),
                metaColor:    UIColor(red: 0.50, green: 0.42, blue: 0.20, alpha: 1)
            )
        case .freshStart:
            return PDFStyle(
                headerColor:  UIColor(red: 0.20, green: 0.33, blue: 0.90, alpha: 1),
                accentColor:  UIColor(red: 1.0,  green: 1.0,  blue: 1.0,  alpha: 0.3),
                nameColor:    .white,
                headingColor: UIColor(red: 0.20, green: 0.33, blue: 0.90, alpha: 1),
                bodyColor:    UIColor(red: 0.12, green: 0.12, blue: 0.22, alpha: 1),
                metaColor:    UIColor(red: 0.29, green: 0.42, blue: 0.97, alpha: 1)
            )
        }
    }
}

// MARK: - Supporting types

struct PDFStyle {
    let headerColor:  UIColor
    let accentColor:  UIColor?
    let nameColor:    UIColor
    let headingColor: UIColor
    let bodyColor:    UIColor
    let metaColor:    UIColor
}

enum ContentSectionType {
    case name, tagline, contact, heading, subheading, meta, body, bullet, spacer
}

struct ContentSection {
    let type: ContentSectionType
    let text: String
}
