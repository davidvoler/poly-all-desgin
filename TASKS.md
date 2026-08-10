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