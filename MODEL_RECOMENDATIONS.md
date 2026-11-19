
. Model Routing in Pydantic AI

In Pydantic AI, you can easily swap models per agent or per agent.run() call using the google-gla: prefix.
• Curriculum & Grammar Agent (google-gla:gemini-4-neon): Use this for your primary generator agent where complex Semitic root mapping (שורשים) and nuanced dialect explanations matter most.
• Exercise & Flashcard Agent (google-gla:gemini-3.8-flash): Pass this model string when running high-volume tasks like generating 20 practice drills per lesson or extracting vocabulary cards.
• Fast Validation & Formatting (google-gla:gemini-3.5-flash-lite): Ideal for lightweight post-processing agents, such as verifying that all Hebrew translations are natural or tagging difficulty levels.

2. Custom @agent.result_validator for Linguistic Guardrails

Because LLMs occasionally drop Arabic vowel markings (tashkeel) or mix up Hebrew transliteration conventions, you can use Pydantic AI's result validators to catch errors automatically and force a retry:
• Enforce Arabic Diacritics (Tashkeel): Write a regex check inside @agent.result_validator to verify that beginner Arabic strings contain Unicode diacritic characters (\u064B–\u0652). If the model outputs unvocalized text, raise ModelRetry("Include full tashkeel diacritics on all Arabic words.").
• Validate Hebrew Transliteration Rules: Check that the Hebrew transliteration field only contains Hebrew characters, spaces, and your designated phonetic markers (like ' for غ or ח'), preventing the model from accidentally slipping into Latin/English transliteration.
• Prevent "False Friend" Hallucinations: If you include a shared_hebrew_root field in your Pydantic model, use a validator or a lightweight lookup table to ensure the model doesn't mistakenly link false friends (like לחם and لحم).

3. Dynamic System Prompts with RunContext

Use Pydantic AI's deps_type and @agent.system_prompt to inject course state dynamically as you generate sequential units:
• Dialect & Level Locking: Pass target_dialect (e.g., "Spoken Palestinian" vs. "MSA") and student_level via deps so a single agent definition can generate lessons across your entire curriculum.
• Cumulative Vocabulary Tracking: Pass known_vocabulary: list[str] in your RunContext so the agent prioritizes words the student already learned in previous lessons when writing new dialogues.

4. Multi-Agent Quality Control (Generator + Critic)

For high-stakes educational content, set up a lightweight two-agent handoff in Python:
• Generator Agent (gemini-4-neon): Drafts the complete lesson, dialogue, and grammar comparison.
• Linguistic Critic Agent (gemini-3.8-flash): Reviews the structured Pydantic output specifically for naturalness in Israeli Hebrew and accuracy in the target Arabic dialect, returning structured feedback if any phrasing sounds overly robotic or textbook-heavy.
Are you currently running into any specific bottlenecks with your Pydantic AI setup—such as tashkeel consistency, transliteration accuracy, or structuring multi-part lessons?
