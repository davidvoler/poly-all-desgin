# MVP - A set of tasks that would enable to go live with the product

### Branch step-11-mvp-phase-1-editor
- [v] Solve the school/public - Concept Data and Auth procedure 
  - [v] Concept - what is a school and when do we open a new one 
  - [v] DDL - Add missing fields to school Table
  - [v] school has a specific domain subdomain 

### Branch step-11-mvp-phase-2-dashboard
- [v] unify dashboard login / app login to a single server api
- [v] remove create school for now - hide it - use a script to create new schools 
- [v] we need user prefs per school 
- [v] login logic
- [w] implement login logic with invitation
- [] consider creating a single auth-preference element including 
    - school
    - user
    - school_user + roles
    - preferences 
    If we have this object on the server side we have all the data - to make decisions on the server side 
- in this phase we care mostly about public school - let's concentrate on these features 
- [w] redo dashboard api
- [] hide show elements in dashboard - depending on roles 
- [] hide show courses - depending on school 


### Branch step-11-mvp-phase-3-formats
- [v] Simplify format creation - move the fields into a separate file - create a map of fields 
- [v] Simplify import 
- [v] Export - save as import 
- [v] export db->yaml 
- Changes
  - valid yaml sections 
  - single file for course 
  - course in order 
- [v] export from db to yaml - should skip some fields  
- [v] find a solution or course and course version


### Branch step-11-mvp-phase-3.1-full-editing-process
Now it is time for some tedious work - that not all of it can be automatic or done with claude  

- [v] flutten routes/modeuls on server side
^ not exactly flat as we do have a sub folder edit in models routes and utils
- [v] create new  routes. models and utils for edit 
- [v] create the scenario in a readme - so we do not implement every possible option  


## mvp-phase-3.1.1-full-editor
We will currently skip this options as it is a lot of work. 

## mvp-phase-3.1.2-import-export
This is for now the chosen option 
We currently skip revision
- [v] make a list of the needed endpoint
get /edit/courses - list of courses I can view in editor
get /edit/course/course_id - change course elements - like title. description, publish, un-publish
post /edit/course/course_id - change course elements - like title. description, publish, un-publish
delete /edit/course/delete -  delete course 
post /edit/course/import - import a course  
post /edit/course/export - export a course 
- [v] import course
- [v] export course
- [v] create a course - verify that is is saved to the current user and current school
- [v] verify that you that courses are created with current user_id/school_id
## mvp-phase-3.1.3-partial 

#### optional
- [] consider renaming schema course_simple to course
- [] simplify and edit state in course 
### Branch step-11-mvp-phase-4-create-with-ai


#### Phase 1 prompt generation 

- [v] Verify that prompt code is correct with the new update. 
- [v] Verify that  prompt generator is dynamic
- [v] Add the new format: content/example_course.yaml
- [v] Add all current question types
  - [v] single_choice
  - [v] multiple_choice
  - [v] description
  - [v] annotated_sentence
  - [v] words_in_sentence
- [v] Add words limits (min.max) words in sentences for each module 
- [v] Add free text section to the generation - so user can add here own comments to the prompt. 

#### Build in steps 
- [] Suggest to do it in 2 steps 
- [] first words selection than the actual module and course 
- [] preview 
- [] modules by modules
- [] Names - Suggest a a combination of 70% native names and 30% common names 

#### Phase - build on movie subtitles 

We have the following endpoint on the server side

api/v1/edit/youtube/info/{video_id}
in which we get info an a video id

api/v1/edit/youtube/download_subtitle
in which we ask the server to download the subtitles in a given language, break it to lines with start and length,break into sentences and list unique words 

With that we can go to AI and ask to generate a module/lesson on this video
We can also do it in steps - so if movie is 60 minutes we can break it into 5 minutes steps and have the 30 steps. 


- [v] we are currently implementing the solution only for youtube movies 
- [v] first step would be to download the subtitles 
- [v] the movie should have subtitles in the language the course is teaching. 
- []  if the youtube film does not have subtitles for the learned language - we can not continue - and we ask the user to select another movie 
- []  after we have downloaded the movies 


#### Phase Testing the Prompt

- We are generating a prompt - and it look like the right time to start to test it.
- [v] First step - inspect the prompt and improve it 
- [v] Try it with different AI
  - [v] try with Claude 
- []  

#### Claude 
##### Create a course with a single prompt 
- The course is quite short 
- The hints are not great 
- Sometime there is only correct options 
- Format is sometime correct - sometime incorrect

##### Create from subtitles 
Seems like the task is misunderstood - the prompt is probably wrong 
We probably to define the task in a better way 
- instead of creating sentences and translation - claude creates understand sentences from the content
maybe the problem was that we have chosen the level of the course 
Maybe we need to describe specifically that we need 
- word and translation
- sentences and translation

Lets describe the work needed to be done with subtitles 
- cut the srt into separate sentences, or phrases - can be done with or without ai
- choose difficult words  (can also be done without ai) - (without AI is simpler)
- Translate - we can do it with AI or with google translate - or alternative 
- Generate Questions of the type we have described - Would be done in a better way with Python
- select wrong answers - maybe AI will do it in a better way 

What would be done best with AI:
- Generate sentences with a given word
- Translate to student languages? 

#### Generate with AI Phase 2 

- We need to break it into small steps 
  - module step 
  - lesson step
- We need that the import would support the smaller steps 
- We have to define what is done with AI and what is done with the backend
- We have to be more specific with the AI and give it exact commands


##### Generate from SRT
- [] list of end points 
- [] tasks break the youtube movie into separate section 
- [] break the text into parts, sentences and phrases 
- [] select the difficult words in sentences - using zipf algo - with limits on minimum
More likely done with AI
- [] Generate more sentences on a give word
Translation 
- [] translate words and sentences - if possible with context 
Voice 
- [] generate voice for the parts

What do we do on the backend with subtitles 
- break it into section (60, 120,300 seconds each)
- break the text into sentences 
- break the text into phrases (currently using comma but later we can do it with Spacy)
- select words - (using zipf min - max )
Exercise creation
- parts and sentences that are shorter than 12 words - single choice
- identify words in the video itself - when played - limit words per line 1/2  
- annotated text for long sentences/parts - also up to 22 words 
- some identify words in sentence when in the short sentences 
The results of such a process can be 
1. the raw data that we have generated - not creating the exercises yet. 
2. also create the exercises 



#### Phase - Preview 
Thinking of a demo the preview is super important
- [] how do we implement preview?
  - [] in the student page 
  - [] in the dashboard
#### Phase - build on existing text 



#### Phase - the complete process 
- [] Should we try with gemini api/claude api/others? 
- [] Research MCP - How it can be used and how - Does it apply to polyglots case - do we need an MCP server
- [] Implement the Dashboard create with AI - with or without MCP 

### Branch step-11-mvp-phase-5-payment
- [v] researched the different option for payment 
- [v] There are solution that give you a service of of payment management - the cost is around 3.5% of the fee
- [] For now we should not do payment - but pseudo payment - so we have features -- require payment -- but they will not be open on the web - only when running locally
- [] Create content with AI - Bring your own Agent - BYOA - would be our choice
- [] The ability to charge for our customers - premium content - will have to be delayed. But we will have the options to share private using with invitation code. 

Summary 
- Payment delayed for later stage
- Use your own agent to create content 
- Invitation for private content - no charge for now 


### Branch step-11-mvp-phase-10-final-mvp
*** Final touches ***
- [] Add link in the home page to create content?
- [v] Create the terms and conditions


### Learn with youtube 
- [] show the youtube movies 
- [] show question before a section
- [] show section after a section
- [] identify words while the section playing 

### Demo steps 
- Create with AI
  - create based on a youtube text 
  - create in iterative steps - maybe lessons 
- Show the course created - do some small edits  
- Preview the course - maybe still in the dashboard 
- Publish
- Show it in the student app


#### - After vacation and some thoughts 

Claude created a lot of question style exercise 
What are fruits of the following list

We should tell the AI only sentences and translation. 

When we look at length of sentences most of them are too long for an exercise 
We can ask AI to shorten the sentences - Or we can use the breakable sentences 


#### - Demo oriented 

If I want to demo the app I should have the full process visibility
- Use AI to create course - End to End 
- Use API to create course and count tokens 
- Show the course Online   

What do I need to get to this point?

- BYOK - this will be the option for the demo
- You tube based learning - We need to add it to the student app. - optional
- Use internal data to create courses?


#### Full account management 
- Use API key and pass - Store somewhere secured 
- Reporting on token usage per key - for each action
- Accounts ? 


#### Create with AI - Round 2 

So far I have a skeleton for creating content with AI
- It it only produces commands for AI on how to create the content
- The commands are not detailed enough as AI generates Questions instead of sentences and translation
- We need to create module by module or even lesson by lesson
- It would be great to have an integrated process from AI directly to preview and save. 


- [] Improve Instruction for AI - so it generates only sentences and translation - multiple meaning should be rare - or skipped in learning stage 
- [] Plan the lesson by lesson/ module by module UI/UX
- [] Plan the by words process - select words and use them in sentences 
- [] Implement the above plan
- [] Implement word selecting stages 
- [] BYOK - implement with this locally not on server 


##### Youtube learning 
Learn with youtube is great - especially for learners with higher level
What are the tasks that required implement learning with youtube 

- [] Plan the UI/UX
  - [] Show video
  - [] Show question 
  - [] Show video with identify words - so we should have space for the video and word selection area
- [] implement the AI for creating a lesson based on a video


##### Planning UI Create course step by step
- [] Create course - initial page 
- [] Select words - optional we can select words lesson by lesson
- [] create module page 
- [] Create lesson page 
    - [] words so far
    - [] Words for lesson
    - [] generate sentences 
    - [] generate exercises 
    - [] preview lesson - add/remove/edit exercise
    - [] preview as a student
- [] List lesson in module 
- [] List Modules in course 

Can all this be translated to a an Agent interface?

We have the following pages

#### Using TMUX with Claude Code

1. I have a lot of tasks and idea - usually the ideas are faster the development 
2. On the other hand - I can not really parallel tasks - As they I may want to test some of the concepts first and see how they work 
3. We can think of Claude Code with TMUX when
  a. The concept is clear 
  b. We have a set of small tasks

#### High Level Tasks
1. Cleanup - Priority 1
  a. Replace course_simple with course 
  b. Remove fields that are not used
  c. Remove remove older files 
  d. DDL last version only  
2. UI/UX + The process for creating course with AI - Priority 4
  a. How does the initial UI/UX looks like  - From a single chat - to a complicated forms 
  b. What are the processes that we have to do (Agents, google translate, Azure text to speech, Internal logic)
3. Adding learn with Youtube - Priority 3
  a. Adding the UI/UX
  b. Adding the data structure (lesson,exercise)
4. Connect to real AI Agent - Currently BYOK Priority 4
  a. Create a key for for Gemini and learn how to use it 
  b. Add to the code where and how to save the key


##### Create with AI UI/UX
1. A chat window - response might require options and selection 
2. Form page with more specific selection 
3. A combination of the above - enable both

##### The AI processes under the hood 
1. Generate sentences from words 
2. Translate
3. Extract rare or difficult words 
4. Text to speech
5. Reuse - Should we have a databases of sentences already created 
6. Save new sentences and words in a table 



H. = human
M. = Machine
MI. Machine Implementation
SEL = Lets the user select from options  

The process 
H. Create for me a course that teaches Japanese for Hebrew speakers 
M. Select Level
H. Complete beginners 
M. Leta's create an example lesson, We can start with the following words
SEL.
  [] - WORD1
  [] - WORD1
  [] - WORD1
  [] - WORD1
  Add Word
H. Selects the words, Or adds his own words 
SEL. Here are the sentences
  [] - Sentences 1 
  [] - Sentences 1 
  [] - Sentences 1 
  [] - Sentences 1 
  [] - Sentences 1 
  Add sentences 
H. Select the sentences or removes un used sentences 
M. Here is the the first lesson
  - The lesson with types 
  - Link to view lesson as a student
M. Would you like me to create next lesson
SEL. 
  [] - Create next lesson
  [] - Create the first module 


#### The Generate Process - Components  

- [UI/Prompt] 
- [EnrichmentLayer] - Add instruction to the model format/tasks/Sentences length /etc
- [Cache] - Get words and sentences from cache
- [ExternalModel] - Generate sentences for words/Translation?
- [Translation] - Google Translate, model 
- [TextToSpeech] Azure text2speech, google text2speech
- [GenExercise] From sentences 
- [SelectWords] - We can use zipf - or tatoeba - or combined words 
- [InternalLogic] - Rank words, break sentence words, etc
- [CostsEvaluator] - Estimated costs, Actual costs. 


                   [UI/Prompt]
                   free text - I want to create a Japanese course for hebrew speakers
                   -- Should use AI to understand the free text -- 
                   
                [CostsEvaluator]
              [EnrichmentLayer] 
            [Cache] [ExternalModel] 
            [InternalLogic]
            [Translation]  [TextToSpeech]
            [GenExercise] 

When working with this structure 
We can really simplify the model task - it is only about generating sentences 
However we could allow the model to do more work - but it seems that breaking tasks 
- generate question
- create sentences from model
- add sentence description 



- This is an example when we want to use multiple choice - When a single lesson can have multiple translation 
- Also when theses translation are quite similar and we want to show that there is no differences 
I want a flower
花が欲しいです。
Hana ga hoshīdesu.

I want flowers
花が欲しいです。
Hana ga hoshīdesu.


#### Reuse content 

- Do we want to reuse ? If I payed for Agent - do I want to share it with others
- If we have the school concept - probably reuse is solved 
- We can define that in the public school - reuse is mandatory 
- How can we avoid that when I create a course with the save requirement like someone else - I would not get the same words and sentences 
- Maybe adding a randomization would help - in multiple processes 
- Maybe we can give a discount if you are willing to share your sentences with other. 


#### Potential Alpha Users 
- Show it to others
  - Tali - Bat Doda
  - Yishai Mor 
- Open it on the web to limit use. 
- Look for more potential users 
What is the effort needed for each of the following 




