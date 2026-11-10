# Server Editor

## Gemini API key

The editor defaults to the `gemini` provider with the `gemini-2.5-flash` model.
Set `GOOGLE_API_KEY` in the environment before starting the server or worker.
PydanticAI also accepts `GEMINI_API_KEY` as an alias.
For Docker Compose, add this line to the repository-root `.env` file, which is
loaded by both editor services:

```env
GOOGLE_API_KEY=your-gemini-api-key
```

For a local run, export the variable before launching the server:

```sh
export GOOGLE_API_KEY="your-gemini-api-key"
```

The key is read by PydanticAI when it creates the Gemini model.

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