// Mock data + "AI" content generation + localStorage persistence for the
// Create-with-AI chat POC. Everything here is client-side and fake — there
// is no backend call. See README.md for scope.

const LANG_INFO = {
  japanese: { flag: '🇯🇵', name: 'Japanese' },
  hebrew:   { flag: '🇮🇱', name: 'Hebrew' },
  spanish:  { flag: '🇪🇸', name: 'Spanish' },
  french:   { flag: '🇫🇷', name: 'French' },
  italian:  { flag: '🇮🇹', name: 'Italian' },
  arabic:   { flag: '🇸🇦', name: 'Arabic' },
  german:   { flag: '🇩🇪', name: 'German' },
  english:  { flag: '🇬🇧', name: 'English' },
  korean:   { flag: '🇰🇷', name: 'Korean' },
  portuguese: { flag: '🇵🇹', name: 'Portuguese' },
};
const LANG_SUGGESTIONS = Object.values(LANG_INFO).map((l) => l.name);

function langInfo(name) {
  const key = (name || '').trim().toLowerCase();
  return LANG_INFO[key] || { flag: '🌐', name: name || 'Unknown' };
}

const LEVELS = ['A1', 'A2', 'B1', 'B2', 'C1'];

// --- Curated starter vocabulary (real words + real example sentences) for
// the languages this app defaults to. Anything else falls back to clearly
// labelled placeholder content — this is a workflow POC, not a translator.
const VOCAB = {
  japanese: [
    { w: 'こんにちは', gloss: 'hello', sentence: 'こんにちは、元気ですか?', sentenceGloss: 'Hello, how are you?' },
    { w: 'ありがとう', gloss: 'thank you', sentence: 'どうもありがとうございます。', sentenceGloss: 'Thank you very much.' },
    { w: '水', gloss: 'water', sentence: '水を一杯ください。', sentenceGloss: 'One glass of water, please.' },
    { w: '猫', gloss: 'cat', sentence: '猫が好きです。', sentenceGloss: 'I like cats.' },
    { w: '犬', gloss: 'dog', sentence: '犬と散歩します。', sentenceGloss: 'I walk with the dog.' },
    { w: '家', gloss: 'house', sentence: 'これは私の家です。', sentenceGloss: 'This is my house.' },
    { w: '友達', gloss: 'friend', sentence: '彼は私の友達です。', sentenceGloss: 'He is my friend.' },
    { w: '食べる', gloss: 'to eat', sentence: '朝ごはんを食べます。', sentenceGloss: 'I eat breakfast.' },
    { w: '飲む', gloss: 'to drink', sentence: 'コーヒーを飲みます。', sentenceGloss: 'I drink coffee.' },
    { w: 'おはよう', gloss: 'good morning', sentence: 'おはようございます。', sentenceGloss: 'Good morning.' },
    { w: 'さようなら', gloss: 'goodbye', sentence: 'さようなら、また明日。', sentenceGloss: 'Goodbye, see you tomorrow.' },
    { w: 'はい', gloss: 'yes', sentence: 'はい、そうです。', sentenceGloss: 'Yes, that is right.' },
    { w: 'いいえ', gloss: 'no', sentence: 'いいえ、違います。', sentenceGloss: 'No, that is not right.' },
    { w: '学校', gloss: 'school', sentence: '毎日学校に行きます。', sentenceGloss: 'I go to school every day.' },
  ],
  hebrew: [
    { w: 'שלום', gloss: 'hello / peace', sentence: 'שלום, מה שלומך?', sentenceGloss: 'Hello, how are you?' },
    { w: 'תודה', gloss: 'thank you', sentence: 'תודה רבה לך.', sentenceGloss: 'Thank you very much.' },
    { w: 'מים', gloss: 'water', sentence: 'אני רוצה כוס מים.', sentenceGloss: 'I want a glass of water.' },
    { w: 'חתול', gloss: 'cat', sentence: 'אני אוהב חתולים.', sentenceGloss: 'I like cats.' },
    { w: 'כלב', gloss: 'dog', sentence: 'הכלב שלי גדול.', sentenceGloss: 'My dog is big.' },
    { w: 'בית', gloss: 'house', sentence: 'זה הבית שלי.', sentenceGloss: 'This is my house.' },
    { w: 'חבר', gloss: 'friend', sentence: 'הוא חבר טוב.', sentenceGloss: 'He is a good friend.' },
    { w: 'לאכול', gloss: 'to eat', sentence: 'אני אוכל ארוחת בוקר.', sentenceGloss: 'I eat breakfast.' },
    { w: 'לשתות', gloss: 'to drink', sentence: 'אני שותה קפה.', sentenceGloss: 'I drink coffee.' },
    { w: 'בוקר טוב', gloss: 'good morning', sentence: 'בוקר טוב לכולם.', sentenceGloss: 'Good morning everyone.' },
    { w: 'להתראות', gloss: 'goodbye', sentence: 'להתראות, נתראה מחר.', sentenceGloss: 'Goodbye, see you tomorrow.' },
    { w: 'כן', gloss: 'yes', sentence: 'כן, זה נכון.', sentenceGloss: 'Yes, that is correct.' },
    { w: 'לא', gloss: 'no', sentence: 'לא, זה לא נכון.', sentenceGloss: 'No, that is not correct.' },
    { w: 'בית ספר', gloss: 'school', sentence: 'אני הולך לבית הספר כל יום.', sentenceGloss: 'I go to school every day.' },
  ],
  spanish: [
    { w: 'hola', gloss: 'hello', sentence: 'Hola, ¿cómo estás?', sentenceGloss: 'Hello, how are you?' },
    { w: 'gracias', gloss: 'thank you', sentence: 'Muchas gracias.', sentenceGloss: 'Thank you very much.' },
    { w: 'agua', gloss: 'water', sentence: 'Quiero un vaso de agua.', sentenceGloss: 'I want a glass of water.' },
    { w: 'gato', gloss: 'cat', sentence: 'Me gustan los gatos.', sentenceGloss: 'I like cats.' },
    { w: 'perro', gloss: 'dog', sentence: 'Mi perro es grande.', sentenceGloss: 'My dog is big.' },
    { w: 'casa', gloss: 'house', sentence: 'Esta es mi casa.', sentenceGloss: 'This is my house.' },
    { w: 'amigo', gloss: 'friend', sentence: 'Él es mi amigo.', sentenceGloss: 'He is my friend.' },
    { w: 'comer', gloss: 'to eat', sentence: 'Como el desayuno.', sentenceGloss: 'I eat breakfast.' },
    { w: 'beber', gloss: 'to drink', sentence: 'Bebo café.', sentenceGloss: 'I drink coffee.' },
    { w: 'buenos días', gloss: 'good morning', sentence: 'Buenos días a todos.', sentenceGloss: 'Good morning everyone.' },
    { w: 'adiós', gloss: 'goodbye', sentence: 'Adiós, hasta mañana.', sentenceGloss: 'Goodbye, see you tomorrow.' },
    { w: 'sí', gloss: 'yes', sentence: 'Sí, es correcto.', sentenceGloss: 'Yes, that is correct.' },
    { w: 'no', gloss: 'no', sentence: 'No es correcto.', sentenceGloss: 'That is not correct.' },
    { w: 'escuela', gloss: 'school', sentence: 'Voy a la escuela todos los días.', sentenceGloss: 'I go to school every day.' },
  ],
};

function vocabFor(lang) {
  const key = (lang || '').trim().toLowerCase();
  if (VOCAB[key]) return VOCAB[key];
  // Unknown language — obviously-fake placeholder content, still enough
  // to exercise every step of the flow.
  return Array.from({ length: 14 }).map((_, i) => ({
    w: `${lang || 'Word'} #${i + 1}`,
    gloss: `demo gloss ${i + 1}`,
    sentence: `(demo) Example sentence using word #${i + 1}.`,
    sentenceGloss: `(demo) Example sentence, translated.`,
  }));
}

let _id = 1;
function nextId(prefix) { return `${prefix}_${_id++}_${Date.now().toString(36)}`; }

/** Generate up to `count` new words for `lang`, skipping ones already on the course. */
function generateWords(lang, existingWords, count = 12) {
  const bank = vocabFor(lang);
  const already = new Set(existingWords.map((w) => w.w));
  const picked = bank.filter((v) => !already.has(v.w)).slice(0, count);
  return picked.map((v) => ({ id: nextId('w'), w: v.w, gloss: v.gloss, sentence: v.sentence, sentenceGloss: v.sentenceGloss }));
}

/** Build draft sentence rows for the given course words (one sentence each). */
function generateSentences(words) {
  return words.map((word) => ({
    id: nextId('s'),
    wordId: word.id,
    text: word.sentence || `(demo) Sentence for "${word.w}".`,
    gloss: word.sentenceGloss || '(demo) translated sentence.',
    chosen: true,
  }));
}

/** Build a single-choice exercise per sentence, distractors pulled from the other chosen words. */
function generateExercises(sentences, words) {
  const byId = Object.fromEntries(words.map((w) => [w.id, w]));
  return sentences.map((s, i) => {
    const word = byId[s.wordId];
    const correct = word ? word.w : '?';
    const distractorPool = words.filter((w) => w.id !== s.wordId).map((w) => w.w);
    const distractors = [];
    for (let j = 0; j < distractorPool.length && distractors.length < 2; j++) {
      const pick = distractorPool[(i + j) % distractorPool.length];
      if (pick !== correct && !distractors.includes(pick)) distractors.push(pick);
    }
    const options = [correct, ...distractors];
    // Shuffle deterministically-ish so it isn't always first.
    options.sort(() => 0.5 - Math.random());
    return {
      id: nextId('e'),
      sentenceId: s.id,
      type: 'single_choice',
      prompt: s.gloss ? `Which word means "${s.gloss.replace(/\.$/, '')}"?` : 'Choose the correct word.',
      options,
      answer: correct,
    };
  });
}

// --- Persistence -----------------------------------------------------

const STORE_KEY = 'poc_create_with_ai_courses_v1';

function loadAll() {
  try {
    const raw = localStorage.getItem(STORE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch (e) {
    return null;
  }
}

function saveAll(courses) {
  localStorage.setItem(STORE_KEY, JSON.stringify(courses));
}

function seedDemoCourses() {
  const now = Date.now();
  const c1Words = generateWords('Japanese', [], 8);
  const c1Sentences = generateSentences(c1Words.slice(0, 6));
  const c1Exercises = generateExercises(c1Sentences, c1Words);
  const course1 = {
    id: nextId('c'),
    title: 'Japanese for Hebrew Speakers',
    lang: 'Japanese',
    toLang: 'Hebrew',
    level: 'A1',
    createdAt: now - 1000 * 60 * 60 * 24 * 3,
    updatedAt: now - 1000 * 60 * 60 * 2,
    mode: 'edit',
    words: c1Words,
    lessons: [
      {
        id: nextId('l'),
        title: 'Lesson 1 — Greetings',
        status: 'ready',
        wordIds: c1Words.slice(0, 6).map((w) => w.id),
        sentences: c1Sentences,
        exercises: c1Exercises,
      },
    ],
    chat: [
      { id: nextId('m'), role: 'assistant', text: "Course 'Japanese for Hebrew Speakers' created — Japanese → Hebrew, level A1. Let's start with a word list." },
      { id: nextId('m'), role: 'user', text: 'Create word list' },
      { id: nextId('m'), role: 'assistant', text: `Generated ${c1Words.length} starter words. Review them in the Words tab, then pick some for Lesson 1.` },
      { id: nextId('m'), role: 'user', text: 'Select words for Lesson 1' },
      { id: nextId('m'), role: 'user', text: 'Confirmed 6 words' },
      { id: nextId('m'), role: 'assistant', text: 'Locked in 6 words for Lesson 1. I drafted example sentences and exercises for all of them — Lesson 1 is ready. Switch to Preview to see the student view.' },
    ],
  };

  const course2 = {
    id: nextId('c'),
    title: 'Spanish for English Speakers',
    lang: 'Spanish',
    toLang: 'English',
    level: 'A1',
    createdAt: now - 1000 * 60 * 60 * 24,
    updatedAt: now - 1000 * 60 * 30,
    mode: 'edit',
    words: [],
    lessons: [],
    chat: [
      { id: nextId('m'), role: 'assistant', text: "Course 'Spanish for English Speakers' created — Spanish → English, level A1. Let's start with a word list.", actions: [{ id: 'create_words', label: 'Create word list' }] },
    ],
  };

  const courses = [course1, course2];
  saveAll(courses);
  return courses;
}

const CourseStore = {
  all() {
    return loadAll() || seedDemoCourses();
  },
  get(id) {
    return this.all().find((c) => c.id === id) || null;
  },
  save(course) {
    const courses = this.all();
    const i = courses.findIndex((c) => c.id === course.id);
    course.updatedAt = Date.now();
    if (i === -1) courses.unshift(course);
    else courses[i] = course;
    saveAll(courses);
  },
  create({ title, lang, toLang, level }) {
    const info = langInfo(lang);
    const toInfo = langInfo(toLang);
    const finalTitle = (title && title.trim()) || `${info.name} for ${toInfo.name} Speakers`;
    const course = {
      id: nextId('c'),
      title: finalTitle,
      lang: info.name,
      toLang: toInfo.name,
      level: level || 'A1',
      createdAt: Date.now(),
      updatedAt: Date.now(),
      mode: 'edit',
      words: [],
      lessons: [],
      chat: [
        {
          id: nextId('m'),
          role: 'assistant',
          text: `Course '${finalTitle}' created — ${info.name} → ${toInfo.name}, level ${level || 'A1'}. Let's start with a word list.`,
          actions: [{ id: 'create_words', label: 'Create word list' }],
        },
      ],
    };
    this.save(course);
    return course;
  },
  wordCount(course) { return course.words.length; },
  lessonCount(course) { return course.lessons.length; },
  progressLabel(course) {
    if (!course.words.length) return 'Not started';
    const ready = course.lessons.filter((l) => l.status === 'ready').length;
    return `${course.words.length} words · ${course.lessons.length} lesson${course.lessons.length === 1 ? '' : 's'}${ready ? ` (${ready} ready)` : ''}`;
  },
};
