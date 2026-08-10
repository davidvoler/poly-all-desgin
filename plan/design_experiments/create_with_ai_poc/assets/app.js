(function () {
  const params = new URLSearchParams(window.location.search);
  let course = CourseStore.get(params.get('course')) || CourseStore.all()[0];
  if (!course) { window.location.href = 'index.html'; return; }
  if (course.id !== params.get('course')) {
    const url = new URL(window.location.href);
    url.searchParams.set('course', course.id);
    window.history.replaceState({}, '', url);
  }

  // Migrate courses saved before modules/usage existed.
  if (!course.modules) course.modules = [];
  if (!course.usage) course.usage = { tokens: 0, cost: 0 };
  if (course.lessons.length && course.modules.length === 0) {
    const mod = { id: nextId('mod'), title: 'Module 1' };
    course.modules.push(mod);
    course.lessons.forEach((l) => { l.moduleId = mod.id; });
    CourseStore.save(course);
  }

  let activeTab = course.workTab || 'words';
  // Sentence rows default to read-only text with an edit-pencil toggle;
  // this tracks which ones are mid-edit. UI-only, not persisted.
  const editingSentences = new Set();

  const el = {
    chatTitle: document.getElementById('chatCourseTitle'),
    chatSub: document.getElementById('chatCourseSub'),
    chatUsage: document.getElementById('chatUsage'),
    chatScroll: document.getElementById('chatScroll'),
    chatForm: document.getElementById('chatForm'),
    chatText: document.getElementById('chatText'),
    workTabs: document.getElementById('workTabs'),
    workScroll: document.getElementById('workScroll'),
  };

  function save() { CourseStore.save(course); }
  function findLesson(id) { return course.lessons.find((l) => l.id === id); }
  function escapeHtml(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }

  /** ids of every word already selected into at least one lesson. */
  function usedWordIds() {
    const s = new Set();
    course.lessons.forEach((l) => l.wordIds.forEach((id) => s.add(id)));
    return s;
  }

  function courseStats() {
    return {
      words: course.words.length,
      modules: course.modules.length,
      lessons: course.lessons.length,
      ready: course.lessons.filter((l) => l.status === 'ready').length,
      exercises: course.lessons.reduce((n, l) => n + l.exercises.length, 0),
    };
  }

  /** Roll a generation call's fake usage into the course total and return
   * it so the triggering chat message can show its own line too. */
  function addUsage(unitCount) {
    const u = mockUsage(unitCount);
    course.usage.tokens += u.tokens;
    course.usage.cost += u.cost;
    return u;
  }

  // ---------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------
  function renderChatHeader() {
    const from = langInfo(course.lang);
    const to = langInfo(course.toLang);
    el.chatTitle.textContent = `${from.flag} ${course.title}`;
    el.chatSub.textContent = `${from.name} → ${to.name} · Level ${course.level}`;
    el.chatUsage.textContent = course.usage.tokens
      ? `≈${course.usage.tokens.toLocaleString()} tokens · $${course.usage.cost.toFixed(4)}`
      : '';
  }

  function pushMessage(msg) {
    course.chat.push(Object.assign({ id: nextId('m') }, msg));
    save();
    renderChat();
    renderChatHeader();
  }

  function appendUser(text) { pushMessage({ role: 'user', text }); }
  function appendAssistant(text, extra) { pushMessage(Object.assign({ role: 'assistant', text }, extra || {})); }

  function simulateThinking(cb) {
    const typing = document.createElement('div');
    typing.className = 'msg assistant';
    typing.innerHTML = `<div class="avatar">AI</div><div class="msg-body"><div class="bubble typing"><i></i><i></i><i></i></div></div>`;
    el.chatScroll.appendChild(typing);
    el.chatScroll.scrollTop = el.chatScroll.scrollHeight;
    setTimeout(() => {
      typing.remove();
      cb();
    }, 550 + Math.random() * 400);
  }

  function renderChat() {
    el.chatScroll.innerHTML = course.chat.map(renderMessage).join('');
    el.chatScroll.scrollTop = el.chatScroll.scrollHeight;
    wireChatInteractions();
  }

  function renderMessage(msg) {
    const isUser = msg.role === 'user';
    const avatar = isUser ? 'You' : 'AI';
    let inner = `<div class="bubble">${escapeHtml(msg.text)}</div>`;

    if (msg.usage) {
      inner += `<div class="msg-note">≈${msg.usage.tokens.toLocaleString()} tokens · $${msg.usage.cost.toFixed(4)}</div>`;
    }

    if (msg.actions && msg.actions.length) {
      inner += `<div class="msg-actions">${msg.actions
        .map((a) => `<button class="btn btn-ghost btn-sm" data-action="${a.id}" data-lesson="${a.lessonId || ''}" ${a.newModule ? 'data-newmodule="1"' : ''}>${escapeHtml(a.label)}</button>`)
        .join('')}</div>`;
    }

    if (msg.picker) {
      inner += renderPicker(msg);
    }
    if (msg.frozenPicker) {
      inner += renderFrozenPicker(msg.frozenPicker);
    }

    return `<div class="msg ${isUser ? 'user' : 'assistant'}"><div class="avatar">${avatar}</div><div class="msg-body">${inner}</div></div>`;
  }

  function renderPicker(msg) {
    const p = msg.picker;
    const rows = p.items
      .map(
        (it) => `
        <label class="picker-row ${it.used ? 'used' : ''}">
          <input type="checkbox" data-picker-item="${it.id}" ${it.checked ? 'checked' : ''} />
          <span class="w">${escapeHtml(it.label)}</span>
          <span class="g">${escapeHtml(it.sub || '')}</span>
        </label>`
      )
      .join('');
    return `
      <div class="picker" data-picker-message="${msg.id}">
        ${rows}
        <div class="picker-foot">
          <button type="button" class="btn btn-primary btn-sm" data-confirm-picker="${msg.id}">${escapeHtml(p.confirmLabel)}</button>
        </div>
      </div>`;
  }

  function renderFrozenPicker(fp) {
    const rows = fp.items
      .filter((it) => it.checked)
      .map((it) => `
        <label class="picker-row" style="opacity:0.6; cursor:default;">
          <input type="checkbox" checked disabled />
          <span class="w">${escapeHtml(it.label)}</span>
          <span class="g">${escapeHtml(it.sub || '')}</span>
        </label>`)
      .join('');
    return `<div class="picker">${rows}</div>`;
  }

  function wireChatInteractions() {
    el.chatScroll.querySelectorAll('button[data-action]').forEach((btn) => {
      btn.addEventListener('click', () => handleAction(btn.dataset.action, btn.dataset.lesson || null, btn.dataset.newmodule === '1'));
    });
    el.chatScroll.querySelectorAll('button[data-confirm-picker]').forEach((btn) => {
      btn.addEventListener('click', () => confirmPicker(btn.dataset.confirmPicker));
    });
  }

  function confirmPicker(messageId) {
    const msg = course.chat.find((m) => m.id === messageId);
    if (!msg || !msg.picker) return;
    const container = el.chatScroll.querySelector(`[data-picker-message="${messageId}"]`);
    const selectedIds = Array.from(container.querySelectorAll('input[data-picker-item]:checked')).map((i) => i.dataset.pickerItem);
    const { kind, lessonId, items } = msg.picker;

    msg.frozenPicker = { items: items.map((it) => ({ ...it, checked: selectedIds.includes(it.id) })) };
    delete msg.picker;
    save();

    if (kind === 'words') confirmWords(lessonId, selectedIds);
    else if (kind === 'sentences') confirmSentences(lessonId, selectedIds);
  }

  // ---------------------------------------------------------------
  // The chat "state machine" — every purposeful action a user (or the
  // quick-action buttons) can trigger. There's no real backend here:
  // each branch calls the mock generators in store.js directly.
  // ---------------------------------------------------------------
  function handleAction(actionId, lessonId, newModule) {
    if (actionId === 'create_words') return doCreateWords();
    if (actionId === 'new_lesson') return doNewLesson(newModule);
    if (actionId === 'create_sentences') return doCreateSentences(lessonId);
    if (actionId === 'create_exercises_direct') return doCreateExercisesDirect(lessonId);
    if (actionId === 'preview_course') return doPreview();
  }

  function doCreateWords() {
    appendUser(course.words.length ? 'Add more words' : 'Create word list');
    simulateThinking(() => {
      const words = generateWords(course.lang, course.words, 12);
      course.words.push(...words);
      save();
      renderWork();
      if (!words.length) {
        appendAssistant("That's every word I've got for this demo language — try selecting words for a lesson instead.", {
          actions: [{ id: 'new_lesson', label: `Select words for Lesson ${course.lessons.length + 1}` }],
        });
        return;
      }
      const usage = addUsage(words.length);
      appendAssistant(`Generated ${words.length} starter words (${course.words.length} total). Review them in the Words tab, then let's build a lesson.`, {
        usage,
        actions: [
          { id: 'new_lesson', label: `Select words for Lesson ${course.lessons.length + 1}` },
          { id: 'create_words', label: 'Add more words' },
        ],
      });
    });
  }

  function doNewLesson(newModule) {
    let mod = course.modules[course.modules.length - 1];
    if (newModule || !mod) {
      mod = { id: nextId('mod'), title: `Module ${course.modules.length + 1}` };
      course.modules.push(mod);
    }
    const n = course.lessons.length + 1;
    const lesson = { id: nextId('l'), moduleId: mod.id, title: `Lesson ${n}`, status: 'draft', wordIds: [], sentences: [], exercises: [] };
    course.lessons.push(lesson);
    save();
    renderWork();
    appendUser(`Select words for ${lesson.title}${newModule ? ` (${mod.title})` : ''}`);
    simulateThinking(() => {
      // Words not yet used in any lesson come first and are pre-checked —
      // "next" words to teach, per the picker's own word-usage tracking.
      const used = usedWordIds();
      const ordered = course.words.slice().sort((a, b) => Number(used.has(a.id)) - Number(used.has(b.id)));
      let uncheckedSoFar = 0;
      const items = ordered.map((w) => {
        const isUsed = used.has(w.id);
        const checked = !isUsed && uncheckedSoFar < 6;
        if (checked) uncheckedSoFar++;
        return { id: w.id, label: w.w, sub: isUsed ? `${w.gloss} · used` : w.gloss, used: isUsed, checked };
      });
      appendAssistant(`Pick the words for ${lesson.title} in ${mod.title} — I've pre-selected the next unused ones.`, {
        picker: { kind: 'words', lessonId: lesson.id, items, confirmLabel: 'Confirm selection', confirmAction: 'confirm_words' },
      });
    });
  }

  function confirmWords(lessonId, selectedIds) {
    const lesson = findLesson(lessonId);
    lesson.wordIds = selectedIds;
    save();
    renderWork();
    appendUser(`Confirmed ${selectedIds.length} word${selectedIds.length === 1 ? '' : 's'}`);
    simulateThinking(() => {
      appendAssistant(`Locked in ${selectedIds.length} words for ${lesson.title}. Want me to draft example sentences for them, or jump straight to exercises?`, {
        actions: [
          { id: 'create_sentences', label: 'Create sentences', lessonId },
          { id: 'create_exercises_direct', label: 'Create exercises directly', lessonId },
        ],
      });
    });
  }

  function doCreateSentences(lessonId) {
    appendUser('Create sentences');
    simulateThinking(() => {
      const lesson = findLesson(lessonId);
      const words = course.words.filter((w) => lesson.wordIds.includes(w.id));
      const sentences = generateSentences(words);
      lesson.sentences = sentences;
      save();
      renderWork();
      const items = sentences.map((s) => ({ id: s.id, label: s.text, sub: s.gloss, checked: true }));
      appendAssistant(`Here are draft sentences for ${lesson.title}. Uncheck any you don't want, then I'll turn the rest into exercises.`, {
        picker: { kind: 'sentences', lessonId, items, confirmLabel: 'Create exercises', confirmAction: 'confirm_sentences' },
      });
    });
  }

  function nextStepActions() {
    return [
      { id: 'preview_course', label: 'Preview course' },
      { id: 'new_lesson', label: `Start Lesson ${course.lessons.length + 1}` },
      { id: 'new_lesson', label: 'Start a new module', newModule: true },
    ];
  }

  function doCreateExercisesDirect(lessonId) {
    appendUser('Create exercises directly');
    simulateThinking(() => {
      const lesson = findLesson(lessonId);
      const words = course.words.filter((w) => lesson.wordIds.includes(w.id));
      const sentences = generateSentences(words);
      const exercises = generateExercises(sentences, words);
      lesson.sentences = sentences;
      lesson.exercises = exercises;
      lesson.status = 'ready';
      save();
      renderWork();
      const usage = addUsage(sentences.length + exercises.length);
      appendAssistant(`Done — I drafted sentences and exercises for ${lesson.title} in one go. It's ready. Check the Lessons tab to review or edit, or preview it.`, {
        usage,
        actions: nextStepActions(),
      });
    });
  }

  function confirmSentences(lessonId, selectedIds) {
    const lesson = findLesson(lessonId);
    lesson.sentences.forEach((s) => { s.chosen = selectedIds.includes(s.id); });
    const chosen = lesson.sentences.filter((s) => s.chosen);
    save();
    renderWork();
    appendUser(`Kept ${chosen.length} sentence${chosen.length === 1 ? '' : 's'}`);
    simulateThinking(() => {
      const words = course.words.filter((w) => lesson.wordIds.includes(w.id));
      lesson.exercises = generateExercises(chosen, words);
      lesson.status = 'ready';
      save();
      renderWork();
      const usage = addUsage(lesson.exercises.length);
      appendAssistant(`${lesson.title} is ready 🎉 Review it in the Lessons tab, or switch to Preview to see the student view.`, {
        usage,
        actions: nextStepActions(),
      });
    });
  }

  function doPreview() {
    setActiveTab('preview');
    appendAssistant("Here's what students will see. Switch back to editing anytime using the tabs on the right.");
  }

  el.chatForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const text = el.chatText.value.trim();
    if (!text) return;
    el.chatText.value = '';
    appendUser(text);
    simulateThinking(() => {
      appendAssistant("Got it — noted for the next batch. This POC's free-text box doesn't steer generation yet; the buttons above drive the actual mock content.");
    });
  });
  el.chatText.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); el.chatForm.requestSubmit(); }
  });

  // ---------------------------------------------------------------
  // Right pane: Words / Lessons / Edit Course / Preview tabs
  // ---------------------------------------------------------------
  function setActiveTab(tab) {
    activeTab = tab;
    course.workTab = tab;
    save();
    renderWork();
  }

  el.workTabs.addEventListener('click', (e) => {
    const btn = e.target.closest('button[data-tab]');
    if (!btn) return;
    setActiveTab(btn.dataset.tab);
  });

  function renderWork() {
    el.workTabs.querySelectorAll('button').forEach((b) => b.classList.toggle('on', b.dataset.tab === activeTab));
    el.workScroll.scrollTop = 0;

    if (activeTab === 'preview') { el.workScroll.innerHTML = renderPreview(); return; }
    if (activeTab === 'edit') { el.workScroll.innerHTML = renderEditTab(); wireWorkInteractions(); return; }
    el.workScroll.innerHTML = activeTab === 'lessons' ? renderLessonsTab() : renderWordsTab();
    wireWorkInteractions();
  }

  function renderWordsTab() {
    if (!course.words.length) {
      return `<div class="work-empty">No words yet — ask the AI to create a word list in the chat.</div>`;
    }
    const used = usedWordIds();
    const usedCount = course.words.filter((w) => used.has(w.id)).length;
    const chips = course.words
      .map((w) => {
        const isUsed = used.has(w.id);
        return `<span class="chip ${isUsed ? 'used' : ''}" ${isUsed ? 'title="Already used in a lesson"' : ''}>${isUsed ? '<span class="used-mark">✓</span>' : ''}<span class="w">${escapeHtml(w.w)}</span><span class="g">${escapeHtml(w.gloss)}</span><button data-remove-word="${w.id}" title="Remove">×</button></span>`;
      })
      .join('');
    return `
      <p class="subhead">Course word bank (${course.words.length}) · ${usedCount} used</p>
      <div class="chips">${chips}</div>
      <p class="subhead" style="margin-top:18px;">Add a word manually</p>
      <div class="add-inline">
        <input type="text" id="addWordInput" placeholder="e.g. 猫 — cat" />
        <button class="btn btn-ghost btn-sm" id="addWordBtn">Add</button>
      </div>`;
  }

  function renderSentenceRow(lesson, s) {
    if (editingSentences.has(s.id)) {
      return `
        <div class="edit-row">
          <input type="text" value="${escapeHtml(s.text)}" data-sentence="${lesson.id}:${s.id}" autofocus />
          <button class="del" data-save-sentence="${lesson.id}:${s.id}" title="Done">✓</button>
          <button class="del" data-del-sentence="${lesson.id}:${s.id}" title="Delete">×</button>
        </div>`;
    }
    return `
      <div class="edit-row view">
        <span class="sentence-text">${escapeHtml(s.text)}</span>
        <button class="del" data-edit-sentence="${lesson.id}:${s.id}" title="Edit">✎</button>
        <button class="del" data-del-sentence="${lesson.id}:${s.id}" title="Delete">×</button>
      </div>`;
  }

  function renderLessonBlock(lesson, isCurrent) {
    const words = course.words.filter((w) => lesson.wordIds.includes(w.id));
    const wordChips = words
      .map((w) => `<span class="chip"><span class="w">${escapeHtml(w.w)}</span><button data-remove-lesson-word="${lesson.id}:${w.id}" title="Remove">×</button></span>`)
      .join('') || '<span class="picker-foot">No words selected.</span>';

    const sentenceRows = lesson.sentences.map((s) => renderSentenceRow(lesson, s)).join('') || '<span class="picker-foot">No sentences yet.</span>';

    const exerciseCards = lesson.exercises
      .map((ex) => `
        <div class="exercise-card">
          <div class="kind">${escapeHtml(ex.type.replace(/_/g, ' '))}</div>
          <input type="text" value="${escapeHtml(ex.prompt)}" placeholder="Question / prompt" data-ex-prompt="${lesson.id}:${ex.id}" />
          <div class="exercise-opts">
            ${ex.options
              .map(
                (opt, i) => `
                <div class="exercise-opt">
                  <input type="radio" name="answer-${ex.id}" data-ex-answer="${lesson.id}:${ex.id}:${i}" ${opt && opt === ex.answer ? 'checked' : ''} />
                  <input type="text" value="${escapeHtml(opt)}" placeholder="Option ${i + 1}" data-ex-option="${lesson.id}:${ex.id}:${i}" />
                </div>`
              )
              .join('')}
          </div>
          <div class="exercise-foot">
            <button class="del" data-del-exercise="${lesson.id}:${ex.id}" title="Delete">×</button>
          </div>
        </div>`)
      .join('');

    return `
      <details class="lesson-block" ${isCurrent ? 'open' : ''}>
        <summary>
          <span class="t">${escapeHtml(lesson.title)}</span>
          <span class="pill ${lesson.status === 'ready' ? 'active' : 'draft'}"><span class="swatch"></span>${lesson.status}</span>
          <span class="chev">›</span>
        </summary>
        <div class="lesson-body">
          <div>
            <p class="subhead">Words</p>
            <div class="chips">${wordChips}</div>
          </div>
          <div>
            <p class="subhead">Sentences</p>
            <div style="display:flex; flex-direction:column; gap:6px;">${sentenceRows}</div>
          </div>
          <div>
            <p class="subhead">Exercises</p>
            <div style="display:flex; flex-direction:column; gap:8px;">
              ${exerciseCards}
              <button class="btn btn-ghost btn-sm" style="align-self:flex-start;" data-add-exercise="${lesson.id}">+ Add exercise</button>
            </div>
          </div>
        </div>
      </details>`;
  }

  function renderLessonsTab() {
    if (!course.lessons.length) {
      return `<div class="work-empty">No lessons yet — select words for a lesson in the chat to start one.</div>`;
    }
    const currentLesson = course.lessons[course.lessons.length - 1];
    return course.modules
      .map((mod) => {
        const lessonsInMod = course.lessons.filter((l) => l.moduleId === mod.id);
        if (!lessonsInMod.length) return '';
        const isCurrentModule = lessonsInMod.some((l) => l.id === currentLesson.id);
        const blocks = lessonsInMod.map((lesson) => renderLessonBlock(lesson, lesson.id === currentLesson.id)).join('');
        return `
          <details class="module-block" ${isCurrentModule ? 'open' : ''}>
            <summary>
              <span class="t">${escapeHtml(mod.title)}</span>
              <span class="picker-foot" style="margin:0;">${lessonsInMod.length} lesson${lessonsInMod.length === 1 ? '' : 's'}</span>
              <span class="chev">›</span>
            </summary>
            <div class="module-body">${blocks}</div>
          </details>`;
      })
      .join('');
  }

  function renderEditTab() {
    const langOptions = LANG_SUGGESTIONS.map((l) => `<option value="${l}">`).join('');
    const stats = courseStats();
    return `
      <p class="subhead">Course stats</p>
      <div class="mini-stats">
        <div class="mini-stat"><div class="v">${stats.words}</div><div class="l">Words</div></div>
        <div class="mini-stat"><div class="v">${stats.modules}</div><div class="l">Modules</div></div>
        <div class="mini-stat"><div class="v">${stats.lessons}</div><div class="l">Lessons · ${stats.ready} ready</div></div>
        <div class="mini-stat"><div class="v">${stats.exercises}</div><div class="l">Exercises</div></div>
      </div>
      <p class="subhead" style="margin-top:20px;">Course settings</p>
      <div style="display:grid; gap:14px; max-width:420px;">
        <div class="field">
          <label for="editTitle">Course title</label>
          <input type="text" id="editTitle" value="${escapeHtml(course.title)}" />
        </div>
        <div class="field-row">
          <div class="field">
            <label for="editLang">Learning language</label>
            <input type="text" id="editLang" list="editLangOptions" value="${escapeHtml(course.lang)}" autocomplete="off" />
          </div>
          <div class="field">
            <label for="editToLang">Student language</label>
            <input type="text" id="editToLang" list="editLangOptions" value="${escapeHtml(course.toLang)}" autocomplete="off" />
          </div>
        </div>
        <datalist id="editLangOptions">${langOptions}</datalist>
        <div class="field">
          <label>Level</label>
          <div class="level-picker" id="editLevelPicker">
            ${LEVELS.map((lvl) => `<label><input type="radio" name="editLevel" value="${lvl}" ${lvl === course.level ? 'checked' : ''} />${lvl}</label>`).join('')}
          </div>
        </div>
        <p class="picker-foot">Changes save automatically. Note: editing the learning language doesn't regenerate words already on the course.</p>
      </div>`;
  }

  function renderPreview() {
    const from = langInfo(course.lang);
    const to = langInfo(course.toLang);
    const lessons = course.lessons
      .map((lesson) => {
        const sentences = lesson.sentences
          .filter((s) => s.chosen !== false)
          .map((s) => `<div class="preview-sentence">${escapeHtml(s.text)}<span class="gloss">${escapeHtml(s.gloss)}</span></div>`)
          .join('');
        const exercises = lesson.exercises
          .map(
            (ex) => `
            <div class="preview-quiz">
              <div class="q">${escapeHtml(ex.prompt)}</div>
              ${ex.options
                .map((opt) => `<div class="opt ${opt === ex.answer ? 'correct' : ''}"><span class="ck"></span>${escapeHtml(opt)}</div>`)
                .join('')}
            </div>`
          )
          .join('');
        return `
          <div class="preview-lesson">
            <h4>${escapeHtml(lesson.title)}</h4>
            ${sentences || '<div class="picker-foot">No sentences yet.</div>'}
            ${exercises}
          </div>`;
      })
      .join('');

    return `
      <div class="preview-course-head">
        <div class="flags">${from.flag}${to.flag}</div>
        <h2>${escapeHtml(course.title)}</h2>
        <div class="sub">${from.name} → ${to.name} · Level ${course.level} · ${course.words.length} words</div>
      </div>
      ${lessons || '<div class="work-empty">No lessons yet — build one from the chat, then preview it here.</div>'}`;
  }

  function wireWorkInteractions() {
    el.workScroll.querySelectorAll('[data-remove-word]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.removeWord;
        course.words = course.words.filter((w) => w.id !== id);
        course.lessons.forEach((l) => { l.wordIds = l.wordIds.filter((wid) => wid !== id); });
        save();
        renderWork();
      });
    });

    const addBtn = el.workScroll.querySelector('#addWordBtn');
    if (addBtn) {
      addBtn.addEventListener('click', () => {
        const input = el.workScroll.querySelector('#addWordInput');
        const raw = input.value.trim();
        if (!raw) return;
        const [w, gloss] = raw.split('—').map((s) => s.trim());
        course.words.push({ id: nextId('w'), w: w || raw, gloss: gloss || '', sentence: '', sentenceGloss: '' });
        save();
        renderWork();
      });
    }

    el.workScroll.querySelectorAll('[data-remove-lesson-word]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const [lessonId, wordId] = btn.dataset.removeLessonWord.split(':');
        findLesson(lessonId).wordIds = findLesson(lessonId).wordIds.filter((id) => id !== wordId);
        save();
        renderWork();
      });
    });

    el.workScroll.querySelectorAll('[data-edit-sentence]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const [, sentenceId] = btn.dataset.editSentence.split(':');
        editingSentences.add(sentenceId);
        renderWork();
        const input = el.workScroll.querySelector(`input[data-sentence="${btn.dataset.editSentence}"]`);
        if (input) { input.focus(); input.select(); }
      });
    });
    el.workScroll.querySelectorAll('[data-save-sentence]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const [, sentenceId] = btn.dataset.saveSentence.split(':');
        editingSentences.delete(sentenceId);
        renderWork();
      });
    });
    el.workScroll.querySelectorAll('[data-sentence]').forEach((input) => {
      input.addEventListener('change', () => {
        const [lessonId, sentenceId] = input.dataset.sentence.split(':');
        const s = findLesson(lessonId).sentences.find((s) => s.id === sentenceId);
        if (s) { s.text = input.value; save(); }
      });
      input.addEventListener('keydown', (e) => { if (e.key === 'Enter') input.blur(); });
    });
    el.workScroll.querySelectorAll('[data-del-sentence]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const [lessonId, sentenceId] = btn.dataset.delSentence.split(':');
        const lesson = findLesson(lessonId);
        lesson.sentences = lesson.sentences.filter((s) => s.id !== sentenceId);
        lesson.exercises = lesson.exercises.filter((e) => e.sentenceId !== sentenceId);
        editingSentences.delete(sentenceId);
        save();
        renderWork();
      });
    });

    el.workScroll.querySelectorAll('[data-add-exercise]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const lesson = findLesson(btn.dataset.addExercise);
        lesson.exercises.push({ id: nextId('e'), sentenceId: null, type: 'single_choice', prompt: '', options: ['', '', ''], answer: null });
        save();
        renderWork();
      });
    });
    el.workScroll.querySelectorAll('[data-ex-prompt]').forEach((input) => {
      input.addEventListener('change', () => {
        const [lessonId, exId] = input.dataset.exPrompt.split(':');
        const ex = findLesson(lessonId).exercises.find((e) => e.id === exId);
        if (ex) { ex.prompt = input.value; save(); }
      });
    });
    el.workScroll.querySelectorAll('[data-ex-option]').forEach((input) => {
      input.addEventListener('change', () => {
        const [lessonId, exId, idx] = input.dataset.exOption.split(':');
        const ex = findLesson(lessonId).exercises.find((e) => e.id === exId);
        if (!ex) return;
        const i = Number(idx);
        const wasAnswer = ex.options[i] === ex.answer;
        ex.options[i] = input.value;
        if (wasAnswer) ex.answer = input.value;
        save();
      });
    });
    el.workScroll.querySelectorAll('[data-ex-answer]').forEach((radio) => {
      radio.addEventListener('change', () => {
        const [lessonId, exId, idx] = radio.dataset.exAnswer.split(':');
        const ex = findLesson(lessonId).exercises.find((e) => e.id === exId);
        if (ex) { ex.answer = ex.options[Number(idx)]; save(); }
      });
    });
    el.workScroll.querySelectorAll('[data-del-exercise]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const [lessonId, exId] = btn.dataset.delExercise.split(':');
        const lesson = findLesson(lessonId);
        lesson.exercises = lesson.exercises.filter((e) => e.id !== exId);
        save();
        renderWork();
      });
    });

    const editTitle = el.workScroll.querySelector('#editTitle');
    if (editTitle) {
      editTitle.addEventListener('change', () => {
        course.title = editTitle.value.trim() || course.title;
        save();
        renderChatHeader();
      });
    }
    const editLang = el.workScroll.querySelector('#editLang');
    if (editLang) {
      editLang.addEventListener('change', () => {
        course.lang = editLang.value.trim() || course.lang;
        save();
        renderChatHeader();
      });
    }
    const editToLang = el.workScroll.querySelector('#editToLang');
    if (editToLang) {
      editToLang.addEventListener('change', () => {
        course.toLang = editToLang.value.trim() || course.toLang;
        save();
        renderChatHeader();
      });
    }
    const editLevelPicker = el.workScroll.querySelector('#editLevelPicker');
    if (editLevelPicker) {
      editLevelPicker.addEventListener('change', (e) => {
        const radio = e.target.closest('input[name=editLevel]');
        if (!radio) return;
        course.level = radio.value;
        save();
        renderChatHeader();
      });
    }
  }

  renderChatHeader();
  renderChat();
  renderWork();
})();
