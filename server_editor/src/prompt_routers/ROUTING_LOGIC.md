# Prompt router 

## Prompt source
When A new prompt in ingested it can be 
- a prompt by the user
- an options - previously generated 

## Context Data
The data the prompt has 
- course_id|None
- module_id|None
- lesson_id|None
## Options Response when context data is missing
If one of the above is missing we should have an option to 
 - create one by one 
 - create all course with the first module and the first lesson
## Extra data
- words for creating an exercise
- sentences for creating an exercise
## Course words 
- We can have a list of course words - that we can load from the database or get them from client
- when do we need the course words 
1. in the main router - offer to add words 
2. when creating exercise/sentences for words 

### main router

no course_id -> pass to course router
no module_id -> pass to module router 
no lesson_id -> pass to lesson router
no words -> vocabulary router
video url -> pass to video router - before we break into section and parts
else:
Exercise router

### Course router
- create course 
- create a course with options 
    - edit course options ? does this require a prompt? maybe a simple edit? 
### Module router
- create a module 
- create a module with options 
### Lesson router 
- create a lesson
### Exercise router
- exercise_count > 12 -> offer to create a new lesson./ or automatically move to the next lesson
- create lesson for words - lesson types 
- create a different lesson type from an existing lesson


