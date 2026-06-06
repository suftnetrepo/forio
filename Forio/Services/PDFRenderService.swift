import UIKit
import PDFKit

// MARK: - PDF Render Service

enum PDFRenderService {

    static func render(
        content: String,
        template: CVTemplate,
        jobTitle: String,
        company: String
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 points
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let style = templateStyle(for: template)
            drawDocument(
                in: ctx,
                content: content,
                pageRect: pageRect,
                style: style,
                jobTitle: jobTitle,
                company: company
            )
        }
        return data
    }

    // MARK: - Draw

    private static func drawDocument(
        in ctx: UIGraphicsPDFRendererContext,
        content: String,
        pageRect: CGRect,
        style: PDFStyle,
        jobTitle: String,
        company: String
    ) {
        let margin: CGFloat = 48
        let contentWidth = pageRect.width - (margin * 2)
        var yPosition: CGFloat = margin

        // Header band
        let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 72)
        style.headerColor.setFill()
        UIRectFill(headerRect)

        // Accent line
        if let accent = style.accentColor {
            accent.setFill()
            UIRectFill(CGRect(x: 0, y: 72, width: pageRect.width, height: 3))
        }

        yPosition = 80 + 16

        // Parse and render content sections
        let sections = parseContent(content)

        for section in sections {
            // Check if we need a new page
            if yPosition > pageRect.height - margin - 60 {
                ctx.beginPage()
                yPosition = margin
            }

            switch section.type {
            case .name:
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22, weight: .medium),
                    .foregroundColor: style.nameColor
                ]
                let str = NSAttributedString(string: section.text, attributes: attrs)
                str.draw(at: CGPoint(x: margin, y: 16))

            case .heading:
                yPosition += 8
                // Heading rule
                style.headingColor.setFill()
                UIRectFill(CGRect(x: margin, y: yPosition, width: contentWidth, height: 1))
                yPosition += 5

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                    .foregroundColor: style.headingColor,
                    .kern: 1.0
                ]
                let str = NSAttributedString(string: section.text.uppercased(), attributes: attrs)
                str.draw(at: CGPoint(x: margin, y: yPosition))
                yPosition += 18

            case .subheading:
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                    .foregroundColor: style.bodyColor
                ]
                let str = NSAttributedString(string: section.text, attributes: attrs)
                str.draw(at: CGPoint(x: margin, y: yPosition))
                yPosition += 16

            case .meta:
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 10),
                    .foregroundColor: style.metaColor
                ]
                let str = NSAttributedString(string: section.text, attributes: attrs)
                str.draw(at: CGPoint(x: margin, y: yPosition))
                yPosition += 14

            case .body:
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                    .foregroundColor: style.bodyColor
                ]
                let attrStr = NSAttributedString(string: section.text, attributes: attrs)
                let textBounds = CGRect(x: margin, y: yPosition,
                                        width: contentWidth, height: pageRect.height)
                let drawn = attrStr.boundingRect(with: textBounds.size,
                                                  options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                  context: nil)
                attrStr.draw(with: textBounds, options: [.usesLineFragmentOrigin], context: nil)
                yPosition += drawn.height + 4

            case .bullet:
                let bullet = "•  " + section.text
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: style.bodyColor
                ]
                let attrStr = NSAttributedString(string: bullet, attributes: attrs)
                let textBounds = CGRect(x: margin + 8, y: yPosition,
                                        width: contentWidth - 8, height: pageRect.height)
                let drawn = attrStr.boundingRect(with: textBounds.size,
                                                  options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                  context: nil)
                attrStr.draw(with: textBounds, options: [.usesLineFragmentOrigin], context: nil)
                yPosition += drawn.height + 3

            case .spacer:
                yPosition += 8
            }
        }
    }

    // MARK: - Content parser

    private static func parseContent(_ raw: String) -> [ContentSection] {
        var sections: [ContentSection] = []
        let lines = raw.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                sections.append(ContentSection(type: .spacer, text: ""))
            } else if trimmed.hasPrefix("# ") {
                sections.append(ContentSection(type: .name, text: String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("## ") {
                sections.append(ContentSection(type: .heading, text: String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("### ") {
                sections.append(ContentSection(type: .subheading, text: String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("*") && trimmed.hasSuffix("*") {
                let inner = trimmed.dropFirst().dropLast()
                sections.append(ContentSection(type: .meta, text: String(inner)))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") {
                let text = trimmed.hasPrefix("- ") ? String(trimmed.dropFirst(2)) : String(trimmed.dropFirst(2))
                sections.append(ContentSection(type: .bullet, text: text))
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
                headerColor:  UIColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1),
                accentColor:  UIColor(red: 0.79, green: 0.66, blue: 0.30, alpha: 1),
                nameColor:    .white,
                headingColor: UIColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1),
                bodyColor:    UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1),
                metaColor:    UIColor(red: 0.79, green: 0.66, blue: 0.30, alpha: 1)
            )
        case .cleanMinimal:
            return PDFStyle(
                headerColor:  UIColor(red: 0.97, green: 0.97, blue: 0.96, alpha: 1),
                accentColor:  UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1),
                nameColor:    UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1),
                headingColor: UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1),
                bodyColor:    UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1),
                metaColor:    UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 1)
            )
        case .boldTwoColumn:
            return PDFStyle(
                headerColor:  UIColor(red: 0.05, green: 0.23, blue: 0.18, alpha: 1),
                accentColor:  UIColor(red: 0.79, green: 0.66, blue: 0.30, alpha: 1),
                nameColor:    .white,
                headingColor: UIColor(red: 0.05, green: 0.23, blue: 0.18, alpha: 1),
                bodyColor:    UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1),
                metaColor:    UIColor(red: 0.30, green: 0.70, blue: 0.58, alpha: 1)
            )
        case .executiveGold:
            return PDFStyle(
                headerColor:  UIColor(red: 0.99, green: 0.99, blue: 0.97, alpha: 1),
                accentColor:  UIColor(red: 0.79, green: 0.66, blue: 0.30, alpha: 1),
                nameColor:    UIColor(red: 0.10, green: 0.07, blue: 0.00, alpha: 1),
                headingColor: UIColor(red: 0.48, green: 0.42, blue: 0.25, alpha: 1),
                bodyColor:    UIColor(red: 0.15, green: 0.12, blue: 0.05, alpha: 1),
                metaColor:    UIColor(red: 0.48, green: 0.42, blue: 0.25, alpha: 1)
            )
        case .freshStart:
            return PDFStyle(
                headerColor:  UIColor(red: 0.94, green: 0.96, blue: 1.00, alpha: 1),
                accentColor:  UIColor(red: 0.29, green: 0.42, blue: 0.97, alpha: 1),
                nameColor:    UIColor(red: 0.10, green: 0.10, blue: 0.24, alpha: 1),
                headingColor: UIColor(red: 0.29, green: 0.42, blue: 0.97, alpha: 1),
                bodyColor:    UIColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1),
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
    case name, heading, subheading, meta, body, bullet, spacer
}

struct ContentSection {
    let type: ContentSectionType
    let text: String
}
