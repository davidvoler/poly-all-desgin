(function () {
  const grid = document.getElementById('courseGrid');
  const newCourseCard = document.getElementById('newCourseCard');
  const modal = document.getElementById('createModal');
  const form = document.getElementById('createForm');
  const cancelBtn = document.getElementById('cancelCreate');
  const levelPicker = document.getElementById('levelPicker');
  const langOptions = document.getElementById('langOptions');

  langOptions.innerHTML = LANG_SUGGESTIONS.map((l) => `<option value="${l}">`).join('');
  levelPicker.innerHTML = LEVELS.map(
    (lvl, i) => `
    <label>
      <input type="radio" name="level" value="${lvl}" ${i === 0 ? 'checked' : ''} />
      ${lvl}
    </label>`
  ).join('');

  function timeAgo(ts) {
    const mins = Math.round((Date.now() - ts) / 60000);
    if (mins < 1) return 'just now';
    if (mins < 60) return `${mins}m ago`;
    const hrs = Math.round(mins / 60);
    if (hrs < 24) return `${hrs}h ago`;
    return `${Math.round(hrs / 24)}d ago`;
  }

  function render() {
    const courses = CourseStore.all().slice().sort((a, b) => b.updatedAt - a.updatedAt);
    grid.querySelectorAll('.course-card').forEach((el) => el.remove());
    courses.forEach((course) => {
      const from = langInfo(course.lang);
      const to = langInfo(course.toLang);
      const a = document.createElement('a');
      a.className = 'glass course-card';
      a.href = `course.html?course=${encodeURIComponent(course.id)}`;
      a.innerHTML = `
        <div class="flags">${from.flag}${to.flag}</div>
        <h3>${course.title}</h3>
        <div class="pair">${from.name} → ${to.name}</div>
        <div class="meta-row">
          <span class="pill level">${course.level}</span>
          <span class="progress">${CourseStore.progressLabel(course)}</span>
        </div>
        <div class="updated">Updated ${timeAgo(course.updatedAt)}</div>
      `;
      grid.insertBefore(a, newCourseCard);
    });
  }

  newCourseCard.addEventListener('click', () => { modal.hidden = false; });
  cancelBtn.addEventListener('click', () => { modal.hidden = true; });
  modal.addEventListener('click', (e) => { if (e.target === modal) modal.hidden = true; });

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const data = new FormData(form);
    const course = CourseStore.create({
      title: data.get('title'),
      lang: data.get('lang'),
      toLang: data.get('toLang'),
      level: data.get('level'),
    });
    window.location.href = `course.html?course=${encodeURIComponent(course.id)}`;
  });

  render();
})();
