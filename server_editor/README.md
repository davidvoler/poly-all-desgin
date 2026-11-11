# Server Editor

## Login

The editor uses the same accounts as the app and dashboard
(`user_data.users`) and signs in with OAuth: Continue with Google through
Auth0. Email + password exists for local development only, where Auth0 is not
set up: the server refuses it unless `EDITOR_PASSWORD_LOGIN=true`, and
production builds hide the form. Only active members of the school with the
`editor` role in `school.school_users.roles` can sign in; users are never
created here.

- **Which school:** the editor site's hostname, matched against
  `school.schools.school_editor_url` (like `school_url` for the app and
  `school_dashboard_url` for the dashboard). Courses and AI keys store the
  school as its `school_id` in text (`'1'`). DDL: `DDL/editor_auth.sql`.
- **Session:** an HttpOnly `editor_session` cookie holding a JWT signed with
  `EDITOR_SESSION_SECRET` (`utils/session.py`). Unlike the app/dashboard
  `user_id` cookie it cannot be edited or forged, and it expires.
- **Every request** (`utils/permission.get_school_user`) checks the cookie,
  that it was issued for this site's school, and that the user is still an
  active editor there, so removing the role takes effect at once.
- **Per-school data:** `require_access` returns 404 for any course, module,
  lesson or exercise of another school.
- Endpoints: `POST /api/v1/auth/login_with_password`, `POST /api/v1/auth/login_auth0`
  (`{"id_token"}`), `GET /api/v1/auth/me`, `POST /api/v1/auth/logout`.

Settings (repository-root `.env`, loaded by the editor server):

```env
EDITOR_SESSION_SECRET=<at least 32 random characters>  # python -c "import secrets;print(secrets.token_urlsafe(48))"
EDITOR_SESSION_DAYS=7
COOKIE_SECURE=true                                      # behind HTTPS
# The editor sites allowed to call the API with the cookie (default: localhost)
EDITOR_ALLOWED_ORIGINS=^https://([a-z0-9-]+\.)*editor\.polyglots\.social$
AUTH0_DOMAIN=polyglots.us.auth0.com                     # same tenant and client as the dashboard
AUTH0_CLIENT_ID=<the SPA client id>
```

To let someone into the editor:

```sql
update school.school_users set roles = array_append(roles, 'editor')
where user_id = <id> and school_id = <school> and not ('editor' = any(roles));
```

## AI API keys

Each school, and each user, brings its own API keys for Gemini, Claude and
OpenAI. They are added in the editor app (the AI keys page in the sidebar) and
stored encrypted in `secrets.ai_api_key` (DDL: `DDL/ai_keys.sql`).

- **School key**: `user_id` is empty; shared by the school's users.
- **User key**: has both `school` and `user_id`; used before the school's.
- **Server key**: `GOOGLE_API_KEY` / `GEMINI_API_KEY`, `ANTHROPIC_API_KEY`,
  `OPENAI_API_KEY` in `.env`, used when neither has one, only while
  `AI_KEYS_ENV_FALLBACK=true`. Off by default; turn it on for local development.

The default provider is `gemini` with the `gemini-3.5-flash` model.

### Setup

1. Create the table: `psql ... -f server_editor/DDL/ai_keys.sql`.
2. No master key is needed for now: without one, keys are stored as plain
   text (`key_version` 0). To encrypt them later, add a master key to the
   repository-root `.env`, loaded by both editor services (the server and the
   `broker-editor` worker), restart them, and run `scripts/rotate_ai_keys.py`
   to encrypt the keys already stored:

   ```env
   # python -c "import os;print(os.urandom(32).hex())"
   # AI_KEYS_MASTER_KEY_V1=<64 hex characters>
   # Optional, local development only: use the server's own keys as a fallback.
   # AI_KEYS_ENV_FALLBACK=true
   ```

   Once set, keep the master key out of git and backed up: without it the
   stored keys cannot be decrypted. Use a different one in each environment.

### How it works

- The API never returns a key, only its last 4 characters
  (`GET/PUT/DELETE /api/v1/ai/keys`).
- With a master key, keys are encrypted with AES-GCM in `utils/secret_box.py`.
  Each ciphertext is bound to its school, user and provider, so a copied row
  does not decrypt. Without one, they are stored as plain text.
- Keys are decrypted only in the task worker, for the length of one prompt
  task (`tasks/prompt_tasks.py` → `prompts.providers.use_api_keys`).
- `GET /api/v1/prompt/ai_models` marks a provider available when the user,
  their school or the server has a key for it.
- Who may change school keys: `utils.permission.can_manage_school_keys`
  (every editor of the school).

### Rotating the master key

Add `AI_KEYS_MASTER_KEY_V2` next to V1, restart the editor server and worker,
then run `cd server_editor/src && python -m scripts.rotate_ai_keys`. Remove V1
once no rows use it.

We want to create a separate server for editor and student
There is some common functionality however most of the code is unique and separating it would ease the development

### Guidelines 

- Smaller files 
- Try to use pure function where possible 
    - Separate saving to DB logic from the actual generation

- Folders 
    - routers 
    - models 
    - utils 
    - tasks
        - long running tasks with task manager such as taskiq 
    - generate? need a better name - Do we need it?- We can simply use utils 
        - complex code that requires complex logic 
- Get data in chunks - do now load a full course but 
- Testing 
    - We need a way to implement tests 



### Process


#### Comparison to current version
- load module by module or even lesson by lesson. no need to load an entire course 
- 

### Scenarios 

1. Create course
 - basic configuration 
 - generate course words - we can add words later in module
 - Some options 
2. Generate Module 
 - words for module - can start from course - or add new 
 - add words already used in course - if we generate a sentence for the word "cat" The cat with the hat. we can now use the words "hat"
 - options 
    - number of sentences per word 
    - number of words per lesson 
3. Generate lesson
 - Show process for each word and sentences created 
 - Show when completed

4. Course Words section 
 - words generated 
 - words used in sentences  
 
### Question:
- Do we need a wizard UI or a simple chat will do?




### Models and costs

#### Google model options

- `gemini-3.1-flash-lite`
- `gemini-2.5-flash-lite`
- `gemini-2.5-flash`
- `gemini-3.8-flash`
- `gemini-2.5-pro`
- `gemini-3.1-pro`

The cost difference between the model tiers is substantial: **Flash-Lite is 15× to 30× cheaper than Pro**, while standard **Flash sits in the sweet spot at roughly 4× to 6× cheaper than Pro**.

Google prices the API per **1 million tokens (1M tokens)**, split into **Input** (your prompt, system instructions, and examples) and **Output** (the generated quiz items and translations).

---

### Token Pricing Comparison

| Tier | Representative Model | Input Cost (per 1M tokens) | Output Cost (per 1M tokens) | Relative Cost Multiplier |
| --- | --- | --- | --- | --- |
| **Flash-Lite** *(Budget / High-Volume)* | `gemini-3.1-flash-lite` / `gemini-2.5-flash-lite` | **$0.10 – $0.25** | **$0.40 – $1.50** | **1× (Baseline)** |
| **Standard Flash** *(Workhorse)* | `gemini-2.5-flash` / `gemini-3.8-flash` | **$0.30 – $0.75** | **$2.50 – $3.75** | **~3× to 6×** |
| **Pro Tier** *(Flagship Reasoning)* | `gemini-2.5-pro` / `gemini-3.1-pro` | **$1.25 – $2.00** | **$10.00 – $12.00** | **~15× to 25×** |

*(Note: Pro models double their input rate if a single request's prompt exceeds 200k tokens, whereas Flash tiers remain flat).*

---

### What Does This Look Like in Practice?

Assume a standard interactive quiz workflow:

* **Input prompt:** ~400 tokens (system instructions, language rules, few-shot schema example)
* **Output generated:** ~300 tokens (questions, 4 choices, translations, explanation)
* **Volume:** **10,000 quiz requests** (Total: 4 million input tokens + 3 million output tokens)

| Model Tier | Cost for 10,000 Generated Quizzes |
| ---                 | ---                 |
| **Flash-Lite**      | **~$2.00 – $4.50** |
| **Standard Flash**  | **~$8.50 – $14.00** |
| **Pro Tier**        | **~$35.00 – $44.00** |
---

### Key Takeaways for Your App

1. **Start with Standard Flash:** At roughly $0.001 per full quiz interaction, standard Flash gives near-instant response times and handles non-Latin/Semitic scripts with high linguistic accuracy without blowing through a budget.
2. **Use Flash-Lite for Single-Word Lookups:** If your app adds micro-interactions (e.g., clicking a single Arabic or Hebrew word to get a 1-word gloss or audio pronunciation helper), route those to Flash-Lite to keep costs near zero.
3. **Reserve Pro for Complex Grammar Audits:** Only route traffic to Pro if a user submits an essay for grading or requests deep linguistic etymology across classical texts.