// Lesson Complete — celebration screen shown after the last quiz question
// Stats hero + new words list + Next Lesson / Home actions

const StatBadge = ({ icon, value, label, tone = "blue" }) => {
  const tones = {
    blue:   { bg: "var(--color-blue-50)",   fg: "var(--brand-primary)" },
    green:  { bg: "#E8F5E9",                fg: "var(--color-green-600)" },
    purple: { bg: "#F3E5F5",                fg: "var(--color-purple-600)" },
  };
  const t = tones[tone];
  return (
    <div style={{
      flex: 1, background: "#fff", borderRadius: 16, boxShadow: "var(--shadow-card)",
      padding: "16px 12px", textAlign: "center",
      display: "flex", flexDirection: "column", alignItems: "center", gap: 6,
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: "50%", background: t.bg, color: t.fg,
        display: "flex", alignItems: "center", justifyContent: "center",
      }}>
        <Icon name={icon} filled size={20} />
      </div>
      <div style={{ fontSize: 28, fontWeight: 300, color: t.fg, letterSpacing: "-.02em", lineHeight: 1 }}>
        {value}
      </div>
      <div style={{ fontSize: 12, color: "var(--fg-muted)" }}>{label}</div>
    </div>
  );
};

const NewWordRow = ({ word, translit, translation }) => (
  <div className="recent-item">
    <div>
      <div className="word cjk">{word}</div>
      {translit && (
        <div style={{ fontSize: 12, color: "var(--fg-subtle)", fontStyle: "italic", marginTop: 2 }}>
          {translit}
        </div>
      )}
    </div>
    <div className="translation">{translation}</div>
  </div>
);

const LessonCompletePage = ({ onHome, onNextLesson, stats, newWords }) => {
  const s = stats || { correct: 4, total: 5, xp: 25, streak: 7, accuracy: 80 };
  const words = newWords || [
    { word: "こんにちは", translit: "konnichiwa", translation: "Hello" },
    { word: "ありがとう", translit: "arigatou",   translation: "Thank you" },
    { word: "わたし",    translit: "watashi",    translation: "I / me" },
    { word: "がくせい",  translit: "gakusei",    translation: "Student" },
  ];

  return (
    <div className="page page-lesson-complete">
      {/* Hero */}
      <div style={{
        textAlign: "center", padding: "24px 16px 8px",
      }}>
        <div style={{
          width: 88, height: 88, borderRadius: "50%",
          background: "var(--brand-primary)", color: "#fff",
          display: "inline-flex", alignItems: "center", justifyContent: "center",
          margin: "0 auto 16px",
          boxShadow: "0 8px 24px rgba(25, 118, 210, .35)",
        }}>
          <Icon name="emoji_events" filled size={48} />
        </div>
        <h1 style={{
          fontSize: 28, fontWeight: 300, color: "var(--fg-strong)",
          letterSpacing: "-.02em", margin: 0,
        }}>
          Lesson complete!
        </h1>
        <p style={{ fontSize: 15, color: "var(--fg-muted)", margin: "6px 0 0" }}>
          {s.correct} of {s.total} correct · Great job
        </p>
      </div>

      {/* Stat trio */}
      <div style={{ display: "flex", gap: 10, margin: "20px 0 16px" }}>
        <StatBadge icon="bolt"          value={`+${s.xp}`} label="XP earned"  tone="blue" />
        <StatBadge icon="local_fire_department" value={s.streak} label="Day streak" tone="purple" />
        <StatBadge icon="check_circle"  value={`${s.accuracy}%`} label="Accuracy" tone="green" />
      </div>

      {/* New words */}
      <div className="card">
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          marginBottom: 12,
        }}>
          <h3 className="card-title" style={{ margin: 0 }}>New words learned</h3>
          <span className="chip chip-blue">{words.length}</span>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
          {words.map((w, i) => <NewWordRow key={i} {...w} />)}
        </div>
      </div>

      {/* Actions */}
      <div style={{ display: "flex", flexDirection: "column", gap: 10, marginTop: 8 }}>
        <PrimaryButton onClick={onNextLesson}>
          Next Lesson
        </PrimaryButton>
        <OutlinedButton onClick={onHome}>
          Back to Home
        </OutlinedButton>
      </div>
    </div>
  );
};

Object.assign(window, { LessonCompletePage, StatBadge, NewWordRow });
