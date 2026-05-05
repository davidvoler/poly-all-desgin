// App shell — orchestrates routing between Home / Courses / Progress / Quiz

const App = () => {
  const [tab, setTab] = React.useState("home");
  const [inQuiz, setInQuiz] = React.useState(false);
  const [options, setOptions] = React.useState({
    showText: true,
    autoPlay: true,
    translit: false,
  });
  const setOption = (k, v) => setOptions(o => ({ ...o, [k]: v }));

  return (
    <div className="phone-frame">
      <div className="phone-screen">
        <StatusBar />
        {inQuiz ? (
          <QuizPage onExit={() => setInQuiz(false)} />
        ) : (
          <>
            {tab === "home" && (
              <HomePage
                options={options} setOption={setOption}
                onStartQuiz={() => setInQuiz(true)}
                onOpenDemos={() => setInQuiz(true)}
                sentenceCount={12} totalCount={234} />
            )}
            {tab === "courses" && <CoursesPage onPickCourse={() => setInQuiz(true)} />}
            {tab === "progress" && <ProgressPage />}
            <BottomNav active={tab} onChange={setTab} />
          </>
        )}
      </div>
    </div>
  );
};

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
