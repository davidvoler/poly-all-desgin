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
post /edit/course/import - import a course  
post /edit/course/export - export s course 
post /edit/course/delete - export s course 
get /edit/module/course_id - show a list of modules per course 
get /edit/lesson/course_id/module_id - show a list of modules
get /edit/lesson/course_id/module_id/lesson_id - show lessons details


- [] create a course - verify that is is saved to the current user and current school
- [] verify that you that courses are created with current user_id/school_id
## mvp-phase-3.1.3-partial 


#### optional
- [] consider renaming schema course_simple to course
- [] simplify and edit state in course 


### Branch step-11-mvp-phase-4-create-with-ai
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