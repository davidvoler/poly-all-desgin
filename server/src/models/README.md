# Modules 


Scenario
1. load preferences + statistics + current course
 a.course has modules and lessons in it
 b. course is kept in the system until we change course - from there we have the list of lessons and their status
 c. for each lessons, module and course we have user status 
 d. statistics is per languages (words, sentences), course (lessons) 
2. save data - single record concept 
a. the problem - in single record we can have one word - per quiz
    - we could think that a sentence is always teaching a single word and its usage - we do not care about other words
    - we can save 2 records - bu then how do we calculate the mark value? shall we split it into 2? or 3 depending on the words?
    - we can save words a separate table
    - have word1, word2, word3 - use union - no simple as we need a simple algorithm to set words always in 1, 2 or 3

2. when no course - or languages are present - show course page

3. when course changed - create or use a new record 


Do we need a Model on the server side - or at the early stage just do sql and model on the client side?
