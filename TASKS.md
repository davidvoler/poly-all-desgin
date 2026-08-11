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
- [ ] New table `course_simple.course_word` for the AI word bank? There's no
      per-course word-bank table today — `module.words`/`lesson.words` are just
      `text[]` columns, and `draft.words(lang, word)` is a global (not per-course)
      dictionary with no gloss/example-sentence/used-state. Proposing:
      `course_word(course_word_id serial pk, course_id, word, gloss,
      example_sentence, example_gloss, created_at)`.
- [ ] `generate_poc` endpoints aren't gated by the existing
      `permissions['create_with_ai']` flag (`utils/user_school_data.py`) — should
      the new/changed endpoints enforce it?
- [ ] Sentence/exercise CRUD: nest under `/api/v1/edit/course/...`, or give
      lesson/exercise their own routers (`/api/v1/edit/lesson/...`,
      `/api/v1/edit/exercise/...`)? Leaning toward one router per resource, since
      `edit_course.py` today is scoped only to courses.
- [ ] `GenerateCourseRequest` has no `level` field even though `course.level`
      already exists in the DB and the POC's create-course form requires it —
      needs adding (request model + `create_course()` insert).

#### Course context ("My courses" list + create)
- [ ] `GET /api/v1/edit/course/courses` — reuse as-is; response needs word/module/
      lesson counts added (extend `Course` with `word_count`/`module_count`/
      `lesson_count`/`ready_lesson_count`, or a `?with_stats=true` variant)
- [ ] `POST /api/v1/generate_poc/generate_course` — reuse; add `level` (see
      decisions above)

#### Course workspace (load + Edit Course tab)
- [ ] `GET /api/v1/edit/course/course/{course_id}/full` — new aggregate endpoint:
      course meta + modules[] + lessons[] (each with words/sentences/exercises) +
      word bank, in one call, so the workspace doesn't need N+1 round-trips.
      Alternative: compose from the granular GETs below instead — pick one.
- [ ] `POST /api/v1/edit/course/course` — reuse for title/lang/to_lang/level
      updates (Edit Course tab); add `level` to the `Course` model

#### Words tab
- [ ] `POST /api/v1/generate_poc/generate_words_list` — currently a stub; wire to
      actually generate N words and persist into `course_word`, returning the new
      rows + `actual_tokens`/`actual_cost`
- [ ] `POST /api/v1/edit/course/{course_id}/words` — add a word manually
- [ ] `DELETE /api/v1/edit/course/words/{course_word_id}` — remove a word (also
      detach it from any lesson's word selection)
- [ ] word "used" tracking — computed server-side (join `course_word` against
      whatever links a word to a lesson, see lesson-word link decision below),
      returned as `used: bool` per word

#### Modules
- [ ] `POST /api/v1/edit/course/{course_id}/modules` — create a module (title
      optional, server defaults to "Module N"); plain CRUD, not AI — the POC's
      "Start a new module" never calls an AI endpoint
- [ ] modules fold into the `GET .../full` response — no separate list endpoint
      needed unless we skip the aggregate route

#### Lessons
- [ ] `POST /api/v1/edit/course/modules/{module_id}/lessons` — create a lesson
      draft (`status='draft'`)
- [ ] `PATCH /api/v1/edit/course/lessons/{lesson_id}/words` — confirm word
      selection, body `{word_ids: [...]}`; need to decide how word↔lesson links
      are stored (a `lesson_word` join table, or keep `lesson.words text[]` but
      store `course_word_id`s instead of raw strings)
- [ ] `POST /api/v1/generate_poc/generate_sentences` — new; body `{lesson_id}`,
      generates + persists draft sentences for the lesson's selected words
      (`chosen=true` by default)
- [ ] `PATCH /api/v1/edit/course/lessons/{lesson_id}/sentences` — confirm which
      generated sentences to keep, body `{sentence_ids: [...chosen...]}`
- [ ] `POST /api/v1/generate_poc/generate_exercises` — new; body `{lesson_id}`,
      generates + persists exercises from the lesson's chosen sentences, sets
      lesson `status='ready'`
- [ ] `POST /api/v1/generate_poc/generate_lesson` — repurpose the existing stub
      for "Create exercises directly": given `{lesson_id}`, generate sentences
      AND exercises in one call, skipping the confirm-sentences step
- [ ] sentences need real rows, not just `lesson.words text[]` — new table
      `course_simple.lesson_sentence(lesson_sentence_id pk, lesson_id, text,
      gloss, chosen bool default true)`, since sentences need individual ids to
      edit/delete/toggle
- [ ] `PATCH /api/v1/edit/course/sentences/{lesson_sentence_id}` — edit sentence
      text
- [ ] `DELETE /api/v1/edit/course/sentences/{lesson_sentence_id}` — delete a
      sentence (cascade-delete any exercise built from it)

#### Exercises
- [ ] `POST /api/v1/edit/course/lessons/{lesson_id}/exercises` — add a blank
      exercise manually
- [ ] `PATCH /api/v1/edit/course/exercises/{exercise_id}` — edit prompt/options/
      correct answer (maps onto the existing `exercise.options` jsonb +
      `sentence`/word columns — settle the exact jsonb shape against the existing
      exercise-type catalogue rather than inventing a new one)
- [ ] `DELETE /api/v1/edit/course/exercises/{exercise_id}` — delete an exercise

#### Preview
- [ ] no new endpoint — Preview tab just renders the same `GET .../full` response
      read-only

#### Usage / cost
- [ ] every `generate_poc` response already carries `actual_tokens`/`actual_cost`
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




