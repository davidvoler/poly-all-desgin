# PLAN

*** Goal ***

Design a step based plan for getting to some target every week

*** Week 1 - UI/UX - DONE ***

- [v] create tables 
- [v] decide on the type of exercises 

- listen and select options
- annotated sentence - annotate all 3 specific words 
- words in sentence
- explanation

- [] start generating a course for arabic

- maybe we need to add a new field for the text with diacritical signs (use python library)
- In Poly_all we did not break arabic to elements - maybe we need to do it again 
- Do we need to break words into elements? 


The process of implementations 
1. break into words - simple
2. select words per sentences - least frequent words 
3. create annotation - with the 2-3 less frequent words
4. select most common words
5. remove manually some words that are too frequent
6. select words order per lessons - do it once using export
7. remove non-arabic words 

8. for arabic - before we break words we should clear diacritical signs - currently we have to many words with the same letters with different sign - pron

The generation process 
start with greeting lessons

for each sentences create - ex_listen
if words count > 3 
    - create annotated text - select meaning for each sentences 
if words count > 4 
    - create ex_req_words




*** Week 2 - Data Structure  - Done ***

*** Week 3 - Example Courses - Done ***

*** Week 4 - Course Learning End to End - Done ***
*** Stats Done ***
Implement basic stats in home page 

*** App UX improvements *** 

- modules vertical and lessons horizontal
- design and implement quiz end page. - Done - needs some improvements 
    - repeat lesson 
    - next lesson 


*** Week 5 - Add Audio ***

*** Week 5 - Improvements ***

1. limits wring options when creating a quiz - now we have 10
2. identify words - use variable number of words 
3. load lesson - consider loading only a limited number exercises 10 or 15


*** practice words/sentences ***

REQUIRES DESIGN 

- implement practice for words and sentences 
- words 
    - search exercise with a certain words - from current course 
- sentences 
    - repeat sentences you have already learned 

*** Week 6 - Deploy  ***


