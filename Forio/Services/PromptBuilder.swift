import Foundation

enum PromptBuilder {

    static func build(profile: UserProfile, jobDescription: String, template: CVTemplate) -> String {
        let personaInstruction = personaInstruction(for: profile)
        let profileSummary = buildProfileSummary(profile)

        return """
        You are an expert CV writer. Rewrite this candidate's CV tailored to the job below.

        \(personaInstruction)

        CANDIDATE PROFILE:
        \(profileSummary)

        JOB DESCRIPTION:
        \(jobDescription)

        TEMPLATE STYLE: \(template.displayName)

        TASK:
        Generate a tailored CV and cover letter for this specific job.

        Return ONLY a valid JSON object with this exact format, no markdown:
        {
          "cvContent": "Full CV text",
          "coverLetterContent": "Full cover letter text",
          "matchScore": 85,
          "matchedKeywords": ["keyword1", "keyword2"],
          "aiInsights": ["insight 1", "insight 2", "insight 3"]
        }

        CV rules:
        - Match the language and keywords from the job description exactly
        - Rewrite the Professional Summary to match this specific role and job title
        - Reorder Experience bullets so the most JD-relevant achievements come first
        - Put skills from the JD first in the Skills section
        - Use strong action verbs
        - Keep all dates exactly as given — never change them
        - Never invent facts — only reframe real experience
        - Keep CV to 1-2 pages worth of content
        - Cover letter: hook → 2-3 matching achievements → call to action
        - matchScore is 0-100 based on how well the profile matches the JD
        - matchedKeywords are keywords from the JD found in the profile
        - aiInsights are 3 specific notes about how the CV was tailored to this JD
        - Return only valid JSON, nothing else
        """
    }

    static func build(cvProfile: CVProfile, jobDescription: String, template: CVTemplate) -> String {
        var p = ""
        p += "Name: \(cvProfile.fullName)\n"
        if !cvProfile.email.isEmpty    { p += "Email: \(cvProfile.email)\n" }
        if !cvProfile.phone.isEmpty    { p += "Phone: \(cvProfile.phone)\n" }
        if !cvProfile.location.isEmpty { p += "Location: \(cvProfile.location)\n" }
        if !cvProfile.professionalSummary.isEmpty { p += "\nSummary:\n\(cvProfile.professionalSummary)\n" }
        if !cvProfile.experience.isEmpty {
            p += "\nExperience:\n"
            for job in cvProfile.experience {
                p += "• \(job.jobTitle) at \(job.company) (\(job.startDate) – \(job.endDate))\n"
                if !job.description.isEmpty { p += "  \(job.description)\n" }
            }
        }
        if !cvProfile.education.isEmpty {
            p += "\nEducation:\n"
            for edu in cvProfile.education {
                p += "• \(edu.degree) – \(edu.institution) (\(edu.graduationYear))\n"
            }
        }
        if !cvProfile.skills.isEmpty {
            p += "\nSkills: \(cvProfile.skills.joined(separator: ", "))\n"
        }

        return """
        You are an expert CV writer. Rewrite this CV tailored to the job below.

        CANDIDATE PROFILE:
        \(p)

        JOB DESCRIPTION:
        \(jobDescription)

        Return ONLY valid JSON:
        {
          "cvContent": "full CV",
          "coverLetterContent": "full cover letter",
          "matchScore": 85,
          "matchedKeywords": ["keyword1"],
          "aiInsights": ["note 1", "note 2", "note 3"]
        }
        """
    }

    // MARK: - Persona instructions

    private static func personaInstruction(for profile: UserProfile) -> String {
        switch profile.persona {
        case .graduate:
            return "PERSONA: Recent graduate. Lead with education and projects."
        case .experienced:
            return "PERSONA: Experienced professional. Lead with impact and achievements. Prioritise last 3-5 years."
        case .careerChanger:
            let from = profile.fromField.isEmpty ? "previous field" : profile.fromField
            let to   = profile.toField.isEmpty ? "target field" : profile.toField
            return "PERSONA: Career changer from \(from) to \(to). Reframe past experience as transferable skills."
        case .returning:
            let reason = profile.gapReason?.rawValue ?? "a career break"
            return "PERSONA: Returning to work after \(reason). Frame the gap positively."
        }
    }

    // MARK: - Profile to text

    private static func buildProfileSummary(_ profile: UserProfile) -> String {
        var lines: [String] = []
        lines.append("Name: \(profile.fullName)")
        if !profile.location.isEmpty  { lines.append("Location: \(profile.location)") }
        if !profile.email.isEmpty     { lines.append("Email: \(profile.email)") }
        if !profile.phone.isEmpty     { lines.append("Phone: \(profile.phone)") }
        if !profile.linkedIn.isEmpty  { lines.append("LinkedIn: \(profile.linkedIn)") }
        if !profile.portfolio.isEmpty { lines.append("Portfolio: \(profile.portfolio)") }

        if !profile.professionalSummary.isEmpty {
            lines.append("\nSummary:\n\(profile.professionalSummary)")
        }
        if !profile.experience.isEmpty {
            lines.append("\nExperience:")
            for job in profile.experience {
                lines.append("  Role: \(job.jobTitle)")
                lines.append("  Company: \(job.company)")
                lines.append("  Dates: \(job.startDate) – \(job.endDate)")
                if !job.description.isEmpty {
                    lines.append("  Details: \(job.description)")
                }
                lines.append("")
            }
        }
        if !profile.education.isEmpty {
            lines.append("Education:")
            for edu in profile.education {
                var e = "  • \(edu.degree) – \(edu.institution) (\(edu.graduationYear))"
                if !edu.grade.isEmpty { e += " — \(edu.grade)" }
                lines.append(e)
            }
        }
        if !profile.skills.isEmpty {
            lines.append("\nSkills: \(profile.skills.joined(separator: ", "))")
        }
        if !profile.fromField.isEmpty {
            lines.append("\nCareer transition: from \(profile.fromField) → \(profile.toField)")
        }
        if let gap = profile.gapReason {
            lines.append("\nCareer gap reason: \(gap.rawValue)")
        }
        return lines.joined(separator: "\n")
    }
}
