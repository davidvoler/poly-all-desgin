# Server Editor

We want to create a separate server for editor and student
There is some common functionality however most of the code is unique and separating it would ease the development

### Guidelines 

- Smaller files 
- Try to use pure function where possible 
    - Separate saving to DB logic from the actual generation

- Folders 
    - routers 
    - models 
    - utils 
    - tasks
        - long running tasks with task manager such as taskiq 
    - generate? need a better name - Do we need it?- We can simply use utils 
        - complex code that requires complex logic 
- Get data in chunks - do now load a full course but 
- Testing 
    - We need a way to implement tests 



### Process


#### Comparison to current version
- load module by module or even lesson by lesson. no need to load an entire course 
- 

### Scenarios 

1. Create course
 - basic configuration 
 - generate course words - we can add words later in module
 - Some options 
2. Generate Module 
 - words for module - can start from course - or add new 
 - add words already used in course - if we generate a sentence for the word "cat" The cat with the hat. we can now use the words "hat"
 - options 
    - number of sentences per word 
    - number of words per lesson 
3. Generate lesson
 - Show process for each word and sentences created 
 - Show when completed

4. Course Words section 
 - words generated 
 - words used in sentences  
 
### Question:
- Do we need a wizard UI or a simple chat will do?
