// Home screen — language card, learning options, questions today, demos CTA

const LanguageCard = ({ source, target, progressPercent }) => (
  <div className="card">
    <div className="lang-card-header">
      <span className="flag">{target.flag}</span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="name">{target.name}</div>
        <div className="native" style={{ fontFamily: target.font }}>{target.native}</div>
      </div>
      <span className="arrow">→</span>
      <span className="flag" style={{ fontSize: 24 }}>{source.flag}</span>
    </div>
    <div style={{ display: "flex", justifyContent: "space-between", fontSize: 13, color: "var(--fg-muted)", marginBottom: 6 }}>
      <span>Progress</span>
      <span>{progressPercent}%</span>
    </div>
    <ProgressBar value={progressPercent} />
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
      <div style={{ fontSize: 36, fontWeight: 700, color: "var(--brand-primary)", lineHeight: 1, marginTop: 4 }}>{count}</div>
      <div style={{ fontSize: 12, color: "var(--fg-muted)", marginTop: 4 }}>{total} total questions</div>
    </div>
    <div style={{ width: 64, height: 64, borderRadius: "50%", background: "var(--color-blue-50)",
      display: "flex", alignItems: "center", justifyContent: "center" }}>
      <Icon name="quiz" filled size={32} style={{ color: "var(--brand-primary)" }} />
    </div>
  </div>
);

const HomePage = ({ options, setOption, onStartQuiz, onOpenDemos, sentenceCount, totalCount }) => {
  const target = { flag: "🇯🇵", name: "Japanese", native: "日本語", font: "var(--font-cjk)" };
  const source = { flag: "🇺🇸", name: "English", native: "English", font: "var(--font-latin)" };
  return (
    <div className="page page-home">
      <div className="page-header">
        <h1 className="page-title">Listen &amp; Learn</h1>
        <p className="page-subtitle">Improve language through understanding</p>
      </div>
      <LanguageCard source={source} target={target} progressPercent={45} />
      <QuestionsTodayCard count={sentenceCount} total={totalCount} />
      <LearningOptionsCard options={options} setOption={setOption} />
      <PrimaryButton onClick={onStartQuiz} style={{ marginBottom: 12 }}>Start Learning</PrimaryButton>
      <OutlinedButton onClick={onOpenDemos}>
        <Icon name="play_circle" filled /> See Question Type Demos
      </OutlinedButton>
      <div style={{ display: "flex", justifyContent: "center", marginTop: 12 }}>
        <NoticePill>Using local questions</NoticePill>
      </div>
    </div>
  );
};

Object.assign(window, { LanguageCard, LearningOptionsCard, QuestionsTodayCard, HomePage });
