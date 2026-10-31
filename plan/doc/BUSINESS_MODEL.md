# Business model 


*** PLAN ***
- [] What are the options for business model?
1. SAAS - provide the system for languages schools and schools with white labeling the apps 
2. Single site where you can open a virtual school and send invitation to members or manage subscription 
3. open content when any one can create courses and share it with everyone else - people can contribute some money for maintenance 
4. Private teachers - create content for your student - follow up on them - this platform can act as an enhancement to private lessons
5. parents and kids - use the platform to create content for your kids - find ways to encourage them on progress 
6. Pay only for content creation while learning is free - try to get funding for open content - maybe wikipedia funds or anything like that 
- [] What would the easiest path to start - I like the idea of open source / open content - I am looking for a way to func the project 
- [] Maybe we need a path - start small and grow - start with schools - maybe public schools with no intention of profit at the early stage 


*** RECOMMENDATION ***

The core tension: open content is the *mission*, but pure open-content +
donations (options 3/6 alone) rarely funds a software project before it has
Wikipedia-scale reach. So make open content the distribution/mission layer and
fund it from a paid layer that does NOT paywall learners.

**Model: open core — free learning + open courses, paid creation & management.**
- Learners: always free. Published courses are a public commons (mission,
  virality, grant eligibility).
- Creators: free to author by hand (the import format). Pay only for the
  expensive compute they trigger — AI course generation (~per exercise) and
  audio/TTS (~per 1k chars). Cost aligns with price; nothing that was free
  becomes paywalled. (Already scaffolded in CREATE_COURSE_WITH_AI.md.)
- Orgs (schools / teachers): free tier (one school, public courses) → paid for
  private cohorts, progress analytics, multiple editors, and the white-label
  app. This is the durable recurring revenue.

This reconciles "open content" with "fund the project" and reuses what exists:
the school = permission table, the editor dashboard, AI generation, TTS.

**Open-source split (open core):** open-source the learner app + import format
+ the course content (trust, contributions, the commons). Keep the managed
cloud — hosted AI generation, TTS, school analytics, white-label builds — as
the paid layer. That's how open projects fund themselves without taxing the
mission.

**Easiest start (start small → grow):**
- Phase 0 — Wedge: **private teachers** first, not multi-school SaaS. A teacher
  is a "school of one" (single decision-maker, immediate need to manage + follow
  students), and the school permission model already supports it. It de-risks
  the schools path with the lightest sale. A pilot public school in parallel is
  fine — non-profit early is the right instinct (harden product, accumulate open
  courses + testimonials + impact metrics).
- Phase 1 — Monetize creation, not consumption: ship metered AI generation +
  audio as the first paid feature. Lowest-friction first revenue.
- Phase 2 — School/SaaS subscription (options 1/2): once a school relies on the
  dashboard, charge per-seat or flat per-school; white-label is the premium tier.
- Phase 3 — Commons + funding (options 3/6): with reach + a public course
  library + impact data, pursue education / language-preservation grants and
  institutional sponsorship; optionally a creator marketplace (revenue share)
  and learner "support us" donations.

**Avoid early:** white-label multi-school SaaS as the *starting* point (heavy to
build/support before product-market fit); parents-and-kids (option 5: hard
distribution/retention); donation-only funding (won't pay bills at low scale).

**Next decisions:** (1) confirm the Phase-0 wedge (private teachers vs. one
pilot school); (2) confirm metered creation as the first paid feature; (3) keep
published courses public to seed the commons + grant story.



*** MVP Model ***
Goals:
  - Grow
  - Get initial feedback
Features
- learning is free 
- schools have free access and invitation - mechanism 
- opening a school require email request. 
- school can create content for close groups - its students
- private teacher are school of a single author 
- content generation - AI - instructions on how to create
- generation online with Polyglot - not in this phase - we do not implement the payment mechanism
- maybe generate only with polyglot is enabled but very very limited - only for people we know 



### My Comments on the plan 

- if we charge for content creation - we should consider invitations - as private teacher would like to earn money for their efforts. Than as a result we will have to collect money for them. 
Alternatively they can have their own way to get money from their students. We only allow them to close the content for their student only 
They can pay by active invitation  
- Schools could be our growth factor - even if we do not charge them money we should allow them to create private content - to a certain extent
- we need users, free content could be a start. but how do we encourage people to create content? 
Co-Editing could be interesting, this would allow users to improve content, but it could be complicated to manage. 


Summary 

- invitation - for closed content - no need for schools for a single user
- schools - add features as we go
  - follow up on students progress 
  - shared editing 