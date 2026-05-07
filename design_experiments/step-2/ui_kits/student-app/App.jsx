// App shell — orchestrates routing between Home / Courses / Progress / Quiz

const App = () => {
  const [tab, setTab] = React.useState("home");
  const [inQuiz, setInQuiz] = React.useState(false);
  const [showComplete, setShowComplete] = React.useState(false);
  const [courseDetail, setCourseDetail] = React.useState(null); // null | 'list' | 'cards'
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
        {showComplete ? (
          <LessonCompletePage
            onHome={() => { setShowComplete(false); setTab("home"); }}
            onNextLesson={() => { setShowComplete(false); setInQuiz(true); }}
          />
        ) : inQuiz ? (
          <QuizPage
            onExit={() => setInQuiz(false)}
            onFinish={() => { setInQuiz(false); setShowComplete(true); }}
          />
        ) : courseDetail ? (
          <CourseDetailPage
            variant={courseDetail}
            onBack={() => setCourseDetail(null)}
            onPickLesson={() => { setCourseDetail(null); setInQuiz(true); }}
            onSwitchCourse={() => { setCourseDetail(null); setTab("courses"); }}
          />
        ) : (
          <>
            {tab === "home" && (
              <HomePage
                options={options} setOption={setOption}
                onStartQuiz={() => setInQuiz(true)}
                onOpenCourse={() => setCourseDetail("list")}
                onOpenDemos={() => setInQuiz(true)}
                onOpenProgress={() => setTab("progress")}
                sentenceCount={12} totalCount={234} />
            )}
            {tab === "courses" && <CoursesPage onPickCourse={() => setCourseDetail("cards")} />}
            {tab === "progress" && <ProgressPage />}
            {!showComplete && <BottomNav active={tab} onChange={setTab} />}
          </>
        )}
      </div>
    </div>
  );
};

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
