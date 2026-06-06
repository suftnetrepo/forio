import SwiftUI

struct SkillChipView: View {
    let skill: String
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            Text(skill)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? AppTheme.gold : AppTheme.textSecond)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.goldFaint : AppTheme.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? AppTheme.goldBorder : AppTheme.bgBorder,
                            lineWidth: 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preset skills by persona

enum PresetSkills {
    static let graduate: [String] = [
        "Microsoft Word", "Excel", "PowerPoint", "Teamwork",
        "Communication", "Research", "Problem solving", "Time management",
        "Public speaking", "Python", "Data analysis", "Writing",
        "Social media", "Customer service", "Organisation"
    ]

    static let experienced: [String] = [
        "Leadership", "Project management", "Stakeholder management",
        "Budgeting", "Strategy", "Mentoring", "Agile", "Scrum",
        "Data analysis", "Presentation", "Negotiation", "CRM",
        "P&L management", "Change management", "Team building"
    ]

    static let tech: [String] = [
        "Swift", "SwiftUI", "Python", "JavaScript", "TypeScript",
        "React", "Node.js", "SQL", "Git", "CI/CD",
        "REST APIs", "AWS", "Docker", "Figma", "Agile"
    ]

    static func skills(for persona: UserPersona) -> [String] {
        switch persona {
        case .graduate:                return graduate
        case .experienced, .returning: return experienced
        case .careerChanger:           return experienced + tech
        }
    }
}
