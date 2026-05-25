// Courses screen — language selector + list of courses for selected language

const LANGUAGES = {
  en: { name: "English", native: "English", font: "var(--font-latin)" },
  ja: { name: "Japanese", native: "日本語", font: "var(--font-cjk)" },
  es: { name: "Spanish", native: "Español", font: "var(--font-latin)" },
  he: { name: "Hebrew", native: "עברית", font: "var(--font-hebrew)" },
  ar: { name: "Arabic", native: "العربية", font: "var(--font-arabic)" },
  zh: { name: "Chinese", native: "中文", font: "var(--font-cjk)" },
};

const COURSES_BY_LANG = {
  ja: {
    courses: [
      { id: "jp-greet", title: "Greetings & Introductions", modules: 3, lessons: 12 },
      { id: "jp-hira", title: "Hiragana Foundations", modules: 5, lessons: 24 },
      { id: "jp-kata", title: "Katakana Foundations", modules: 5, lessons: 24 },
      { id: "jp-kanji", title: "Essential Kanji", modules: 8, lessons: 36 },
      { id: "jp-travel", title: "Travel Phrases", modules: 4, lessons: 16 },
      { id: "jp-food", title: "At the Restaurant", modules: 2, lessons: 8 },
    ],
  },
  es: {
    courses: [
      { id: "es-greet", title: "Saludos y Presentaciones", modules: 3, lessons: 12 },
      { id: "es-verbs", title: "Common Verbs", modules: 6, lessons: 30 },
      { id: "es-travel", title: "Travel Phrases", modules: 4, lessons: 16 },
      { id: "es-food", title: "Food & Dining", modules: 3, lessons: 14 },
    ],
  },
  he: {
    courses: [
      { id: "he-alef", title: "Alef-Bet Foundations", modules: 4, lessons: 22 },
      { id: "he-greet", title: "Everyday Greetings", modules: 3, lessons: 12 },
      { id: "he-verbs", title: "Verb Patterns", modules: 5, lessons: 25 },
    ],
  },
  ar: {
    courses: [
      { id: "ar-script", title: "Arabic Script Basics", modules: 4, lessons: 20 },
      { id: "ar-greet", title: "Greetings & Polite Phrases", modules: 3, lessons: 12 },
      { id: "ar-travel", title: "Travel Essentials", modules: 4, lessons: 16 },
    ],
  },
  zh: {
    courses: [
      { id: "zh-pinyin", title: "Pinyin & Tones", modules: 4, lessons: 20 },
      { id: "zh-hanzi", title: "Essential Hanzi", modules: 6, lessons: 30 },
      { id: "zh-greet", title: "Daily Greetings", modules: 3, lessons: 12 },
    ],
  },
};

const LanguageDropdown = ({ label, selected, onSelect, options, exclude }) => {
  const [open, setOpen] = React.useState(false);
  const ref = React.useRef(null);
  const lang = LANGUAGES[selected];

  React.useEffect(() => {
    if (!open) return;
    const onDoc = (e) => { if (ref.current && !ref.current.contains(e.target)) setOpen(false); };
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [open]);

  const entries = options.filter(c => c !== exclude);

  return (
    <div ref={ref} style={{ position: "relative", flex: 1, minWidth: 0 }}>
      <button
        onClick={() => setOpen(o => !o)}
        style={{
          width: "100%", display: "flex", alignItems: "center", gap: 8,
          padding: "10px 12px",
          borderRadius: 12,
          border: "1px solid var(--color-grey-200)",
          background: "#fff",
          cursor: "pointer",
          textAlign: "left",
          boxShadow: open ? "var(--shadow-card-compact)" : "none",
          transition: "box-shadow 200ms cubic-bezier(0.4,0,0.2,1)",
        }}>
        <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 2, minWidth: 0 }}>
          <span style={{ fontSize: 10, fontWeight: 500, letterSpacing: "0.06em",
            textTransform: "uppercase", color: "var(--fg-muted)" }}>{label}</span>
          <span style={{ display: "flex", alignItems: "baseline", gap: 6, minWidth: 0 }}>
            <span style={{ fontSize: 15, fontWeight: 500, color: "var(--fg-strong)",
              whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{lang.name}</span>
          </span>
        </div>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"
          style={{ color: "var(--fg-muted)", flexShrink: 0,
            transform: open ? "rotate(180deg)" : "rotate(0)",
            transition: "transform 200ms cubic-bezier(0.4,0,0.2,1)" }}>
          <path d="M7 10l5 5 5-5z" />
        </svg>
      </button>
      {open && (
        <div style={{
          position: "absolute", top: "calc(100% + 4px)", left: 0, right: 0,
          background: "#fff",
          borderRadius: 12,
          border: "1px solid var(--color-grey-200)",
          boxShadow: "var(--shadow-card)",
          zIndex: 10,
          overflow: "hidden",
        }}>
          {entries.map((code, i) => {
            const l = LANGUAGES[code];
            const isActive = code === selected;
            return (
              <button
                key={code}
                onClick={() => { onSelect(code); setOpen(false); }}
                style={{
                  width: "100%", display: "flex", alignItems: "center", gap: 12,
                  padding: "12px 14px",
                  border: "none",
                  borderBottom: i < entries.length - 1 ? "1px solid var(--color-grey-100)" : "none",
                  background: isActive ? "var(--color-blue-50)" : "transparent",
                  cursor: "pointer",
                  textAlign: "left",
                }}>
                <div style={{ flex: 1, display: "flex", alignItems: "baseline", gap: 8 }}>
                  <span style={{ fontSize: 15, fontWeight: isActive ? 600 : 500,
                    color: isActive ? "var(--brand-primary-text)" : "var(--fg-strong)" }}>{l.name}</span>
                  <span style={{ fontSize: 13, fontFamily: l.font,
                    color: isActive ? "var(--brand-primary)" : "var(--fg-muted)" }}>{l.native}</span>
                </div>
                {isActive && <Icon name="check" size={20} style={{ color: "var(--brand-primary)" }} />}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
};

const CourseRow = ({ course, onClick }) => (
  <div className="course-row" onClick={onClick}>
    <div className="course-avatar">
      <Icon name="menu_book" filled />
    </div>
    <div className="body">
      <div className="title">{course.title}</div>
      <div className="meta">
        <span><Icon name="layers" /> {course.modules} modules</span>
        <span><Icon name="school" /> {course.lessons} lessons</span>
      </div>
    </div>
    <Icon name="chevron_right" size={24} style={{ color: "var(--color-grey-400)" }} />
  </div>
);

const CoursesPage = ({ onPickCourse }) => {
  const [studentLang, setStudentLang] = React.useState("en");
  const [learningLang, setLearningLang] = React.useState("ja");
  const lang = COURSES_BY_LANG[learningLang] || { courses: [] };
  const allCodes = Object.keys(LANGUAGES);
  const learningOptions = allCodes.filter(c => c !== "en" || studentLang !== "en"); // allow learning anything except own native

  return (
    <div className="page page-courses">
      <div className="page-header" style={{ padding: "16px 8px 8px" }}>
        <h1 className="page-title" style={{ fontSize: 24 }}>Courses</h1>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 8, margin: "4px 0 16px" }}>
        <LanguageDropdown
          label="Learning"
          selected={learningLang}
          onSelect={(c) => { setLearningLang(c); if (c === studentLang) setStudentLang(allCodes.find(x => x !== c)); }}
          options={allCodes}
          exclude={studentLang} />
        <LanguageDropdown
          label="I speak"
          selected={studentLang}
          onSelect={(c) => { setStudentLang(c); if (c === learningLang) setLearningLang(allCodes.find(x => x !== c)); }}
          options={allCodes}
          exclude={learningLang} />
      </div>
      <div style={{ height: 16 }} />
      {lang.courses.length === 0 ? (
        <div style={{ padding: 24, textAlign: "center", color: "var(--fg-muted)", fontSize: 14 }}>
          No courses available for this language yet.
        </div>
      ) : lang.courses.map(c => <CourseRow key={c.id} course={c} onClick={() => onPickCourse(c)} />)}
    </div>
  );
};

Object.assign(window, { CourseRow, CoursesPage, LanguageDropdown, COURSES_BY_LANG, LANGUAGES });
