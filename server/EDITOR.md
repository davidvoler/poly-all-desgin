# Editor
This is how to edit course 

## Import export
1. we can import a course - created manually or by human or AI or both with a single command
2. We can export the course from db back to a file 
3. We can import again to the same course creating a new revision?

## Editing - with forms 
I can think of 3 options here 
1. full edit of course with add/edit/delete/update for all elements like module and exercises 
2. only publish, and rename course title and descriptions - no detailed edits of modules, lessons and exercises.
    a. Preview for a course
    b. Preview by module lesson
    c. Preview as learner    
3. basic edits of exercise - like we had in the POC created by claude - we can extend it a little - like reordering 


The easiest open is option 2 it really requires - import and export of a complete course.
Option 3 requires is problematic - as we have to know where to stop
Options 1 is easy for planning but it is a lot of code to implement



I suggest we start with options 2

### Revision 

What is the advantage of course revision compared to creating a new course?
1. Suppose you want to edit an already existing course and you want to change lessons, you want to keep history of changes, you want the users to continue the same course but now new modules and lessons are added
2. let multiple users edit the same course and you want to choose the best revision 

Can we skip this for now - for simplification?
