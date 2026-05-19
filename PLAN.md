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

*** App UX improvements DONE *** 

- modules vertical and lessons horizontal
- design and implement quiz end page. - Done - needs some improvements 
    - repeat lesson 
    - next lesson 


*** Week 5 - Add Audio - Done ***


*** RTL/LTR Language aware  Done ***
- add language awareness of RTL and LTR


*** practice words/sentences - Done ***

REQUIRES DESIGN 

The simple solution
Just create a quiz with exercise from different lessons using a certain word


- implement practice for words and sentences 
- words 
    - search exercise with a certain words - from current course 
- sentences 
    - repeat sentences you have already learned 


*** Week 5 - Course Data Improvements ***

1. limits wring options when creating a quiz - now we have 10
2. identify words - use variable number of words 
3. load lesson - consider loading only a limited number exercises 10 or 15




*** Week 6 - Deploy  ***




*** tasks  ***


## Design

1. different design touch for each question type 


## UI
1. load entire course - all modules 
2. Options
    - auto play
    - Select text type - (diacritic signs in arabic,hebrew - Hiragan, katakana, romanji in japanese  )
    - font size 
3. add explanations to lesson




## Backend


## content creation 

Look for alternatives to tatoeba - it is not great with the repeating names - and simplified sentences. 
Handle a youtube subtitle - this of how to do it 
Create course in  
Create Data for hebrew 
Create


## Editor 
1. define the full yaml structure 
2. search for alternative for yaml that would be great for people 



simple format suggestion by gemini 
original 

=== EXERCISE ===
type: simple
id: 345341121
to_id: 2529262219
voice: /ar/ara/ar-xa_1d7b008f78e3ae12faf005971d454701a25d0961.mp3
words: ها | أريد | ''

text:
أُرِيدَ التَّحَلُّصُ مِنْهَا

options:
[CORRECT] I want to get rid of it.
[-] He wants to expand his Berber vocabulary.
[-] I guess I'm a little antsy.
[-] I want to get rid of Tom.


simplified 

=== EXERCISE ===
text:
مُوسِيقَاهَا رَائِعَةُ
options:
[-] My favorite is Italian.
[-] My favorite is lasagna.
[+] Her music is great.


=== EXERCISE ===
find words in sentences 
text:
مُوسِيقَاهَا رَائِعَةُ
options:
[+] مُوسِيقَاهَا
[-] مُوسِيقَاهَا 
[+] رَائِعَةُ

---
sentence:
أُرِيدَ التَّحَلُّصُ مِنْهَا
options:
[+] I want to get rid of it.
[-] He wants to expand his Berber vocabulary.
[-] I guess I'm a little antsy.
[-] I want to get rid of Tom.
---explanation
some long text with be written here. 
--- words in text
text:
 أُرِيدَ التَّحَلُّصُ مِنْهَا
[+]مِنْهَا
[+]أُرِيدَ
[-] be
[-] bee
[+]التَّحَلُّصُ
--- 
Walking on the moon
[-] مِنْهَا
[-] مِنْهَا
[-] مِنْهَا
[+] مِنْهَا


