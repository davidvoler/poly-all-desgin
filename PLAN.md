# PLAN

*** Goal ***

Design a step based plan for getting to some target every week

*** Week 1 - UI/UX - DONE ***

- [v] create tables 
- [] decide on the type of exercises 

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

*** Week 4 - Course Learning End to End  ***

*** Week 5 - Deploy  ***


