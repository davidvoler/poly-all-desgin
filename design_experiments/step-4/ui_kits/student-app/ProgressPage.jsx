// Progress screen — total questions stat, recent words, recent sentences

const StatCard = ({ value, label, color }) => (
  <div className="stat-card">
    <div className={"stat-number " + (color || "")}>{value}</div>
    <div className="stat-label">{label}</div>
  </div>
);

const RecentItem = ({ word, translation, cjk = false }) => (
  <div className="recent-item">
    <span className={"word" + (cjk ? " cjk" : "")}>{word}</span>
    <span className="translation">{translation}</span>
  </div>
);

const ProgressPage = () => {
  const recentWords = [
    { word: "こんにちは", translation: "hello", cjk: true },
    { word: "ありがとう", translation: "thank you", cjk: true },
    { word: "おはよう", translation: "good morning", cjk: true },
    { word: "さようなら", translation: "goodbye", cjk: true },
  ];
  const recentSentences = [
    { word: "お元気ですか？", translation: "How are you?", cjk: true },
    { word: "私は学生です。", translation: "I am a student.", cjk: true },
    { word: "水をください。", translation: "Water, please.", cjk: true },
  ];
  return (
    <div className="page page-progress">
      <div className="page-header">
        <h1 className="page-title">Your Progress</h1>
        <p className="page-subtitle">Japanese</p>
      </div>
      <StatCard value="234" label="Total Questions" color="green" />
      <div className="stat-row">
        <div className="stat-card"><div className="stat-number">12</div><div className="stat-label">Today</div></div>
        <div className="stat-card"><div className="stat-number purple">3</div><div className="stat-label">Last Quiz Score</div></div>
      </div>
      <div className="card">
        <h3 className="card-title">Words You've Learned</h3>
        <div className="recent-list">
          {recentWords.map((w, i) => <RecentItem key={i} {...w} />)}
        </div>
      </div>
      <div className="card">
        <h3 className="card-title">Sentences You've Practiced</h3>
        <div className="recent-list">
          {recentSentences.map((w, i) => <RecentItem key={i} {...w} />)}
        </div>
      </div>
    </div>
  );
};

Object.assign(window, { StatCard, RecentItem, ProgressPage });
