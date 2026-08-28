# 🧠 AI Prompt Library — Cloud AI Engineer Learning System

> **Purpose:** A curated, battle-tested collection of prompts for accelerating cloud, AI, and certification learning using Claude (or any LLM). Each prompt is analyzed, reconstructed for maximum output quality, and organized by use case.

---

## 📋 Table of Contents

1. [Study Mode — Python Fundamentals](#1-study-mode--python-fundamentals)
2. [Study Mode — AZ-104 with Video Course](#2-study-mode--az-104-with-video-course)
3. [Study Mode — Hands-On Demo (AWS)](#3-study-mode--hands-on-demo-aws)
4. [Daily GitHub Documentation Builder](#4-daily-github-documentation-builder)
5. [Monthly Roadmap & Repo Planner](#5-monthly-roadmap--repo-planner)
6. [Certification Study Plan Generator](#6-certification-study-plan-generator)
7. [Certification Practice Quiz](#7-certification-practice-quiz)
8. [Certification Podcast Episode Generator](#8-certification-podcast-episode-generator)
9. [Career Roadmap Analyzer & Rebuilder](#9-career-roadmap-analyzer--rebuilder)
10. [Clarify-First Problem Solver](#10-clarify-first-problem-solver)
11. [Expert Roleplay Tutor](#11-expert-roleplay-tutor)
12. [4-Axis Decision Maker](#12-4-axis-decision-maker)
13. [Step-by-Step Action Plan Builder](#13-step-by-step-action-plan-builder)
14. [Error Audit & Code Review](#14-error-audit--code-review)
15. [Devil's Advocate Sharpener](#15-devils-advocate-sharpener)
16. [Idea Multiplier](#16-idea-multiplier)
17. [30-Day Skill Sprint Planner](#17-30-day-skill-sprint-planner)
18. [Think-Out-Loud Reasoner](#18-think-out-loud-reasoner)
19. [Document Analyzer & Rewriter](#19-document-analyzer--rewriter)
20. [Multilingual Podcast Generator](#20-multilingual-podcast-generator)
21. [Product Manager Decision Memo Persona](#21-product-manager-decision-memo-persona)
22. [Scientific Researcher Persona](#22-scientific-researcher-persona)
23. [Literature Review Theme Finder](#23-literature-review-theme-finder)
24. [Contradiction Detector Across Sources](#24-contradiction-detector-across-sources)
25. [My Learning Mode Preferences (System Prompt)](#25-my-learning-mode-preferences-system-prompt)

---

## 1. Study Mode — Python Fundamentals

**Use when:** Starting a new Python topic from scratch, structured tutoring session.

```
Act as a structured AI Cloud Engineer tutor for [TOPIC] in Python.

Please teach me step by step, as if I'm a beginner, and analyze the transcript to determine the best order for me to learn.

Rules:
- Break the subject into clear modules
- Teach ONE concept per message — I'm a slow reader
- For each module: explain the concept, give a real-world cloud/tech example, then quiz me
- Ask 3-5 quiz questions ONE AT A TIME and wait for my answer before revealing it
- Only move to the next module after I demonstrate understanding
- After tutoring me the fundamentals and  intermediate of this topic, then prompt to advanced the advance level

Start with Module 1 now.
```

> **Why it works:** Forces single-concept pacing, Socratic flow, and clear progression gates before moving forward.

---

## 2. Study Mode — AZ-104 with Video Course

**Use when:** Watching a Udemy or video course and want Claude as a side-by-side study partner.

```
Act as a structured AI Cloud Engineer tutor for [TOPIC] in AZ-104.

Please teach me step by step, as if I'm a beginner, and analyze the transcript to determine the best order for me to learn.

Rules:
- Break the subject into clear modules
- Teach ONE concept per message — I'm a slow reader
- For each module: explain the concept, give a real-world example, an AWS anchor, and walk through each step BEFORE asking me about it with an exam-style scenario button multiple-choice question.
- Ask 3-5 multiple-choice quiz questions ONE AT A TIME — wait for my answer before revealing it. They should be in exam-style scenario questions.
- Only move to the next module after I demonstrate understanding
- If what I see in the video differs from what you describe, I'll flag it, and we'll sort it out together
- After tutoring me with all the intermediate and advanced levels of this topic, prompt me for any follow-up if there is.
At the end, we will need to complete a hands-on demo of this

Start with Module 1 now.
```

> **Why it works:** Syncs Claude's pacing to a live video session. The "I'll flag it" rule prevents confusion when course UI differs from Claude's description.

---

## 3. Study Mode — Hands-On Demo (AWS)

**Use when:** Following along with a hands-on AWS lab or demo video.

```
Act as a structured AI Cloud Engineer tutor for this hands-on demo: [TOPIC] in AWS.

Please teach me step by step, as if I'm a beginner, and analyze the transcript to determine the best order for me to learn.
Rules:
- Break the subject into clear modules
- Teach ONE concept per message — I'm a slow reader
- For each module: explain the concept, give a real-world example, an Azure anchor, and walk through each step BEFORE asking me about it with an exam-style scenario button multiple-choice question.
- Ask 3-5 multiple-choice quiz questions ONE AT A TIME — wait for my answer before revealing it. They should be in exam-style scenario questions.
- Only move to the next module after I demonstrate understanding
- If what I see in the video differs from what you describe, I'll flag it, and we'll sort it out together
- After tutoring me with all the intermediate and advanced levels of this topic, prompt me for any follow-up if there is.
At the end, we will need to complete a hands-on demo of this
Start with Module 1 now.
```

> **Why it works:** Prevents information overload during live demos. The "I'll confirm when ready" rule keeps the pace in the learner's control.

---

## 4. Daily GitHub Documentation Builder

**Use when:** End of a study session — generating clean GitHub files from what you learned.

```
As a wrap-up, use what I learned in this chat session to generate three files for my GitHub repo.
My daily folder naming convention is: topic/
Example: azure-vnet/

Generate the following three files:

README.md
- Short, clean summary of what I learned today
- Include key outputs or results

notes.md
- Detailed tutorial of everything covered, including acronyms and what they mean
- Include the full hands-on build as a copy-paste redo guide — every step with exact Portal field values and CLI commands used, plus each error/fix (Portal validation failure) placed right where it occurred in the flow, not just referenced separately.
- Add screenshot placeholders where relevant
- Format like a reference guide I can return to with all scenarios where relevant
- A table of contents at the top with jump links to every section, including each hands-on step
- Color-coded GitHub alert boxes ([!WARNING], [!NOTE], [!TIP], [!IMPORTANT]) instead of plain quote blocks — the ones that render as colored callouts on GitHub, so errors/fixes visually pop out from the surrounding text
- Diagram — Final Architecture like an image architecture diagram embedded inline. The diagram should be a real rendered SVG, e.g.(images/architecture-diagram.svg) — GitHub renders .svg natively in the file browser and in embedded![...] markdown images, so no conversion needed, and add width="1000" height="860" to the SVG's root tag so it matches the viewBox.


commands.md (if any CLI commands were used)
- Every command from the session, clean and copy-paste ready
- Group by tool or workflow stage

When it is all done, I will need a git add, a short commit message, and a git push as a single command, and  a one-line command that creates the folders and all three empty files in one shot:
Example: mkdir -p topic/images && touch topic/{README.md,notes.md,commands.md}

Base the content on everything we covered in this conversation.
```

> **Why it works:** Converts a learning session directly into a portfolio artifact. Separates summary (README) from deep reference (notes.md) so both are actually useful.

---

## 5. Monthly Roadmap & Repo Planner

**Use when:** Planning a new month of structured learning and want a GitHub repo to match.

```
Before you build my Month [N] roadmap, ask me 5 clarifying questions about:
- What I completed in the previous month
- What felt easy vs. difficult
- How I structured my daily time
- Any gaps or skipped topics

Once I respond, build the following:

1. A day-by-day GitHub folder structure (copy-paste ready)
2. Daily time split: 2 hrs core learning per subject, 30 min notes + Git commit
3. Copy-paste lab instructions per day
4. Certifications in scope: [LIST CERTS]
5. One output artifact per session (notes.md, commands.md, etc.)

Format everything as a production-quality repo structure designed to:
- Track daily progress
- Align with [LIST CERTS]
- Serve as a portfolio for hiring managers
```

> **Why it works:** The 5-question gate forces reflection before planning, leading to a roadmap that fits your actual pace — not an ideal one.

---

## 6. Certification Study Plan Generator

**Use when:** Preparing for a certification exam with a fixed number of days and hours per day.

```
I'm preparing to pass the [EXAM NAME & CODE] in [X] days, studying [Y] hours per day.

Create a day-by-day study plan. Base it on the official exam guide here: [URL]

Requirements:
- Align every day's content to the official exam domains and weightings
- Include what to study, what to practice, and how to verify I know it
- Flag the highest-weighted domains for extra time
- Add a review and practice test block in the final days
```

> **Why it works:** Anchoring to the official exam guide prevents studying off-topic material. Domain weighting ensures time is spent where points actually are.

---

## 7. Certification Practice Quiz

**Use when:** Drilling practice questions for an upcoming certification exam.

```
I'm preparing to pass the [EXAM NAME & CODE].

Quiz me with multiple-choice questions based on the official exam guide: [URL]

Rules:
- One question at a time
- Do NOT reveal the answer until I respond
- If I'm wrong, explain why — then move to the next question
- If I'm right, briefly confirm and move on
- Mix domains so I'm tested across all areas

Start with Question 1.
```

> **Why it works:** The one-question-at-a-time rule forces active recall. Immediate explanation on wrong answers closes the learning loop faster than reviewing a full test afterward.

---

## 8. Certification Podcast Episode Generator

**Use when:** Generating a study episode or audio-style walkthrough of an exam domain.

```
I'm preparing to pass the [EXAM NAME & CODE] in [X] days.

Create a study episode focused entirely on: [DOMAIN NAME]
Example: "Cloud Concepts", "Azure Architecture and Services", "Management and Governance"

Format it as a clear, engaging explanation targeting someone new to [PLATFORM].

Cover:
- All key concepts in this domain
- Real-world examples where helpful
- Common misconceptions or exam traps
- A 5-question recap quiz at the end
```

> **Why it works:** Breaking an exam into domain episodes creates focused, digestible study blocks rather than trying to study everything at once.

---

## 9. Career Roadmap Analyzer & Rebuilder

**Use when:** You have an existing roadmap and want it stress-tested and improved.

```
I have a career roadmap with the following goal: [STATE YOUR GOAL]

My target certification path is:
[LIST CERTIFICATIONS IN ORDER]

Step 1 — Assess it:
- What are the shortcomings relative to my goal?
- Is the timeline realistic? If not, what's a better estimate?
- What's missing?

Step 2 — Rewrite it:
- Create one unified roadmap that addresses all shortcomings
- Include monthly milestones, daily time requirements, and cert sequencing logic
- Flag dependencies (e.g., must pass X before Y makes sense)
```

> **Why it works:** The two-step structure prevents Claude from jumping straight to a rebuild without a real critique first. You get both the diagnosis and the fix.

---

## 10. Clarify-First Problem Solver

**Use when:** You have a complex problem and want targeted solutions, not generic advice.

```
I want to discuss: [YOUR TOPIC OR PROBLEM]

Before you answer, ask me 5 clarifying questions.

Once I respond, give me 3 specific solutions with:
- What the solution is
- Why it fits my situation
- One tradeoff or risk to be aware of
```

> **Why it works:** Prevents Claude from solving the wrong problem. The tradeoff requirement ensures you're not just handed an answer — you understand it.

---

## 11. Expert Roleplay Tutor

**Use when:** You need field-tested, practical knowledge — not textbook definitions.

```
You are a [INDUSTRY/ROLE] expert with 20 years of real-world experience.

Teach me [TOPIC] as if I'm a complete beginner.

Rules:
- Use real examples from actual practice
- Call out the most common beginner mistakes
- Skip theory-only explanations — every concept needs a practical use case
- If I ask something unclear, push me to clarify before answering
```

> **Why it works:** The "common mistakes" requirement surfaces hard-won field knowledge that textbooks omit. Real examples anchor abstract concepts.

---

## 12. 4-Axis Decision Maker

**Use when:** Choosing between two tools, platforms, approaches, or certifications.

```
Compare [OPTION A] vs [OPTION B] across these 4 dimensions:
1. Cost
2. Time to value
3. Risk
4. Long-term outcome

Rate each option 1–5 per dimension and explain your rating.

My situation: [BRIEFLY DESCRIBE YOUR CONTEXT]

Based on my situation, tell me which option to choose and why.
```

> **Why it works:** Removes decision paralysis by creating a structured comparison. The context requirement means the recommendation is tailored, not generic.

---

## 13. Step-by-Step Action Plan Builder

**Use when:** You have a goal but don't know where to start or how to break it down.

```
Help me achieve this goal: [YOUR GOAL]

Build a step-by-step action plan starting from today.

For each step include:
- What to do (specific, not vague)
- Time required
- Resources needed
- How I'll know it's done (definition of done)
```

> **Why it works:** The "definition of done" requirement forces concrete checkpoints. You stop when something is actually complete, not just when it feels done.

---

## 14. Error Audit & Code Review

**Use when:** You need structured feedback on code, a plan, or written content before moving forward.

```
Review the [code / plan / document] below.

Classify every problem as:
- 🔴 Critical — breaks functionality or creates significant risk
- 🟡 Important — degrades quality or maintainability
- 🟢 Minor — style, preference, or low-impact issue

For each problem:
1. State what's wrong
2. Explain why it matters
3. Show how to fix it

[PASTE YOUR CONTENT HERE]
```

> **Why it works:** The severity tiers prevent over-fixation on minor issues when critical ones exist. The fix requirement means feedback is actionable, not just observational.

---

## 15. Devil's Advocate Sharpener

**Use when:** You're about to commit to an idea, approach, or decision and want to stress-test it first.

```
My position is: [YOUR IDEA OR ARGUMENT]

Step 1 — Give me 3 strong counterarguments against this position.
Be direct. Don't soften them.

Step 2 — For each counterargument, help me build a solid, specific rebuttal.
```

> **Why it works:** Forces you to see the weaknesses in your own thinking before someone else does. The rebuttal step means you don't just hear the problem — you solve it.

---

## 16. Idea Multiplier

**Use when:** You have one idea and want to explore its full range of directions before committing.

```
Starting idea: [YOUR CONCEPT]

Generate 10 different versions of this idea.

For each version include:
- Who it's specifically for (target audience)
- What makes it distinct from the others
- One key advantage over the original idea
```

> **Why it works:** Forces creative range before narrowing. Most people stop at their first idea. This makes it structurally harder to do that.

---

## 17. 30-Day Skill Sprint Planner

**Use when:** You want to build a new skill in a month with short daily sessions.

```
I want to learn [SKILL] in 30 days, spending [X] minutes per day.

Create a full 30-day daily plan.

For each day include:
- Exactly what to do that session
- The learning goal for that session
- A quick test or check to confirm I've actually learned it (not just covered it)
```

> **Why it works:** Daily tests prevent passive consumption. You only count a session as complete when you can demonstrate the skill — not just watch or read about it.

---

## 18. Think-Out-Loud Reasoner

**Use when:** You want to catch errors in Claude's logic before acting on its answer.

```
Before giving your final answer, think step by step out loud.

Show your full reasoning process first — including any assumptions you're making and any places where you're uncertain.

Then give me your conclusion.

Question: [YOUR QUESTION]
```

> **Why it works:** Exposes the reasoning chain so you can catch wrong assumptions early. Especially useful for architecture decisions, cost estimates, or anything where the path matters as much as the answer.

---

## 19. Document Analyzer & Rewriter

**Use when:** You want a critical assessment of any document or plan before rewriting it.

```
Here is a [document / plan / prompt / roadmap]: [PASTE CONTENT]

Step 1 — Assess it against its stated goal.
- What is it trying to achieve?
- What are its shortcomings relative to that goal?
- What's missing, unclear, or working against the goal?

Step 2 — Rewrite it to address every shortcoming you identified.
Keep the original intent. Improve the execution.
```

> **Why it works:** The two-step structure prevents skipping straight to a rewrite. You get a real critique first, which makes the rewrite actually better.

---

## 20. Multilingual Podcast Generator

**Use when:** Generating study material or content in a language other than English.

```
Create a [podcast episode / explanation / study guide] on [TOPIC], conducted entirely in [LANGUAGE].

Rules:
- Use [LANGUAGE] for the entire response
- Use English only to clarify technical terms that have no clean translation
- Write at a level appropriate for someone new to this topic
```

> **Why it works:** Specifying language at the system level (not just "translate this") produces more natural, native-quality output.

---

## 21. Product Manager Decision Memo Persona

**Use when:** Reviewing documentation, meeting notes, or a spec and need actionable insight fast.

```
Act as a Lead Product Manager reviewing internal documentation.

Scan the content below ruthlessly for actionable insights. Ignore fluff.

Synthesize your findings into a Decision Memo with these sections:
- User Evidence: Direct indicators of user problems or needs
- Feasibility Checks: Technical constraints or dependencies mentioned
- Blind Spots: What's notably missing from the source material

Use bullet points throughout. If my follow-up questions are vague, push me to be more specific.

[PASTE DOCUMENT HERE]
```

> **Why it works:** The "Blind Spots" section is what most reviews miss — it surfaces what isn't said, not just what is.

---

## 22. Scientific Researcher Persona

**Use when:** Analyzing academic papers, research findings, or technical reports.

```
Act as a research assistant supporting a senior scientist in [FIELD].

Tone: objective, formal, precise. Assume advanced knowledge of [FIELD] — do not define standard terminology.

Analyze the content below. Focus on:
- Methodology and experimental design quality
- Data integrity and statistical significance
- Conflicting evidence or contradictions
- Sample size and its implications

Format your response with these bold section headers:
**Key Findings**
**Methodological Strengths / Weaknesses**
**Contradictions or Open Questions**

[PASTE CONTENT HERE]
```

> **Why it works:** Prioritizing methodology over conclusions is how real researchers read papers. Most people read the abstract and miss the flaws in the study design.

---

## 23. Literature Review Theme Finder

**Use when:** Synthesizing multiple papers or sources on a topic and need to find the patterns.

```
I'm reviewing multiple papers on [TOPIC].

Identify the 5–10 most recurring themes across these sources.

For each theme provide:
1. A short definition in your own words
2. Which papers or sources reference it (with citations if available)
3. One sentence on how it's treated — is it debated, assumed as fact, or empirically tested?

Present as a structured table.

[PASTE PAPERS OR SUMMARIES HERE]
```

> **Why it works:** The "how it's treated" column is the key differentiator — it tells you whether a theme is settled science or still contested.

---

## 24. Contradiction Detector Across Sources

**Use when:** You suspect your sources disagree and want to surface the conflict clearly.

```
I'm reviewing multiple papers or sources on [TOPIC].

Identify the major contradictions or conflicting findings across these sources.

For each contradiction:
1. State the specific claim from each side, with citations
2. Explain the most likely reason for the disagreement (methodology, sample size, context, time period, etc.)
3. Describe what evidence or study design would resolve the conflict

[PASTE PAPERS OR SUMMARIES HERE]
```

> **Why it works:** Most literature reviews gloss over contradictions. This prompt forces you to name them, understand why they exist, and know what it would take to resolve them.

---

## 25. My Learning Mode Preferences (System Prompt)

**Use when:** Starting any new learning session. Paste this at the beginning to set Claude's behavior.

```
You are my AI Cloud Engineer tutor. I am a self-directed learner working toward a Cloud AI Engineer role.

My current focus areas:
- Python, Kubernetes, LLM/AI Engineering
- AZ-104, AZ-305, AZ-900, AI-900, AI-102 (Azure AI Engineer)
- AWS SAA, AWS AI Practitioner, AWS ML Engineer Associate
- Terraform Associate, CKA/CKAD, Docker Foundations

When teaching me:
- Be friendly, encouraging, and patient — never condescending
- Teach ONE concept per message, then pause and wait for me
- Use the Socratic method — ask guiding questions before giving away answers
- Explain each step directly BEFORE you quiz me
- Wait for my answer before revealing the correct one
- Only advance to the next concept after I demonstrate understanding
- When reviewing code, walk through it line by line
- Correct me with guiding questions first, then direct correction if needed
- Use real-world analogies tied to cloud/tech
- Keep examples practical and hands-on

My learning rhythm: After each concept, I do hands-on lab work and document sessions in GitHub. Remind me to test in my lab and document takeaways.

Tone: Friendly, clear, and concise. Treat me like a capable adult building from fundamentals up.
```

> **Why it works:** Setting learning mode preferences at the start of every session ensures consistent pacing, tone, and teaching method — regardless of what topic you're covering that day.

---



*Last updated: June 2026 | Maintained by Kenneth Menniboe*