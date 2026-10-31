// Course detail page — header + numbered lesson list with progress
// Two variations exposed via a `variant` prop ('list' | 'cards').

const COURSE_LESSONS = [
  { num: 1, title: "Hello & Goodbye",          words: 8,  bestScore: 100, status: "done" },
  { num: 2, title: "Polite Introductions",     words: 12, bestScore: 90,  status: "done" },
  { num: 3, title: "Greetings & Introductions", words: 14, bestScore: null, status: "current" },
  { num: 4, title: "Asking Names",             words: 10, bestScore: null, status: "todo" },
  { num: 5, title: "Numbers 1–10",             words: 10, bestScore: null, status: "todo" },
  { num: 6, title: "Days of the Week",         words: 7,  bestScore: null, status: "todo" },
  { num: 7, title: "Family Members",           words: 16, bestScore: null, status: "todo" },
  { num: 8, title: "Common Verbs",             words: 18, bestScore: null, status: "todo" },
];

const CourseHeader = ({ course, target, source, completed, total }) => {
  const pct = Math.round((completed / total) * 100);
  return (
    <div className="card" style={{ padding: 20 }}>
      <div style={{
        fontSize: 11, fontWeight: 500, letterSpacing: ".08em",
        textTransform: "uppercase", color: "var(--brand-primary)",
        marginBottom: 6,
      }}>Course</div>
      <h1 style={{
        fontSize: 24, fontWeight: 400, color: "var(--fg-strong)",
        margin: 0, letterSpacing: "-.01em", lineHeight: 1.2,
      }}>{course}</h1>
      <div style={{
        display: "flex", alignItems: "center", gap: 8,
        fontSize: 13, color: "var(--fg-muted)", marginTop: 8,
      }}>
        <span style={{ fontFamily: target.font }}>{target.native}</span>
        <span style={{ color: "var(--fg-subtle)" }}>→</span>
        <span>{source.name}</span>
      </div>
      <div style={{ display: "flex", justifyContent: "space-between",
        fontSize: 13, color: "var(--fg-muted)", margin: "16px 0 6px" }}>
        <span>{completed} of {total} lessons</span>
        <span>{pct}%</span>
      </div>
      <ProgressBar value={pct} />
    </div>
  );
};

// ── Variation A: dense numbered list ────────────────────────────────────────
const LessonRowList = ({ lesson, onClick }) => {
  const isDone = lesson.status === "done";
  const isCurrent = lesson.status === "current";
  return (
    <button
      onClick={onClick}
      className="lesson-row"
      style={{
        width: "100%", display: "flex", alignItems: "center", gap: 14,
        padding: "14px 16px",
        background: isCurrent ? "var(--color-blue-50)" : "#fff",
        border: "1px solid " + (isCurrent ? "var(--brand-primary-border)" : "var(--color-grey-200)"),
        borderRadius: 12, marginBottom: 8, cursor: "pointer", textAlign: "left",
      }}>
      <div style={{
        width: 32, height: 32, borderRadius: "50%",
        background: isDone ? "var(--state-correct-icon)"
          : isCurrent ? "var(--brand-primary)"
          : "var(--color-grey-200)",
        color: isDone || isCurrent ? "#fff" : "var(--fg-muted)",
        display: "flex", alignItems: "center", justifyContent: "center",
        fontSize: 14, fontWeight: 600, flexShrink: 0,
      }}>
        {isDone ? <Icon name="check" size={18} /> : lesson.num}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 15, fontWeight: 500, color: "var(--fg-strong)",
          whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
        }}>{lesson.title}</div>
        <div style={{
          fontSize: 12, color: "var(--fg-muted)", marginTop: 3,
          display: "flex", alignItems: "center", gap: 10,
        }}>
          <span>{lesson.words} words</span>
          {lesson.bestScore != null && (
            <span style={{ display: "inline-flex", alignItems: "center", gap: 3,
              color: "var(--state-correct-fg)" }}>
              <Icon name="emoji_events" filled size={12} /> {lesson.bestScore}%
            </span>
          )}
          {isCurrent && (
            <span style={{ color: "var(--brand-primary)", fontWeight: 500 }}>In progress</span>
          )}
        </div>
      </div>
      <Icon name="chevron_right" size={20} style={{ color: "var(--color-grey-400)" }} />
    </button>
  );
};

// ── Variation B: spacious cards with score chip on the right ────────────────
const LessonRowCard = ({ lesson, onClick }) => {
  const isDone = lesson.status === "done";
  const isCurrent = lesson.status === "current";
  return (
    <button
      onClick={onClick}
      style={{
        width: "100%", display: "flex", alignItems: "center", gap: 14,
        padding: "16px",
        background: "#fff",
        border: "1px solid " + (isCurrent ? "var(--brand-primary)" : "var(--color-grey-200)"),
        borderRadius: 14, marginBottom: 10, cursor: "pointer", textAlign: "left",
        boxShadow: isCurrent ? "0 4px 12px rgba(25,118,210,.15)" : "none",
      }}>
      <div style={{
        fontSize: 11, fontWeight: 600, letterSpacing: ".08em",
        color: "var(--fg-subtle)", width: 28, textAlign: "center", flexShrink: 0,
      }}>
        {String(lesson.num).padStart(2, "0")}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <div style={{
            fontSize: 15, fontWeight: 500, color: "var(--fg-strong)",
            whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
          }}>{lesson.title}</div>
          {isCurrent && (
            <span style={{
              fontSize: 10, fontWeight: 600, letterSpacing: ".06em",
              padding: "2px 6px", borderRadius: 4,
              background: "var(--brand-primary)", color: "#fff",
              textTransform: "uppercase", flexShrink: 0,
            }}>Now</span>
          )}
        </div>
        <div style={{ fontSize: 12, color: "var(--fg-muted)", marginTop: 4 }}>
          {lesson.words} words · phrases
        </div>
      </div>
      <div style={{ flexShrink: 0, textAlign: "right" }}>
        {isDone ? (
          <div style={{
            fontSize: 14, fontWeight: 600, color: "var(--state-correct-fg)",
            display: "flex", alignItems: "center", gap: 4, justifyContent: "flex-end",
          }}>
            <Icon name="check_circle" filled size={16} />
            {lesson.bestScore}%
          </div>
        ) : (
          <Icon name="chevron_right" size={20} style={{ color: "var(--color-grey-400)" }} />
        )}
      </div>
    </button>
  );
};

const CourseDetailPage = ({ onBack, onPickLesson, onSwitchCourse, variant = "list" }) => {
  const lessons = COURSE_LESSONS;
  const completed = lessons.filter(l => l.status === "done").length;
  const target = { name: "Japanese", native: "日本語", font: "var(--font-cjk)" };
  const source = { name: "English" };
  const Row = variant === "cards" ? LessonRowCard : LessonRowList;
  return (
    <div className="page page-course-detail">
      <div className="quiz-header" style={{ padding: "8px 0 16px" }}>
        <div className="row1">
          <button className="icon-btn" onClick={onBack}><Icon name="arrow_back" /></button>
          <span className="title">Course</span>
          {onSwitchCourse && (
            <button
              onClick={onSwitchCourse}
              style={{
                display: "inline-flex", alignItems: "center", gap: 4,
                padding: "6px 10px", borderRadius: 8,
                border: "1px solid var(--brand-primary-border)",
                background: "var(--color-blue-50)", color: "var(--brand-primary)",
                fontSize: 13, fontWeight: 500, cursor: "pointer",
              }}>
              <Icon name="swap_horiz" size={16} />
              Switch
            </button>
          )}
        </div>
      </div>
      <CourseHeader
        course="Japanese for Beginners"
        target={target} source={source}
        completed={completed} total={lessons.length} />
      <div style={{
        fontSize: 12, fontWeight: 500, letterSpacing: ".06em",
        textTransform: "uppercase", color: "var(--fg-muted)",
        margin: "16px 4px 8px",
      }}>Lessons</div>
      <div>
        {lessons.map(l => (
          <Row key={l.num} lesson={l} onClick={() => onPickLesson && onPickLesson(l)} />
        ))}
      </div>
    </div>
  );
};

Object.assign(window, { CourseDetailPage, CourseHeader, LessonRowList, LessonRowCard, COURSE_LESSONS });
