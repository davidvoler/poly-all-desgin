// Home screen — language card, learning options, questions today, demos CTA

const LanguageCard = ({ source, target, progressPercent, courseName, lessonName, lessonNumber, onStart, onOpenCourse }) => (
  <div className="card">
    {courseName && (
      <div style={{
        fontSize: 12, fontWeight: 500, letterSpacing: "0.08em",
        textTransform: "uppercase", color: "var(--brand-primary)",
        marginBottom: 4
      }}>Current Course</div>
    )}
    {courseName && (
      <h2
        onClick={onOpenCourse}
        style={{
          fontSize: 22, fontWeight: 400, color: "var(--fg-strong)",
          margin: "0 0 12px 0", lineHeight: 1.2, letterSpacing: "-.01em",
          cursor: onOpenCourse ? "pointer" : "default",
        }}>{courseName}</h2>
    )}
    {lessonName && (
      <div style={{
        display: "flex", alignItems: "center", gap: 8,
        padding: "10px 12px", marginBottom: 16,
        background: "var(--color-blue-50)", borderRadius: 10,
      }}>
        <Icon name="play_circle" filled size={18} style={{ color: "var(--brand-primary)", flexShrink: 0 }} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 11, color: "var(--brand-primary)", fontWeight: 500, letterSpacing: ".05em", textTransform: "uppercase" }}>
            {lessonNumber ? `Lesson ${lessonNumber} · Up next` : "Up next"}
          </div>
          <div style={{ fontSize: 14, fontWeight: 500, color: "var(--fg-strong)", marginTop: 1, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
            {lessonName}
          </div>
        </div>
      </div>
    )}
    <div className="lang-card-header">
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="name">{target.name}</div>
        <div className="native" style={{ fontFamily: target.font }}>{target.native}</div>
      </div>
      <span className="arrow">→</span>
      <div style={{ textAlign: "right" }}>
        <div className="name" style={{ fontSize: 14, color: "var(--fg-muted)", fontWeight: 500 }}>{source.name}</div>
      </div>
    </div>
    <div style={{ display: "flex", justifyContent: "space-between", fontSize: 13, color: "var(--fg-muted)", marginBottom: 6 }}>
      <span>Progress</span>
      <span>{progressPercent}%</span>
    </div>
    <ProgressBar value={progressPercent} />
    {onStart && (
      <PrimaryButton onClick={onStart} style={{ marginTop: 16 }}>Start Learning</PrimaryButton>
    )}
  </div>
);

const LearningOptionsCard = ({ options, setOption }) => (
  <div className="card">
    <h3 className="card-title">Learning Options</h3>
    <ToggleRow
      icon="visibility" color="var(--accent-show-text)"
      title="Show Text" sub="Display written text with audio"
      on={options.showText} onChange={v => setOption("showText", v)} />
    <ToggleRow
      icon="volume_up" color="var(--accent-auto-play)"
      title="Auto Play" sub="Play audio automatically"
      on={options.autoPlay} onChange={v => setOption("autoPlay", v)} />
    <ToggleRow
      icon="text_fields" color="var(--accent-translit)"
      title="Transliteration" sub="Show pronunciation guide"
      on={options.translit} onChange={v => setOption("translit", v)} />
  </div>
);

const QuestionsTodayCard = ({ count, total }) => (
  <div className="card-compact" style={{ marginBottom: 16, display: "flex", alignItems: "center", gap: 16 }}>
    <div style={{ flex: 1 }}>
      <div style={{ fontSize: 14, color: "var(--fg-muted)" }}>Questions Today</div>
      <div style={{ fontSize: 36, fontWeight: 300, color: "var(--brand-primary)", lineHeight: 1, marginTop: 4, letterSpacing: "-.02em" }}>{count}</div>
      <div style={{ fontSize: 12, color: "var(--fg-muted)", marginTop: 4 }}>{total} total questions</div>
    </div>
    <div style={{ width: 64, height: 64, borderRadius: "50%", background: "var(--color-blue-50)",
      display: "flex", alignItems: "center", justifyContent: "center" }}>
      <Icon name="quiz" filled size={32} style={{ color: "var(--brand-primary)" }} />
    </div>
  </div>
);

const ProgressMiniCard = ({ stats, onOpenProgress }) => (
  <div className="card" style={{ marginBottom: 16 }}>
    <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 16 }}>
      <h3 className="card-title" style={{ margin: 0 }}>Your Progress</h3>
      {onOpenProgress && (
        <button onClick={onOpenProgress} style={{
          background: "transparent", border: "none", padding: 0, cursor: "pointer",
          fontSize: 13, fontWeight: 500, color: "var(--brand-primary)",
          display: "inline-flex", alignItems: "center", gap: 2,
        }}>
          See all
          <Icon name="chevron_right" size={16} />
        </button>
      )}
    </div>
    <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12, marginBottom: 16 }}>
      {stats.map((s, i) => (
        <div key={i} style={{ textAlign: "left" }}>
          <div style={{
            fontSize: 28, fontWeight: 300, lineHeight: 1, letterSpacing: "-.02em",
            color: s.color || "var(--brand-primary)",
          }}>{s.value}</div>
          <div style={{ fontSize: 12, color: "var(--fg-muted)", marginTop: 6, fontWeight: 500 }}>{s.label}</div>
        </div>
      ))}
    </div>
    <div style={{ display: "flex", justifyContent: "space-between", fontSize: 13, color: "var(--fg-muted)", marginBottom: 6 }}>
      <span>Weekly goal</span>
      <span>3 / 5 days</span>
    </div>
    <ProgressBar value={60} />
  </div>
);

const HomePage = ({ options, setOption, onStartQuiz, onOpenDemos, onOpenProgress, onOpenCourse, sentenceCount, totalCount }) => {
  const target = { flag: "🇯🇵", name: "Japanese", native: "日本語", font: "var(--font-cjk)" };
  const source = { flag: "🇺🇸", name: "English", native: "English", font: "var(--font-latin)" };
  const progressStats = [
    { value: sentenceCount, label: "Today",   color: "var(--brand-primary)" },
    { value: totalCount,    label: "Total",   color: "var(--state-success-icon)" },
    { value: 5,             label: "Day streak", color: "var(--accent-translit)" },
  ];
  return (
    <div className="page page-home">
      <div className="page-header">
        <h1 className="page-title">Listen &amp; Learn</h1>
        <p className="page-subtitle">Improve language through understanding</p>
      </div>
      <LanguageCard source={source} target={target} progressPercent={45} courseName="Japanese for Beginners" lessonName="Greetings & Introductions" lessonNumber={3} onStart={onStartQuiz} onOpenCourse={onOpenCourse} />
      <ProgressMiniCard stats={progressStats} onOpenProgress={onOpenProgress} />
    </div>
  );
};

Object.assign(window, { LanguageCard, LearningOptionsCard, QuestionsTodayCard, ProgressMiniCard, HomePage });
