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
- [] First step - inspect the prompt and improve it 
- [] Try it with different AI
- []  


#### Phase - Preview 

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