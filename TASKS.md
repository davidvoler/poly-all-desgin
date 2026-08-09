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

- [] When we create a course the first time call /generate_course
- [] We get back the text and 2 options 
    - [] create words 
    - [] Create leson
- [] We can click on each and get the results 
