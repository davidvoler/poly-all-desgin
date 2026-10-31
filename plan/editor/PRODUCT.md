# Product

## Editor
- [] in place editing of exercise
- [] reordering?

### Chat page 
- [] better flow 
- [] context for chat 
- [] 

### Content 
- [] shorter sentences - if not existing in text - create 
- [] voice generation 

### Publish
 - [] simple publish button - somewhere in courses

## Student
Shall we recreate the student app are use already what we have 
I am quite happy with the design on the student page - only maybe there i
Can we maybe simplify it further 


/courses - by languages/all
/course/{id}
lessons/ - module id
lesson/{id} - with exercise
? exercises/ - lesson id 

### Review to the old student

I am playing with the old student app anf it looks like it has a lot of great features. 
It was well planned and well thought of 
There is some cleanups to do but it should be easy

A lot of great features were implemented
- annotations
- transliteration

After some research - actually playing with the code it seems that indeed many features and details have been implemented and it would be a good idea to keep the student code for now with minor changes 

The option we have to consolidate new Editor with the old code
1. Editor should save into the old format/database
2. Export Option - Editor will use current DB/Tables and export to the old table
3. rewrite PAD/APP Server  - Read the new format 
4. Rewrite both student app and student server

                | Option 1.  | Option 2 | Option 3 | Option 4 
Time to market  | 8          | 10       | 3        | 1
Clean code      | 3          | 1        | 9        | 10


#### Option 1 - Implementation
- [v] unify both repos 
    - [v]  decide on which - poly-all-design as it has more history
- [v] DDL compare/Merge 1H 
- [v] find replace course -> course_simple 1H
- [] move the database
- [] Rename exercise types 
- [] Test ad fix gaps 4H
- [] Extra 9H 

- [] Change format of options 
this is how options is defined in PAD
```json
[{"text": "Tobias rushed down the stairs."}, {"text": "We started according to plan."}, {"text": "We heard him come downstairs.", "correct": true}]
```

This is how it is defined in Editor:
```json
{"correct": ["פריחה כלכלית, קפיצה"], "incorrect": ["בקתה", "בריחה", "חדשני, יצירתי"]}
```
I thinks that we should follow PAD


#### Options 2 Implementations 
 - [] Write a script the exports data from Editor to the PAD/DB
 - [] Run both DBS on different ports 
#### Options 3 Implementations 
 - [v] List all code that need
 - [v] DDL Compare/Add missing fields to Editor 
 - [] Copy server from PAD and remove models/routers 
 - [] Adjust and simplify existing models/routers
#### Options 4 Implementations 
- [] Create a new app
- [] Create a new server 
- [v] List all code that need
- [] Copy server from PAD and remove models/routers 
- [] list client features
- [] select features
- [] implement client features 



#### Questions 
If I would have start the process from new ?
Q. Would I plan to different databases for editing and student - or I would keep one with a field indicating editing status

Q. What features I would remove/change from current client?
- words in sentences - there are 2 types one is ok the other should be removed or fixed - single selection should change to multiple selection
- [] Add video module/lesson - the name of the current git branch is video - I do not know how much of the video was implemented 
    - [] 
- [v] Data is incorrect - exercise type 
- [] By words has errors
- [] by sentences returns always the same sentences - ad random


Q. What is the number of endpoints used for the current client

All **17 endpoints observed in the retained server logs**, ignoring query parameters:

| Endpoint | Requests | HTTP Status |
|---|---:|---|
| GET `/api/v1/course/` | 5 | 200 |
| GET `/api/v1/exercise/` | 3 | 200 |
| GET `/api/v1/lesson/` | 5 | 200 |
| GET `/api/v1/module/` | 4 | 200 |
| GET `/api/v1/practice/by_sentences` | 1 | 200 |
| **GET `/api/v1/practice/by_words`** | **11** | **500 ERROR, all requests** |
| GET `/api/v1/practice/words` | 1 | 200 |
| GET `/api/v1/preference/` | 2 | 200 |
| GET `/api/v1/user_stats/` | 5 | 200 |
| OPTIONS `/api/v1/lesson/completed` | 1 | 200 |
| OPTIONS `/api/v1/preference/` | 1 | 200 |
| OPTIONS `/api/v1/user_data/` | 1 | 200 |
| POST `/api/v1/achievement/check_new_achievements` | 1 | 200 |
| POST `/api/v1/auth/login_with_cookie` | 2 | 200 |
| POST `/api/v1/lesson/completed` | 1 | 200 |
| POST `/api/v1/preference/` | 15 | 200 |
| POST `/api/v1/user_data/` | 30 | 200 |

Only `/api/v1/practice/by_words` returned errors. Its recent traceback shows an `Exercise` validation failure: `options` received `{}` instead of a list.



### Home page 
- Remove the sentences demo button 
- remove the 
- remove or hide the 
- The words buttons should go to the words demo


## Business Model


## 