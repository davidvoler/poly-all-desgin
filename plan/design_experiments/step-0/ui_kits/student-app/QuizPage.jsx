// Quiz player — header, audio controls, three quiz types

const QuizHeader = ({ current, total, onBack }) => (
  <div className="quiz-header">
    <div className="row1">
      <button className="icon-btn" onClick={onBack}><Icon name="arrow_back" /></button>
      <span className="title">Quiz</span>
      <span className="count">{current} of {total}</span>
    </div>
    <ProgressBar value={(current / total) * 100} />
  </div>
);

const AudioControls = ({ showText, sentence, onReveal }) => {
  const [playing, setPlaying] = React.useState(false);
  return (
    <div>
      <div className="audio-controls">
        <button className="audio-btn" title="Slow"><Icon name="slow_motion_video" /></button>
        <button className="audio-btn primary" onClick={() => setPlaying(p => !p)} title="Play">
          <Icon name={playing ? "pause" : "play_arrow"} filled />
        </button>
      </div>
      {!showText && (
        <div style={{ textAlign: "center", marginTop: 8 }}>
          <button className="btn btn-text" onClick={onReveal} style={{ margin: "0 auto" }}>
            <Icon name="visibility" /> Reveal text
          </button>
        </div>
      )}
    </div>
  );
};

const AnswerTile = ({ children, state, onClick, marker }) => (
  <button className={"answer-tile" + (state ? " " + state : "")} onClick={onClick}>
    <span className="marker">{marker}</span>
    <span>{children}</span>
  </button>
);

// Quiz type 1: translate this sentence (single choice)
const TranslateQuestion = ({ q, selected, submitted, onSelect }) => {
  return (
    <div className="quiz-question-card">
      <p className="quiz-instruction">Translate this sentence</p>
      <div className="quiz-sentence quiz-sentence-jp">{q.sentence}</div>
      {q.translit && <div className="quiz-translit">{q.translit}</div>}
      <AudioControls showText={true} />
      <div style={{ marginTop: 16 }}>
        {q.choices.map((c, i) => {
          let state = "";
          if (submitted) {
            if (i === q.answer) state = "correct";
            else if (i === selected) state = "incorrect";
          } else if (i === selected) state = "selected";
          const marker = state === "correct" ? "✓" : state === "incorrect" ? "✕" : state === "selected" ? "●" : "○";
          return (
            <AnswerTile key={i} state={state} marker={marker} onClick={() => !submitted && onSelect(i)}>
              {c}
            </AnswerTile>
          );
        })}
      </div>
    </div>
  );
};

// Quiz type 2: identify words you hear (multi-select)
const IdentifyWordsQuestion = ({ q, selected, submitted, onToggle }) => {
  return (
    <div className="quiz-question-card">
      <p className="quiz-instruction">Listen and tap the words you hear.</p>
      <AudioControls showText={false} sentence={q.sentence} />
      <div style={{ display: "flex", flexWrap: "wrap", gap: 10, marginTop: 24, justifyContent: "center" }}>
        {q.words.map((w, i) => {
          const isSel = selected.includes(i);
          const isCorrect = q.correct.includes(i);
          let state = "";
          if (submitted) {
            if (isCorrect && isSel) state = "correct";
            else if (!isCorrect && isSel) state = "incorrect";
            else if (isCorrect && !isSel) state = "correct";
          } else if (isSel) state = "selected";
          return (
            <button
              key={i}
              className={"answer-tile" + (state ? " " + state : "")}
              style={{ width: "auto", padding: "12px 18px", margin: 0, fontSize: 18 }}
              onClick={() => !submitted && onToggle(i)}>
              <span style={{ fontFamily: "var(--font-cjk)" }}>{w}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
};

// Quiz type 3: memory cards
const MemoryQuestion = () => {
  const pairs = [["あ","a"],["い","i"],["う","u"],["え","e"]];
  const initial = pairs.flatMap(([k, v], idx) => [
    { id: `${idx}-k`, pairId: idx, label: k, cjk: true },
    { id: `${idx}-v`, pairId: idx, label: v, cjk: false },
  ]).sort(() => 0.5 - Math.random());
  const [cards] = React.useState(initial);
  const [revealed, setRevealed] = React.useState(new Set([cards[0].id, cards[3].id]));
  const [matched] = React.useState(new Set([cards[1].id, cards[5].id]));

  return (
    <div className="quiz-question-card">
      <p className="quiz-instruction">Flip two cards at a time. Matched pairs stay visible.</p>
      <div style={{ textAlign: "center", color: "var(--fg-muted)", margin: "8px 0 16px", fontSize: 14 }}>
        Pairs found: 1 / 4
      </div>
      <div className="memory-grid">
        {cards.map(c => {
          const isRev = revealed.has(c.id);
          const isMatched = matched.has(c.id);
          const cls = "memory-card" + (isMatched ? " matched" : isRev ? " revealed" : "");
          return (
            <div key={c.id} className={cls} style={!c.cjk ? { fontFamily: "var(--font-latin)" } : undefined}
              onClick={() => setRevealed(r => { const n = new Set(r); n.has(c.id) ? n.delete(c.id) : n.add(c.id); return n; })}>
              {(isRev || isMatched) ? c.label : "?"}
            </div>
          );
        })}
      </div>
    </div>
  );
};

const QuizPage = ({ onExit }) => {
  const questions = [
    { type: "translate",
      sentence: "こんにちは",
      translit: "konnichiwa",
      choices: ["Goodbye", "Hello", "Thank you", "Good morning"],
      answer: 1 },
    { type: "identify",
      sentence: "わたし は がくせい です",
      words: ["わたし", "あなた", "がくせい", "せんせい", "です", "ます", "は", "を"],
      correct: [0, 2, 4, 6] },
    { type: "memory" },
  ];
  const [idx, setIdx] = React.useState(0);
  const q = questions[idx];
  const [selected, setSelected] = React.useState(q.type === "identify" ? [] : null);
  const [submitted, setSubmitted] = React.useState(false);

  const reset = (newIdx) => {
    const nq = questions[newIdx];
    setSelected(nq.type === "identify" ? [] : null);
    setSubmitted(false);
    setIdx(newIdx);
  };

  const isLast = idx === questions.length - 1;
  const canCheck = q.type === "translate" ? selected !== null
    : q.type === "identify" ? selected.length > 0
    : true;

  return (
    <div className="page page-quiz">
      <QuizHeader current={idx + 1} total={questions.length} onBack={onExit} />
      {q.type === "translate" && (
        <TranslateQuestion q={q} selected={selected} submitted={submitted}
          onSelect={i => setSelected(i)} />
      )}
      {q.type === "identify" && (
        <IdentifyWordsQuestion q={q} selected={selected} submitted={submitted}
          onToggle={i => setSelected(s => s.includes(i) ? s.filter(x => x !== i) : [...s, i])} />
      )}
      {q.type === "memory" && <MemoryQuestion />}

      {!submitted && q.type !== "memory" && (
        <PrimaryButton onClick={() => setSubmitted(true)} disabled={!canCheck}>
          Check Answer
        </PrimaryButton>
      )}
      {submitted && !isLast && (
        <PrimaryButton onClick={() => reset(idx + 1)}>Next Question</PrimaryButton>
      )}
      {(submitted && isLast) && (
        <PrimaryButton onClick={onExit}>Finish Quiz</PrimaryButton>
      )}
      {q.type === "memory" && (
        <PrimaryButton onClick={() => reset(idx + 1 < questions.length ? idx + 1 : 0)}>
          {idx + 1 < questions.length ? "Next Question" : "New Quiz"}
        </PrimaryButton>
      )}
    </div>
  );
};

Object.assign(window, { QuizHeader, AudioControls, AnswerTile, TranslateQuestion, IdentifyWordsQuestion, MemoryQuestion, QuizPage });
