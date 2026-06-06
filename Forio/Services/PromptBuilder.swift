import Foundation

enum PromptBuilder {

    static func build(profile: UserProfile, jobDescription: String, template: CVTemplate) -> String {
        let systemInstruction = personaInstruction(for: profile)
        let profileSummary = buildProfileSummary(profile)

        return """
        \(systemInstruction)
        
        CANDIDATE PROFILE:
        \(profileSummary)
        
        JOB DESCRIPTION:
        \(jobDescription)
        
        TEMPLATE STYLE: \(template.displayName)
        
        TASK:
        Generate a tailored CV and cover letter for this specific job.
        
        Return ONLY a valid JSON object with this exact format, no markdown:
        {
          "cvContent": "Full CV text formatted for \(template.displayName) style",
          "coverLetterContent": "Full cover letter text",
          "matchScore": 85,
          "matchedKeywords": ["keyword1", "keyword2"],
          "aiInsights": ["insight about tailoring 1", "insight about tailoring 2"]
        }
        
        CV rules:
        - Match the language and keywords from the job description
        - Use strong action verbs
        - Be specific and quantify achievements where possible
        - Keep CV to 1-2 pages worth of content
        - Cover letter should be 3 short paragraphs: hook, evidence, call-to-action
        - matchScore is 0-100 based on how well the profile matches the JD
        - matchedKeywords are keywords from the JD found in the profile
        - aiInsights are 2-3 short notes about how the CV was tailored
        - Return only valid JSON, nothing else
        """
    }

    // MARK: - Persona-specific system instructions

    private static func personaInstruction(for profile: UserProfile) -> String {
        switch profile.persona {

        case .graduate:
            return """
            SYSTEM: This is a recent graduate with limited work experience.
            Lead with education, university projects, and transferable skills.
            Use enthusiastic, forward-looking language.
            Frame part-time and voluntary work as genuine experience.
            Do not penalise or draw attention to gaps in employment history.
            Highlight potential, eagerness to learn, and relevant coursework.
            """

        case .experienced:
            return """
            SYSTEM: This is an experienced professional seeking a new role.
            Lead with career achievements and measurable impact.
            Use confident, results-driven language.
            Prioritise the most recent 3-5 years of experience.
            Surface quantifiable achievements wherever possible (%, £, team sizes).
            Keep education brief — it is secondary to work history.
            """

        case .careerChanger:
            let from = profile.fromField.isEmpty ? "their previous field" : profile.fromField
            let to = profile.toField.isEmpty ? "the target field" : profile.toField
            return """
            SYSTEM: This person is switching careers from \(from) to \(to).
            Your primary job is to build a bridge narrative.
            Reframe past experience as transferable skills relevant to \(to).
            Downplay unrelated job titles — lead with competencies, not roles.
            Draw out transferable skills: analytical thinking, communication, deadlines, stakeholders.
            The opening summary must clearly explain the transition and make it compelling.
            """

        case .returning:
            let reason = profile.gapReason?.rawValue ?? "a career break"
            return """
            SYSTEM: This person is returning to work after \(reason).
            Frame the gap honestly and positively — do not hide it.
            Acknowledge the gap briefly in the cover letter with a positive framing.
            Emphasise skills maintained or gained during the gap.
            Highlight any freelance, volunteer, or training activity during the gap.
            Use confident, forward-looking language focused on what they bring now.
            """
        }
    }

    // MARK: - Profile → readable text

    private static func buildProfileSummary(_ profile: UserProfile) -> String {
        var lines: [String] = []

        lines.append("Name: \(profile.fullName)")
        if !profile.location.isEmpty      { lines.append("Location: \(profile.location)") }
        if !profile.email.isEmpty         { lines.append("Email: \(profile.email)") }
        if !profile.phone.isEmpty         { lines.append("Phone: \(profile.phone)") }
        if !profile.linkedIn.isEmpty      { lines.append("LinkedIn: \(profile.linkedIn)") }
        if !profile.portfolio.isEmpty     { lines.append("Portfolio: \(profile.portfolio)") }

        if !profile.professionalSummary.isEmpty {
            lines.append("\nSummary:\n\(profile.professionalSummary)")
        }

        if !profile.experience.isEmpty {
            lines.append("\nExperience:")
            for job in profile.experience {
                let period = "\(job.startDate) – \(job.endDate)"
                lines.append("  • \(job.jobTitle) at \(job.company) (\(period))")
                if !job.description.isEmpty {
                    lines.append("    \(job.description)")
                }
            }
        }

        if !profile.education.isEmpty {
            lines.append("\nEducation:")
            for edu in profile.education {
                var entry = "  • \(edu.degree) – \(edu.institution) (\(edu.graduationYear))"
                if !edu.grade.isEmpty { entry += " — \(edu.grade)" }
                lines.append(entry)
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
