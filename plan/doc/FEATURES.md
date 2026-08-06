# Plan

*** goal - Focus ***

Focus on a an app that looks good and the UX is simple enough
- Try to get there in the shortest way 
- skip any other gaol to get there if it can be skipped and we still reach this gaol



*** Done - Goal 1 Initial  UI/UX - initial design, basic implementation ***
 - create UI/UX that looks good and can be used 
 - create multiple version 
 - choose best version and convert to flutter  


*** Goal  - course - lesson structure ***
Define how a course should look like 
We can import a course into the system in the following formats
- yaml
- csv
- json
Find example in context


*** Goal  User data structure ***

List of fields 
The problem 
until now the user data was word, sentences oriented 
now that we are course based - we need need to save data on course/module/lesson level
Do we do both? 
word level
course level?

Can we keep the single record per value that will include many fields

if each quiz has its words we can save a single records 
user, course,module,lesson, word, sentence
For this single record we can extract everything


*** Goal Practice ***

How does a user practice what he has already learned ?
Where are the practice buttons located ?
Clicking on words, sentences - will open the words or sentences pages - where the students practices her latest - words and sentences. 

*** Goal  Level Test ***
Course level tests - A 

*** Goal Initial end to end learning process - complete UI/UX ***
- automated course generator from existing data - or manual

- quiz types
    - words 
    - sentence -  identify words 
    - sentence - hear and identify meaning 
    - annotated sentence - identify meaning 
- encouragement - when students reaches a simple milestone - every 50 words 

*** Goal Reactive encouragement ***
- design the UI/UX of the interaction
- Decide what are the milestones
Notify the user when she reaches a certain milestone
