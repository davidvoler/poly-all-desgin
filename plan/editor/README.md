# Editor

This project is an editor for language course 
I have decided replace a single server for student, school management and editor

### Editor/UI
I am re-designing the editor UI 
- Simpler 
- More AI driven - so far we did it in baby steps now we can do create a module - and it will do each steps
- Maybe we do 



### Questions

I want the ui for creating a course or a module look more like claude code or any agent 
- You can type free text 
- Your text is that translated to actions 
    - create exercises of different types
    - choose words for lesson
    - create explanations 
    - break them into lessons 
    - create a module based on a video
The AI should return options 
- suggests words for model - say you have 3 lists and you choose one of them, or create your own list
- suggest explanations for each lesson

### Prompt router - self planned 

- PromptRouter
    - Try to understand user  
    - if you do not succeed 
        - pose question
    - if data is missing 
        - pose show options 

- CoursePrompts
    - figure out the mandatory fields from the prompt
    - offer more options to the user - basic list + show more 
    - create a course 

- Module Prompts 
    - just like course - ask the user for some options 

- ExercisePrompt
    - We have multiple exercises types we want to understand what type of exercise to create
    - We have the module data and know what was created so far and what is needed

- Lesson prompt?
    - do we need a prompts for that stage - is lesson not only a bunch of exercises
    - can we group exercises into lesson later

- VideoPrompt 
    - Show some options 
    - break into sections
    - break sections into parts of speech 
    - generate quizzes

- Utitlities
    - save prompts request for debug
    - handle errors 


#### Architectural design ####
- Easily improve prompts 
    - extended
    - test
    - improve 
- Prompts should have 
    - params for the prompts  
        - word
        - free text
    - system params oc course/module level
        - language 
        - to language 
        - max number of words in sentence
        - free text extending the system prompt


##### UI/UX #####
A simple chat window with not need to have create course/create module button 
We are always in a context of a course/module whoever we change from button interface to chat interface

Pages 
- Chat page - When we are in course context we see the course/module in a tab 
    - the good elements about using chat to create the course are 
        - it is impressive - fully modern AI design
        - it is great for setting specific course related parameters
- Course list page 
- Prompt Monitor

Q. Where do we show the tasks that are not yet completed 
    a. in chat window (and we can continue to the next prompt)
    b. in the context 
        - if we are creating a new module - we show it in the module tab
        - if we create exercises for words - show it in the lesson/exercises

The chat window should have the following structure 
- 2 panes 
    - chat pane
    - course/module pane 
    - review pane 

###### Ideas ######
- add suggestion to a module/course 
    - too many exercises in a lesson
    

##### Backend #####
A user can write anything in the chat 
Prompt Router - what do the user wants from the chat 

                                       _________________
                                       | Prompt Router |
                                       -----------------
                                              |
     _________________    _______________   _______________    ________________    ________________
    | Exercise Router |  | Module Router |  | Lesson Router | | Course Router  |  | Video Router  |  
     -----------------    ---------------   ---------------    ----------------    ----------------                        

     _________________    _______________    _______________    ________________
    | Choice Exercise |  |Explanation  |   | Identify.    |   |Course Router  |
     -----------------    ---------------    ---------------    ----------------   


How to figure out what did the user mean? 
- keywords
- let AI decide
- Show options 

Context
- Course context
- Module context
- Options selected context with original prompt

Logging 
It would be great to save the prompt data into a database
- review the process
- get context for next time with start - go exactly where you left
- improve prompts 


#### Client Server Communication ####
[Client]
- load context (per course, empty if no context)
- Send prompt
    - Prompt Text
    - Context
[Server]
- Identify type of prompt - what does the user want?
- returns Prompt Response
    - task id if a long running task - we will poll on completed tasks and mark them as done, running, failed
    - results if the prompt can be answered without waiting
    - options - if we are not sure what the user wanted - if the current context 
    - description to display prompt window
    - result type 
- Returns option for user to select from


[Client]
    Result type?
        - new course 
            - create the course elements in the course pane 
        - new module 
            - Create the module in the module pane
        - Task ID 
            - show progress spinner
            - poll for task results 
            - reload module when task completes
        - Options 
            - show the options in a clickable manner
            - offer the normal chat to suggest something else


- Prompt procedure 
    - Understand what the user wants 
        - if not show options for the user to select 
    - Extract the data from the prompt 
        - if we are not sure - or some data is missing 
            - offer the user what we understand - so he can correct it
            - offer her to complete the missing data
    - Take the action
        - return the results of the action
        - when action is a long running task return task id

endpoint
POST /prompt
GET /prompt/status  - list of task ids for the current module/course
GET /course/prompt_context - where we have left last time in the course
GET /module/prompt_context 
GET /course
GET /module_full includes all lesson and exercises 


simplified version 

GET /course -  course data
GET /context (course_id, module_id) - last saved context 
GET /module_full - context, module, module element
GET /tasks/status

Questions:
Q. when can the user send the next prompt?
    1. when last prompts has a response - async 
    2. when pending tasks are completed - sync - do not run a new task before older tasks are completed

Q. Can we really simplify the data we pass from prompts and back 
- looks like we have too many classes and types, can we group the together?  

Q. How should we show the debug options 
a. in the same chat window when debug options is selected
b. in a separated window

Q. Do we need a context - or are we saving the entire data in the module/course
a. we could have a prompt history - and get the last prompt 
b. we can save as much data as we can in the course/module
c. consider consulting AI

Q. Maybe it is better to always return Task ID and reload - never return data from a request   
a. The logic is simpler 
    - request - prompt or options 
    - task id - a task id 
    - get status - status should also include what has change and what need to be reloaded - stop spinner
    - reload - reload the data 
b. You do not have edge cases where data is returned directly - but it is partial 





##### Example Discussion ####

p: create a French course
s: would you like to create a new course 
    d: lang: [French]
    d: to_lang [] - What language do your student speak
    d: level [b1] - what is the course level
    advanced options
        audience: []
        age group [] 
p: (filling the missing data)
s: creating the course and the course is presented on the course pane 
    Would you like to create the first module for the course 
p: yes,  please create a module with some greeting words    



### Gemini suggestion for Implementing Multi stage course creation  

### Prompt Router

                          ┌──────────────────────────┐
                          │   User Message + State   │
                          └────────────┬─────────────┘
                                       │
                                       ▼
                          ┌──────────────────────────┐
                          │   PydanticAI Router      │
                          └────────────┬─────────────┘
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        │                              │                              │ 
        ▼                              ▼                              ▼
┌──────────────┐               ┌──────────────┐               ┌──────────────┐
│ Exercise     │               │ Course.      │               │ Module       │
│ Router.      │               │ Router.      │               │ Router.      │
└───────┬──────┘               └───────┬──────┘               └───────┬──────┘
        │                              │                              │
        └──────────────────────────────┼──────────────────────────────┘
                                       ▼
                          ┌──────────────────────────┐
                          │ Return Response.         │ [Data], [TaskID],[Options]
                          └──────────────────────────┘
                                      |
                                      ▼
                          ┌──────────────────────────┐    ┌──────────────────────────┐
                          │ Run Tasks.               │ -> │ Notify task complete     │
                          └──────────────────────────┘    └──────────────────────────┘
                                      |
                                      ▼
                          ┌──────────────────────────┐
                          │ Save to DB               │
                          └──────────────────────────┘





### Tasks & Taskiq
The way we work with tasks
I can see 2 options 
1. The tasks itself is saving results to the db - so even if the use closed the page - the next time we open the chat window the results is there 
2. pass full data back in the results - if not polled the results are lost
3. do both 
    a. save to DB by the task
    b. pass full data in the task so we do not need to read from the DB

```python
#option 1
@broker.task 
async def prompt_request(req):
    response = get_response(req)
    response_id = save_response(response)
    return TaskResponse(response_id=response_id)

async def get_task_Status(task_id):
    res = await broker.result_backend.get_result(task.task_id)
    response_id = res.results.response_id
    return load_response(response_id)



#option 3 
@broker.task 
async def prompt_request(req):
    response = get_response(req)
    #do not wait for db - return the response to be fast
    asyncio.run(save_response(response))
    return response


async def get_task_Status(task_id):
    #results of type 
    results = await broker.result_backend.get_result(task.task_id)
    return results.results

```
We choose option 3 
- it is faster 
    - no need to read from DB 
    - no need to wait even for writing to DB

- It retains the data even if polling failed or page closed 


### The full cycle - architecture

- When page is loaded
[Client] Request chat history
[Server] Load chat history from DB
[Client] Display chat history
- When user start prompting
[Client] send prompt
[Server] starts a task - return Task response request
[Client] poll for results 
[Task] Get response  
[Task] Save  to db
[Task] Return results to results backend 
[Client] Read Results
[Client] Stop spinner
[Client] Show results in chat window 
[Client] Reload course/module data


### Auth simplified
- a new user for each school - if a user is member of multiple schools he simply has a new user record,permission for each school

tables:
user [user_id,school, permission, lang, to_lang]
preferences [user_id,lang,to_lang] - this is needed for learning
We could add preferences as a list into the user record


Later we could think of school record and configurations there

Pros 
- simplicity
- A single use to read from the database
- User contains permission and maybe also preferences 
Cons
- The auth code was complicated - rewriting will be time consuming



## Next steps