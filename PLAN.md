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


*** Week 5 - Course Data Improvements - Done ***

1. limits wring options when creating a quiz - now we have 10
2. identify words - use variable number of words 
3. load lesson - consider loading only a limited number exercises 10 or 15


*** Editor - DONE  ***
1. define the full yaml structure 
2. search for alternative for yaml that would be great for people 
3. implement simple export 
4. implement simple import 


The current import export assume a single minimum 
that exercises are separated by a ---

Done implemented a real simple format 

folder 
course/module/lesson.txt

TODO: course and module description 

---simple
دَعْنِي أَحَصِّلُ عَلَى اثْنَيْنِ
[+] Let me get two.
[-] Let's plan it.
[-] Yes, let’s do it!
---

*** Youtube usage - .srt file - Started ***

- [v] download srt format
- [v] break the text into sentences 
- [v] break the video into time line - say 5 minutes each
- [v] generate question 
- [] handle multiple translation for a given language 
- [] extract zipf words  

*** annotated sentence ***

implement annotated sentence in text 


***  Design ***
1. different design touch for each question type 



*** UI ***
1. [v] load entire course - all modules - done
2. Options
    - auto play audio
    - Select text type - (diacritic signs in arabic,hebrew - Hiragana, katakana, Romanji in japanese  )
    - font size 
3. add explanations to lesson
4. Add description of the task 
    - select a single translation
    - select all the words you hear in the sentence
    - select all correct answers 
5. words page
    - practice words when selection 
    - server - show words in the order we have learned them
6. correct/incorrect notification 

7. Lesson Complete = Page 
- [] skip - should get you to the end of lesson end ot practice page
- [] calculate mark on client side (or serer side can return mark) - show mark after each question - show real mark where the heart icon on top
- [] end of lesson - show some data on lesson - how many exercise were answered correctly, how many wrong, how many skipped and the final score of the lesson
- [] show list of words in the lesson - optional
- [] recommend: on repeat - or next lesson



*** content creation *** 

Look for alternatives to tatoeba - it is not great with the repeating names - and simplified sentences. 
Handle a youtube subtitle - this of how to do it 
Create Course in  
Create Data for hebrew 
Create German
Create 
Arabic course 
    - the diactirization is not great do not use it for now 
    - prefer sentences with sound


*** implementing school ***

- [] UI - requirement - show the school somewhere in the home page - maybe in the round area 
- [] UI - list of languages for school only 

- [v] Decision - for now schools is supported only in db and ui - later on we can get school from url
- [v] server - course search will require school context 
- [v] DB - Add school to course
- [v] DB - Add school to users


How to manage schools 
- course only - single site - url - schools are part of the course 
- school on a completely different domain/sub domain



*** course completion ***

maybe we should go simple 
When a user finises write it in the db 
course,module,lesson
alternative - get it from results
we need number of lesson and exercises to do this calculation

*** student motivation *** 

First principle: reward *retention*, not *attendance*.
Streaks are intentionally OFF the list — they reward consecutive presence, 
encourage minimum-effort daily clicks, and the loss-aversion when a streak 
breaks often drives quitting (not retry). We want signals that reward what 
the student can still remember, not how many days in a row they tapped in.





Memory-aware metrics (the streak replacements):
- [] "Words you can still recall" — distinct from "words you've seen".
     Re-test old words on a spaced schedule; count the ones still recalled.
     The home stats card today shows mastered counts only; add the gap as 
     a separate signal.
- [] Today's recall % — how well did you remember yesterday's lesson today?
     Honest number, immediately actionable. Low values do NOT punish; they 
     just suggest a re-warm session.
- [] Long-dormant-word celebration — when a word last seen 30+ days ago is 
     recalled correctly, a small inline "you still know this!" moment. 
     The data is already there in user_data.results.
- [] Forgetting-curve calendar — small visualization of what's about to 
     fade. Informative, not punitive — no streak-loss feel.


Identity & autonomy (why are you learning?):
- [] On-boarding question: "Why are you learning <lang>?"
     travel · family · faith · work · music · curiosity. Bias lesson order 
     and messaging accordingly.
- [] Self-set monthly goals — "Order coffee in Hebrew without English by 
     July", "Read a newspaper headline". Mid-arc feedback on trajectory.
- [] Daily practice menu — let the user pick today's mix (more listening / 
     reading / speaking). Autonomy is itself motivating.


Re-entry warmth (the anti-streak):
- [] Welcome-back session — when you return after a break, the app 
     re-warms 5-10 old items before any new material. No counter reset, 
     no guilt screen. The longer the break, the warmer the welcome.
- [] Soft cadence — "You aim for 3 sessions/week" shown as a rolling 
     4-week average. Missing a week dips the average, doesn't zero it.


Earned content (intrinsic, story-driven):
- [] Story-arc courses — when you master a unit, unlock the next chapter 
     / verse / recipe. Polyglots Open's "Cooking with Imma", "Songs & 
     Lyrics", "Biblical Reader" format already fits this. Curiosity 
     drives return — "what happens next" beats "don't lose your streak".
- [] Native artifact unlocks — short videos, news clips, real letters 
     tied to mastery thresholds. The *content* is the reward.
- [] "You can now read…" prompt — at each level threshold, surface a 
     real-world sample they can actually understand (a sign, a tweet, a 
     menu, a song lyric). Concrete proof that the work pays off.


Small social loops (no leaderboards):
- [] Study buddies — pair two learners by language + level. They see 
     each other's progress; it's a duo, not a ranking.
- [] Family circles — small private groups (grandparent + grandchild 
     learning Hebrew together is a real motivator we haven't surfaced).
- [] Note from your reviewer — when a course reviewer notices a 
     student's progress on a course they made, send a small personal 
     encouragement. Intermittent, human, not gamified.
- [] Share-a-sentence — record yourself reading a hard sentence, share 
     to your private circle. Intrinsic pride, not extrinsic ranking.


Hearable / visible growth:
- [] Voice diary — record yourself on day 1, day 30, day 90. Let the 
     user *hear* their own improvement. Likely the strongest intrinsic 
     motivator on this list.
- [] Memory map — visualization of the words/sentences you can recall, 
     grouped by domain (family · food · travel · faith). A growing 
     artifact, not a counter.
- [] Compound projection — "at this pace, in 60 days you'll know X 
     more words". Forward-looking framing instead of retrospective.


Milestone notifications (the original item — expanded):
- [] First 100 words owned
- [] First sentence read fluently (low error, decent pace)
- [] First time recalling a word after a 30+ day gap (memory milestone, 
     not effort milestone)
- [] First completed module / course
- start from design — same visual treatment as the existing 
  quiz-completion screen; trigger at exercise/lesson end so the 
  celebration lands at a natural pause point.


Evaluate carefully, may regret:
- [] Variable rewards on hard items — leans into gambling mechanics if 
     overdone; use sparingly and only for genuine surprise difficulty.
- [] Public profile / authored-course pride — more relevant to 
     school_public than the consumer app; keep an eye on whether 
     "showing off" undermines intrinsic motivation.


*** School dashboard ***

- [v] select languages
- [v] create content example download and upload 
- [v] add students - invite by email
- [v] basic student board

- [] database
- [] UI implementation 
- [] server implementation 

*** public content dashboard *** 

- [v] initial design
- [] database
- [] UI implementation 
- [] server implementation 




*** DB Changes ***
- [] replace mark with score

*** Week 6 - Deploy  ***


TIME FOR DETAILS - LET'S COMPLETE THE UI. 