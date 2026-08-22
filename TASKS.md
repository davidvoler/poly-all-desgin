# TASKS


### Create with AI - POC


- [x] In Dashboard create a new page named 'Course AI POC' It should have the following elements 
    - [x] title course name 
    - [x] learning language 
    - [x] student language
    - [x] Prompt
- [x] Fix -  Prompt is only an Input - maybe with some icon indicating it is a prompt - We do not need the copy prompt text and all that
- [x] On top of the prompt lets replace the text Prompt with 'Hi {username} let's start creating a course'
- The 

### Create Lesson - Description

options under the prompt - A user can select what to do
options will change with context 
Example options 
- select words for next lesson/ course 
- Create next lesson
- Preview lesson
- Create a course 
Every call to the backend will return the next option

I see that I have already created a model for prompt with the different models. 
Maybe I should be using it after all. 

We can start the process one by one
1. create a course - generate title if not provided by the user. 
2. suggest next steps
a. select initial words for course 
b. create first lesson - greeting sentences
c. Create the next lessons - simple sentences. 

Experiment:
I have asked gemini to teach me words related to politics 
The words were great - but they he created 3 sentences for all participating words that were impossible to understand - As each word there was not understood. 

The idea that language should be thought while introducing little difficulty each time and keep most of the text familiar - is difficult for AI. We will have to ask for it implicitly. 



#### Tasks
- [x] create the backend model for response that include options 
- [x] Create the default options 
- [x] Create initial router code



#### End2End front end and backend 

- [x] When we create a course the first time call /generate_course
- [x] We get back the text and 2 options 
    - [x] create words 
    - [x] Create leson
- [x] We can click on each and get the results 

#### The process of creating a course 

cleanup 
- [x] remove '14 streak' and search icon from the top left of Course AI POC 
- [x] One we have created the course 
    - [x] the title should be the course title
    - [x] We should keep in the state course_id, lang, to_lang and send them with any new prompt 
    - [x] next prompts should not be create course but only create lesson 


#### Let's review the process 

Lets compare to Gemini and and Claude

Gemini 
left had icon menu
- New chat
- Search chats
- image 
- Video
- Library
- recent - a list of recent Chats 

The Chat window itself 

Ask away, David
+ {icon} Ask Gemini     /select Model/mic icone





What do we need?
Course context - See all courses that I was working on 
Create Course - should be simple - lang to lang level and title - for now no need for prompt to create a course
Once course is created - we are in the course context
We can switch courses and continue from were we left 
We should have course in edit mode and in preview mode 
We should be able to create list of words for the course 
Select words for the next lesson
Create sentences for lesson 
Choose sentences for the lesson - or ask the backend to directly create exercises  
Edit sentences 
Edit exercises
preview course 


It is time for a UI/UX POC
We can create the POC in HTML/JS only in the folder 
plan/design_experiments/create_with_ai_poc
The page should be designed with AI Chat in minf hourser in our case this is not a general ask me anything chat - but we have a certain perpose to create a course, review it, and direct the backend/AI to create what we expect. 





#### We have the concept 
The first version of the concept looks good - but we will have to do a few changes 

The Good:
- Like in any other AI Chat window I can follow my actions 
- I have a list of courses and information about them (number of lessons, words,  etc)
- I have the edit mode and the preview mode 
- I can see list of words and list of sentences 
- I have my courses page that leads to the course page 

Improvements 
 - When we are in the context of a course - we do not need to see the other courses. A link to my courses is enough - we need the entire space
 - We should break the page in 2 
    - Left side is the chat and the process 
    - Right side the the models/lesson/exercises

Words 
- It could be that when we create a lesson we offer words for the next lesson 
- We over a few and only 2 are selected - If we define 2 words per lessons 
- User. can select other words from the list 


The lessons in edit/preview mode  
- lesson title 
- words in lesson
- exercises 
Preview mode 
- What we have is not bad - it is a long list of exercises - where you can participate 
- Full - preview - exercise after exercise - exactly like in the students will see 
--done up to this line--
#### More small fixes before moving to implement with flutter 
1. Add costs/tokens to the chat area 
2. Rename edit tab with 'edit course' 
3. Ddd to course more data like number of lessons, modules etc
4. Think how we can add modules 
5. Add the possibility to create exercise manually 
6. add the options to edit elements in a sentences - maybe an edit button
7. show current lesson/module - while other modules could be closed (view only the title)
8. We can see words that we hve already used 
9. We can see the next words when selecting a lesson


More fixes 
1. move 'my courses' to the top left 
2. "My Course" should be a bit bigger 
3. Add start a new module 




# Planning the api

Mapping the create_with_ai_poc (`plan/design_experiments/create_with_ai_poc`) feature
set to backend endpoints before building it in Flutter. Conventions to follow (both
already established in the codebase):
- AI-generation calls stay flat under `/api/v1/generate_poc/<verb>` (matches the
  existing `generate_course`/`generate_lesson`/`generate_words_list`).
- Plain CRUD lives under `/api/v1/edit/<resource>/...` (matches `edit_course.py`).
- Every new/changed endpoint uses `Depends(current_school_user)` and scopes every
  query by `(user_id, school_id)` — same as every existing editor endpoint.

#### Decisions needed before implementing
- [x] New table `course_simple.course_word` for the AI word bank? There's no
      per-course word-bank table today — `module.words`/`lesson.words` are just
      `text[]` columns, and `draft.words(lang, word)` is a global (not per-course)
      dictionary with no gloss/example-sentence/used-state. Proposing:
      `course_word(course_word_id serial pk, course_id, word, gloss,
      example_sentence, example_gloss, created_at)`.
- [x] `generate_poc` endpoints aren't gated by the existing
      `permissions['create_with_ai']` flag (`utils/user_school_data.py`) — should
      the new/changed endpoints enforce it?
- [x] Sentence/exercise CRUD: nest under `/api/v1/edit/course/...`, or give
      lesson/exercise their own routers (`/api/v1/edit/lesson/...`,
      `/api/v1/edit/exercise/...`)? Leaning toward one router per resource, since
      `edit_course.py` today is scoped only to courses.
- [x] `GenerateCourseRequest` has no `level` field even though `course.level`
      already exists in the DB and the POC's create-course form requires it —
      needs adding (request model + `create_course()` insert).

#### Course context ("My courses" list + create)
- [x] `GET /api/v1/edit/course/courses` — reuse as-is; response needs word/module/
      lesson counts added (extend `Course` with `word_count`/`module_count`/
      `lesson_count`/`ready_lesson_count`, or a `?with_stats=true` variant)
- [x] `POST /api/v1/generate_poc/generate_course` — reuse; add `level` (see
      decisions above)

#### Course workspace (load + Edit Course tab)
- [x] `GET /api/v1/edit/course/course/{course_id}/full` — new aggregate endpoint:
      course meta + modules[] + lessons[] (each with words/sentences/exercises) +
      word bank, in one call, so the workspace doesn't need N+1 round-trips.
      Alternative: compose from the granular GETs below instead — pick one.
- [x] `POST /api/v1/edit/course/course` — reuse for title/lang/to_lang/level
      updates (Edit Course tab); add `level` to the `Course` model

#### Words tab
- [x] `POST /api/v1/generate_poc/generate_words_list` — currently a stub; wire to
      actually generate N words and persist into `course_word`, returning the new
      rows + `actual_tokens`/`actual_cost`
- [x] `POST /api/v1/edit/course/{course_id}/words` — add a word manually
- [x] `DELETE /api/v1/edit/course/words/{course_word_id}` — remove a word (also
      detach it from any lesson's word selection)
- [x] word "used" tracking — computed server-side (join `course_word` against
      whatever links a word to a lesson, see lesson-word link decision below),
      returned as `used: bool` per word

#### Modules
- [x] `POST /api/v1/edit/course/{course_id}/modules` — create a module (title
      optional, server defaults to "Module N"); plain CRUD, not AI — the POC's
      "Start a new module" never calls an AI endpoint
- [x] modules fold into the `GET .../full` response — no separate list endpoint
      needed unless we skip the aggregate route

#### Lessons
- [x] `POST /api/v1/edit/course/modules/{module_id}/lessons` — create a lesson
      draft (`status='draft'`)
- [x] `PATCH /api/v1/edit/course/lessons/{lesson_id}/words` — confirm word
      selection, body `{word_ids: [...]}`; need to decide how word↔lesson links
      are stored (a `lesson_word` join table, or keep `lesson.words text[]` but
      store `course_word_id`s instead of raw strings)
- [x] `POST /api/v1/generate_poc/generate_sentences` — new; body `{lesson_id}`,
      generates + persists draft sentences for the lesson's selected words
      (`chosen=true` by default)
- [x] `PATCH /api/v1/edit/course/lessons/{lesson_id}/sentences` — confirm which
      generated sentences to keep, body `{sentence_ids: [...chosen...]}`
- [x] `POST /api/v1/generate_poc/generate_exercises` — new; body `{lesson_id}`,
      generates + persists exercises from the lesson's chosen sentences, sets
      lesson `status='ready'`
- [x] `POST /api/v1/generate_poc/generate_lesson` — repurpose the existing stub
      for "Create exercises directly": given `{lesson_id}`, generate sentences
      AND exercises in one call, skipping the confirm-sentences step
- [x] sentences need real rows, not just `lesson.words text[]` — new table
      `course_simple.lesson_sentence(lesson_sentence_id pk, lesson_id, text,
      gloss, chosen bool default true)`, since sentences need individual ids to
      edit/delete/toggle
- [x] `PATCH /api/v1/edit/course/sentences/{lesson_sentence_id}` — edit sentence
      text
- [x] `DELETE /api/v1/edit/course/sentences/{lesson_sentence_id}` — delete a
      sentence (cascade-delete any exercise built from it)

#### Exercises
- [x] `POST /api/v1/edit/course/lessons/{lesson_id}/exercises` — add a blank
      exercise manually
- [x] `PATCH /api/v1/edit/course/exercises/{exercise_id}` — edit prompt/options/
      correct answer (maps onto the existing `exercise.options` jsonb +
      `sentence`/word columns — settle the exact jsonb shape against the existing
      exercise-type catalogue rather than inventing a new one)
- [x] `DELETE /api/v1/edit/course/exercises/{exercise_id}` — delete an exercise

#### Preview
- [x] no new endpoint — Preview tab just renders the same `GET .../full` response
      read-only

#### Usage / cost
- [x] every `generate_poc` response already carries `actual_tokens`/`actual_cost`
      — once a real LLM call lands, populate these for real (currently always
      0.0/0, nothing calls an LLM yet); the running per-course total shown in the
      chat header stays a client-side sum, no new endpoint needed



#### API Manual planning 

- We always use POST with a request
- We should test permission on each call - User can edit this course? User can use AI? etc. 
- We do not use path parameters  /write/{course_id}/best - As we always use post and pass course_id, lesson_id in the request



Utilities
- permissions (course editing, using AI, AI Limit etc)
- calc costs , estimate costs 
endpoints

No AI
- /edit/create/course - create course 
- /edit/course/state - got back to last state - show the prompt history
- /edit/course/words/update - updates the list of words - by user by adding and removing

- /edit/module/create - creates a new module - this becomes the current module 

AI
- /generate/prompt - general prompt that we should use AI to understand
With or without AI
- words : we always see the next words to use
- /edit/course/words/suggest - suggests an initial words per course

- /edit/lesson/gen -{words} -  generate a full lesson - from words 
- /edit/lesson/sentences - {words} -  generate a full lesson
- /edit/lesson/exercises - {sentences} -  generate a full lesson





#### Initial implementation


I have started implementing the full api 
I have to think - when generating a lesson - Are we going to insert the exercises and than send them back to the user - so he can edit/delete/add 
Or we send them to the users - and if he approves than we save to the DB

Sounds like the first option in better - this way we can go back to where we left. 

Maybe we want to add reviewed field for all elements - this is set to true when user has spend some time reviewing - or explicitly set reviewed button

It is good to have plain simple CRUD API for content elements - as we may reuse it - for imported courses, for gen with AI and manual creation of course. when applicable 


##### Just before we bind frontEnd and backend 

1. We need to create a table for prompts and results - so we can have the state of every prompt. 
2. We need to plan the process again - with full options
3. Meta Model is now free and supports ollama - we can use it for experiments 


Process 
Enter a course and start generating 
We have the following options for generating data 
- gen words 
      - AI
      - corpus - words that are common in a corpus 
      - zipf - load words by how common they are in zipf db 
- gen sentences 
      - AI
      - Corpus
- Translate
      - AI
      - Google Translate
      - Azure 
- Gen Audio
      - AI?
      - Azure
      - Google
      - Others? 
- Gen Exercise 
      - Logic 80% single choice, 10% identify words, ...
      - AI
- Sentences Elements 
      - Spacy
      - AI

- Option for prompts 
      - Words source 
      - Sentences source
      - AI configuration

We can think of a complex scenario where you want the data from corpus - but if sentences are missing you generate with ai
Also - when data comes from corpus - you already have translation and voice

Complex feature 
- Link chat area with lesson  created by this chat 
- like the name of the chat window can be: Creating Lesson 3

We can ask AI to create complex exercises 
like explanation - or sentence annotation 
This goes into the chat window 

The initial code should try with AI as we do want to test how to work with it - especially now that we have the option of using the Meta model 


in case we do work with AI
Here is the process 
- AI, generate sentences 
- Code/AI break words - rank words
User review?
- Code Generate exercises 
Users review edit






### Manual Tasks 
- Implement get words  - do it manually, using zipf, using ollama
- We should start using
- Get words should be done for a single module 
- When we want next words - We ask the model - here is our last model words - give us the next words 
if we use zipf - we should keep the last words that we used and ask for the next chunk 
the same when we use words from a corpus 

When words are used in a course - stope offering them 
keep a list of course words with 

### Claude tasks 
- [x] Start using ollama 
- [x] choose models
-

#### Ollama provider (2026-08-13)

`utils/ollama_client.py` — real (non-mocked) local inference via
Ollama's HTTP API, reachable from the `server` container at
`host.docker.internal:11434` (Docker Desktop's host alias on Mac/
Windows; `extra_hosts: host-gateway` in docker-compose.yaml makes the
same alias work on Linux). Override with `OLLAMA_BASE_URL` if Ollama
runs elsewhere.

- [x] `POST /api/v1/generate_poc/` (previously an unimplemented stub) —
      the general "ask AI anything" prompt path
      (`Prompt.prompt`/`.provider`/`.model` → `PromptResponse.response`),
      gated on `current_ai_school_user` like every other AI endpoint.
      `provider` defaults to (and currently only supports) `"ollama"`.
- [x] `GET /api/v1/generate_poc/models` — `{"providers": {"ollama": [...]}}`
      for a model picker.
- [x] Models wired up: `muse-glimmer`, `gemma4`, `gpt-oss-20b` (tagged
      `gpt-oss:20b` in `ollama list` — `OLLAMA_MODELS` maps the display
      name to the real tag).
- [x] Token usage (`actual_tokens`) comes from Ollama's real
      `prompt_eval_count`/`eval_count`; `actual_cost` is always `0.0`
      since local inference has no per-token billing.
- Scope: only the raw prompt path is real now. `ai_course_content.py`
  (word/sentence/exercise generation) is still curated mock content —
  routing those through Ollama needs real prompt-engineering work
  (structured output, retries) that's out of scope for this pass.

#### Data model correction (2026-08-13)

First backend pass modeled words and sentences as real DB entities
(`course_word` table with a serial id, `lesson_word` join table,
`lesson_sentence` table with a serial id). Review feedback: that's too
much relational overhead for content that's really just per-course/
per-lesson state. Reworked to:

- [x] Words are NOT a database entity — no id, no table.
      `course_simple.course.words` is a plain ordered jsonb list
      (`[{word, gloss, example_sentence, example_gloss}, ...]`) —
      generation order = frequency order, simplest/most common word
      first. The word string is the identity, same as
      `course_simple.lesson.words` (text[], unchanged from before).
      `course_word`/`lesson_word` tables dropped.
- [x] Sentences ARE a database entity — `course_simple.sentence`
      (`sentence_id bigint pk, lang, text, gloss, created_at`) — but
      nothing holds a foreign key to it. `sentence_id` is a
      deterministic hash of `"lang:text"` (`sentence_id_for()` in
      `utils/ai_course_content.py`, masked to 53 bits so it stays a
      JS-safe integer through Flutter web's JSON), computed in app code
      before insert. A lesson just carries an ordered jsonb list of its
      own draft sentences (`course_simple.lesson.sentences`, mirroring
      `.words`) — no join table (`lesson_sentence` dropped).
- [x] Exercises keep their own copy of the prompt text
      (`exercise.sentence`) and only carry `sentence_id` for reference —
      editing an exercise never touches the sentence it came from, and
      deleting a draft sentence never cascades to exercises already
      built from it. No links to maintain in either direction, matching
      the pre-existing (and never FK-enforced)
      `exercise.sentence_id`/`to_sentence_id` columns.
- [x] `course.level`: `smallint` → `varchar`. Store CEFR strings
      (`"A1"`..`"C1"`) directly — no more int↔string mapping table
      (`utils/level.py` deleted).

See `plan/DDL/create_with_ai_v4.sql` for the migration. 


### Manual Tasks 
- [v]  write the create words with AI 
- [v]  write the create sentences with AI 
- [v]  write the create exercises - use code from  create_exercise_* in scripts 
Create exercise is quite simple all you need is the write a few fields 

- [v] Write a design - what do we do in each stage 


#### Create with AI - What do we do in each stage 
- when creating a course we add some settings that should be sent with each request
  - level
  - type of questions 
  - number of words per lesson - can be change in a module level - or in a specific lesson
  - use ai - model etc 
- Save chat messages 
      - message 
      - action
      - results 
      - message sent to chat 
      - tokens 
      - costs 
- When creating a module as to select words 
- When creating a lesson - save lesson
- Mark used words as used - deselect them 



The process in order 
- create course 
      - extra options/optional - with default 
- Create module 
      - create words and save in module 
- Create Lesson 
      - choose words 
      - create sentences 
      - create exercises 
- Create Exercise 
      - you can ask the create a specific exercise - for example explanation exercise - or something else 
- Free chat - should be mapped to one of the above actions  

After working on lessons I have some understanding 
1. I need words so far identify_words exercise - I could take them from module or course
2. I need a place to store sentences for using them as distactors - or wrong answers

It is time now to bind everything together and get the process to work.
Maybe it is also time to add options in the course so can change
We have to define the options fields and pass them on any request.

- [v] Generate options
- [] Create a CLI for testing the generate API
- [] Add the code for getting data from corpus
- [] get course words 


### Corpus
- [] create corpus connection
- [] get data from corpus 
- [] get words from corpus  


### Testing 
- [] this of a way to create local test for reviewing the results 

### UI
- [] The tabs on the left - lesson is first - that preview and finally words
- [] Show current module in the top
#### Words 
- [] Words are created for a module - We need to see a list of words in each module 
- [] Show the words used in each module 
- [] Show current module words 
#### Exercises 
- [] Allow creating a manual exercise 
- [] Add exercise type 
- [] Allow changing the exercise type

### End2End
#### Routers 
- [] Follow the design so far and decide what each rout is doing 
- [] Re