# TASKS

## Overview

- Try to have a fully working app when a feature pack is complete


## Feature Pack 1 - Architecture

### Design the architecture 
- [v] prompts, prompts router etc  
- [v] Results structure  
### Recreate the database structure 
- [v] Recreate all table and databases for course  
- [v] Create tables for prompts and prompt history
### Tasks, API and full process 
- [v] verify that the process works for an example action
##  Feature Pack 2 - Course editor pane 
- [v] words pane - load words from current modulw/course 
- [v] lesson page with exercises
    > Q: Separate page or a tab in the course pane? Decision: a "Lesson" tab next to Modules/Words, showing the context's lesson (else the module's first lesson).
- [v] words for this module mark used 
    > Q: How is a word "used"? Decision: new column course.exercise.word; saving/deleting an exercise recalculates course.words.used for its module (used = some exercise in the module practises the word).
- [v] manual editing of exercise
    > Q: Which fields does the form edit? Decision: type, word, question, answer, wrong options (options = {"incorrect": [...]}, like the AI SingleChoice shape), translation (sentence_alt1), explanation.
- [v] manual add exercise
##  Feature Pack 3 - Prompt context
- [v] The prompt options should know the current course/module context
    > Q: Where are options computed and when are they shown? Decision: the server computes them from the course's last saved context (GET /prompt/default_options, utils/context_options.py); the chat shows them at start and after every reply that has no options of its own. Unrecognised typed messages also get them.
    > Q: Thresholds? Decision: 10 exercises per lesson, 5 lessons per module, 5 words per exercise request (constants in utils/context_options.py).
    > Q: Offer one option or all that apply? Decision: the most specific step only (next module > next lesson > create exercises), plus "Suggest (more) words" when there are no unused words.
    - [v] No words - suggest words
    - [v] No exercise - suggest create exercise for words 
        > Q: How are exercises created? Decision: one AI call writes one exercise for each word of the picked option, saved in the current lesson, which marks the words used.
        > Q: How are they offered? Decision (per David): up to 3 alternatives, each naming 3 different unused words ("Create single choice exercises for: sole, luna, albero"); the option's prompt_values carry its words (fewer per option when the lesson is nearly full).
        > Q: What is a single-choice exercise (the default)? Decision (per David): a sentence in the learned language that uses the word; the student picks the sentence's correct translation from 5 options: the correct translation + 4 wrong ones that look alike but change the meaning (another word, person, tense or negation). The manual form still starts with 4 option rows. Fill in the blank (sentence with ___, the word is the answer) is generated only when prompt_type is fill_in_the_blank.
    - [v] too many exercise for the current lesson - create the next lesson
        > Q: What happens after creating it? Decision: "Lesson N+1" is added and becomes the current context, so new exercises go there.
    - [v] too many lessons per module - suggest creating the next module, move words from current module to the next one    
        > Q: Which words move? Decision: only words no exercise uses yet; used words stay with their module. The new "Module N+1" gets "Lesson 1" and becomes the current context.
## Feature Pack 3 - Video
- [v] When the prompt contains a video url
    > Q: How is a video link recognised? Decision: any YouTube URL in a typed chat message routes to the video router (main_router), whatever else the message says.
    > Q: Which subtitles? Decision: the course's learning language only; if missing, the reply lists the languages the video has.
    - [v] start a video module 
        > Q: Module title and storage? Decision: titled after the video (YouTube oEmbed), subtitles stored in course.video.raw_subtitles; the module becomes the current context with no lesson until it is split.
    - [v] suggest braking the video into 10 parts each 3 minutes length,  20 parts each 2 minutes length
        > Q: Fixed 10/20 parts? Decision: offer 3-minute and 2-minute parts, with the part count computed from the video's length. Each part becomes a lesson ("Part 1 (0:00-3:02)") whose description holds the part's subtitles; parts end on subtitle boundaries.
    - [v] extract words 
        > Q: Whole video or per part? Decision: one AI call per part ("Extract words and sentences from Part N"), up to 15 words with translations, saved to the module; the part's lesson.words records them and marks the part done.
    - [v] extract parts 
        > Q: What are "parts" here? Decision: cleaned-up sentences with translations (up to 10 per part), saved to course.sentences with the part's lesson_id, in the same AI call as the words.
- [v] generate exercises 
    > Q: New flow for video? Decision (per David): exercises come from each part's extracted words and sentences, offered for the first part that still has some without exercises. All are single choice: the question is the word or sentence, the options are translations (the correct one + 3 wrong), saved in the part's lesson, which becomes current.
        - "Create word exercises for Part N": no AI; wrong options are random translations of the module's other words.
        - "Create sentence exercises for Part N": no AI; wrong options are random translations of the module's other sentences.
        - "... with AI wrong translations": one AI call writes 3 wrong translations per sentence that look alike but change the meaning.
        - "Extract words and sentences from Part N and create exercises" (per David: in one go): extraction, then word and sentence exercises with random wrong options. Q: AI wrong options for the sentences here? Decision: no, random, so the step stays a single AI call (~3 min).
    > Q: Lesson size limit for parts? Decision: none; a part holds all its exercises. Video modules don't get the generic AI "Create single choice exercises for: ..." options or "next lesson"/"next module".
- [v] select words and translations 
    > Q: How? Decision: tap a word in the Words tab to edit its translation or remove it (PUT /words/word, soft delete). Removed words are not suggested again.
    > Note: extracting a part took ~3.5 min on muse-glimmer, so the chat now waits up to 10 minutes for a reply.


## Feature Pack 4 - Ui improve improvements
- [v] lesson pane merged into the module pane; the separate Lesson tab is removed
    > Q: How do lessons show inside a module? Decision: the current module lists its lessons (title + exercise count); the current lesson (context, else the first) opens in place with the part text, "Add exercise" and the exercise cards (edit/delete). Tapping another lesson makes it current.
- [v] video preview in each video lesson
    > Q: Where do part times come from? Decision: new columns course.lesson.video_start/video_end (seconds), set when a video is split; existing parts were backfilled from their titles. The modules list returns each module's video_url.
    > Q: What does "Play part" do? Decision: plays from the part's start and stops at its end. The preview is cued at the part's start; YouTube's own play button resumes from where it paused and also stops at the part's end. Player: youtube_player_iframe (web, macOS, iOS, Android), max 420px wide.
- [v] lesson preview
    > Q: Full-course page or per-module pane? Decision: a "Preview" tab in the course pane for the current lesson, built as a reusable LessonPreview widget so a full-course preview page (the header's Preview button) can reuse it later.
    > Q: How does it play? Decision: the video part first (if any), then one exercise at a time with options shuffled (same order each time); single choice, fill in the blank and true/false check on tap, multiple choice has a Check button, explanations are read. After checking: right/wrong colours, the translation and the explanation. At the end "N of M correct" (explanations not counted) and "Start again". Editing the lesson restarts the preview.
- [v] sentences pane on the chat page
    > Q: Separate pane or a tab? Decision: a "Sentences" tab in the course pane next to Modules/Words/Lesson, for the current module: sentence + translation, grouped by lesson (video part), marked when an exercise asks it (GET /words/sentences). Read-only for now.
- [] words panes - allow adding words manually - translation is optional
- [] Lessons pane - 
    - [v] adding exercises manually
        > Q: One form or one per type? Decision: one dialog whose fields follow the type. Single/multiple choice: sentence, 4 options by default with a checkbox for each correct one (single choice allows exactly one), add/remove options, translation, explanation. True/false: statement + True/False. Explanation: one multi-line text. Fill in the blank: question with ___ and the same option rows with exactly one correct option (the word for the blank), translation, explanation.
        > Q: How are several correct options stored? Decision: options = {"correct": [...], "incorrect": [...]}, answer = the first correct option. Exercises without options.correct (the AI's) read their answer as the one correct option. True/false stores answer "true"/"false".
    - [v] Edit Exercise - you can correct any part of the exercise manually 
    - [v] Add options 
    - [v] delete options 
    - [v] correct sentences and correct translation


## Feature Pack 4 - Ui improve improvements - phase 2 
- [v] improvement phase 1 
module/lesson issue 
we have 3 panes now 
- lessons
- modules
- words

I am considering embedding lessons inside modules
adding a new pane 
- sentences 
Do we need to show the video? maybe it is not a bad idea = but were will we see it?
- [v] add video preview 


## Feature Pack 5 - Preview lesson
- [] decide is preview simply another
    - [] Full course preview in a different page/window
    - [] Per module preview pane
    - [] Per lesson preview pane



## Feature pack 6 - Full course preview 

- [] Create a full course preview 
- [] Optional create a button with preview as modal for lesson.

## Feature pack 7 - Improve prompts 
- [] sentences are too long 
- [] we need smaller speech parts 
- [] We need more words in a video





## Feature Pack 20 -Context words in module 
- [] Words appeared in sentences should be collected - suggest them as new words to learn
- []  



## Next steps 
1. improve ui - view words/sentences/exercises
2. Learner part copy logic from the existing code
