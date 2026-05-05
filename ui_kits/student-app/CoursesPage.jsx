// Courses screen — list of courses for the active target language

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
  const courses = [
    { id: "jp-greet", title: "Greetings & Introductions", modules: 3, lessons: 12 },
    { id: "jp-hira", title: "Hiragana Foundations", modules: 5, lessons: 24 },
    { id: "jp-kata", title: "Katakana Foundations", modules: 5, lessons: 24 },
    { id: "jp-kanji", title: "Essential Kanji", modules: 8, lessons: 36 },
    { id: "jp-travel", title: "Travel Phrases", modules: 4, lessons: 16 },
    { id: "jp-food", title: "At the Restaurant", modules: 2, lessons: 8 },
  ];
  return (
    <div className="page page-courses">
      <div className="page-header" style={{ padding: "16px 8px" }}>
        <h1 className="page-title" style={{ fontSize: 24 }}>Courses</h1>
        <p className="page-subtitle" style={{ fontSize: 14 }}>🇯🇵 Japanese</p>
      </div>
      {courses.map(c => <CourseRow key={c.id} course={c} onClick={() => onPickCourse(c)} />)}
    </div>
  );
};

Object.assign(window, { CourseRow, CoursesPage });
