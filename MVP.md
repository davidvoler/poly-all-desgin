# MVP - A set of tasks that would enable to go live with the product



### Branch step-11-mvp-phase-1-editor
- [v] Simplify the Dashboard access
  - [W] default dashboard access is to default school
  - [w] login to different school - https://dashboard.polyglots.social/school_id or  https://school_id.dashboard.polyglots.social/
The above solution would allow users to be part of multiple schools and login ech time to a different one with the same user in the system. 

- [v] solve subdomain/domain school
- [] unify dashboard login / app login to a single server api
- [v] load school from url
- [v] save it in a cookie - how save is it? 
- [] use it everywhere - to get courses, lessons etc.
- [] different logic for certain schools - public/any private/invitation
- [p] load user roles/permission 
- [p] invitation join school 
- [p] invitation course  

school tables are quite good - maybe they need a few changes - but mostly the design is ok 
- [w] make a list of changes and needed
- [] user roles - should be json or list
- [] invitation - private - or multiple 
- [] all user data should be in school context
- [] school should use int for id not string everywhere 

Change tables 

activity_log - good - future  - leave untouched 
billing_methods - future - leave untouched 
course_access - in course record - leave untouched 
password_resets - not used for now - we use auth0 - leave untouched 
plan_features - future - leave untouched 
plans - future - leave untouched 
school_invites - require updates - 
school_users - good - a user maybe member in multiple schools - but we will always see a single school context
schools - needed - we also need school icon
student_enrollments - future 
- [w] super_admins - remove - just a role - remove 
- [w] terms_acceptances - needed


- [] hide show elements in dashboard - depending on roles 
- [] hide show courses - depending on school 
- [] consider adding school to secured cookie 

#### ACL

- [v] Simplify editing and co-editing logic 
     - [] Anyone can edit - after signing the term and conditions 
     - [w] Each course has the following states 
          school_id 
          Editing Stage 
          - draft
          - preview
          - published 
          Access State
          - public
          - invitation
          - private ? only for me 
          Co Editing 
          - private - default 
          - Allow copy  
          - Allow All  
- [v] Create the terms and conditions

#### Summary 
when this stage is completed 
- we can login logout to a school 
- we can create content in a school
- we see all the courses we have created 
- We can see all courses that are in review mode - with a review badge 
- We can not see courses in draft mode 
- We can not see courses that are private
#### Estimate 
2/4 full working days 

### Branch step-11-mvp-phase-2-formats
- [] Do we need to add a new question types - like ruby text or annotated sentence?
- [] The export is now a Json - need to export to our format
- [] remove create school for now - hide it - use a script to create new schools 
- [] default school should be the public school 
- [] consider almost valid yaml - we still have to solve the explanation with multi line text 

correct_option: 
wrong_option:
replacing 
option:
correct: true 

### Branch step-11-mvp-phase-3-create-with-ai
*** Complete the Export/Import formats ***

- [] create an example lesson 
- [] improve the create with AI page - add more features


*** Create with AI ***

- [] Try with one of gemini's model
  - [] buy tokens 
  - [] Experiment with a few languages  
- [] Try with open api - ChatGPT tokens 
- [] Add recording functionality with Azure 
- [] Use some hash of the string to create the sentence id - so recording can be used


### Branch step-11-mvp-phase-4-pseudo-payment

*** Payment - research stage ***
- [v] researched the different option for payment 
- [v] There are solution that give you a service of of payment management - the cost is around 3.5% of the fee
- [] For now we should not do payment - but pseudo payment - so we have features -- require payment -- but they will not be open on the web - only when running locally
- [] Create content with AI - Bring your own Agent - BYOA - would be our choice
- [] The ability to charge for our customers - premium content - will have to be delayed. But we will have the options to share private using with invitation code. 

Summary 
- Payment delayed for later stage
- Use your own agent to create content 
- Invitation for private content - no charge for now 


### Branch step-11-mvp-phase-10-final-mvp
*** Final touches ***
- [] Add link in the home page to create content?
