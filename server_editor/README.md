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