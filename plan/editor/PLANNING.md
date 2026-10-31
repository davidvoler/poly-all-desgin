# Planning 
## New Chat framework
- [v] Get the framework to work client and server 
- [] Initial complete course creation 
    - [] create course/module/lesson
    - [] create words 
    - [] create exercise for words  
- [] Video support 
    - [] handle video module 
    - [] break to sections 
    - [] break to parts 
- [] History of chat
- [] The debug should be readable and can be used
- [] A mechanism to improve the cycle of prompts improvements - with AI 
## Improve results 
- Improve on the prompts
- Verify the prompt router  
## Editing & Adding exercises
- Edit Exercise 
- Add by exercise type 

### Ideas 
- let the user after chat rate
    - how well the AI understood what she wanted
    - The quality of the content

### Question on how to proceed 

Q. let claude copy code from old repo
A. No, Design the new architecture

Q. I embarked on the cleanup project - Should I give it up and go back to the working version and improve it there?
A. Old code is not manageable - continue with the cleanup 

Q. When would it be time to pay for more expensive Claude subscription and continue with the code
A. When I have a good working architecture on the server side and I want to speed up the development cycles

Q. Should I keep auth for later
A. Yes

Q. Should we separate the data to multiple schemas 
- content - sentences and words 
- prompts - prompts request responses
- users - already in a specific schema 
A. Maybe - but it would be easy to do it at any time 
Q. Should a prompt options should be of type PromptsRequest 
 - this way the is almost no login on the server side
 - we should let the clint know somehow that it is an options 
  - but maybe we can prepare the entire request for the server
 - Words for example - the client should know where to load the words for the course/module 
- We do need for the client to do some composition when create a prompt request. Let's look at it and this what would be the best way

- course id
- module id 
- lesson id
- words 
- user prompt text

List of words - we could read it in the server side 
words - if we collect it on the server side it saves us extra read form the client and than send to server
What do we do when we want the user to select specific words for the exercise?
How do we order words? 

Option1 - sent from the client
[Client] Read words for module - for display/order/delete 
[Client] Add words for each Prompt
[Server] Use words send to make decisions

Option2 - red by the server
[Client] Read words for module - for display/order/delete
[Client] Generate a prompt without words
[Server] read words from DB
[Server] Use words to make decisions 

Options 2 seems somewhat better only that requires an extra read from the database


Q. I have options MODULE_CREATE_SUGGEST_WORDS - I create a module and than suggest words 
I need it because I need the module ID for suggesting the words
I thought of the following options 
- prompts should revive a list of prompts request
- We should create prompts type for complex requests 
In this case we do need the module id for saving the words 




### Course Context - or PromptContext
When working on a course we should have a context 
The current course/module/lesson ids 
The next time we open the window we know exactly where we were 

How do it work 
When a user opens a new course 
We do not have a module of lesson 
The get or create context - will create the first lessons 
When user chooses to add a module 
The client will move the  
[client]create course 
[client] get_or_create_context
[client] add lesson -> get_or_create_context
[user] select a different module/lesson -> save context


Q. Should we include words in this context
- For - a simple read when ever we need context
- Against - simplify calls to the server 
