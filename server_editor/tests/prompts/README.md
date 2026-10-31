# Prompt evaluations

Add prompt runs to `prompt_cases.yaml`. Each run contains:

- `target`: the import path and function, for example `prompts.text_quiz:get_text_quiz`
- `comment`: the code or prompt change being evaluated
- `args`: the complete keyword arguments for that function

Run the basic execution tests from `server` with:

```bash
python -m pytest tests/prompts/test_prompt_cases.py --run-prompts -q
```

These call every function and save only `test`, `comments`, and `status`.

Run the quality tests with:

```bash
python -m pytest tests/prompts/test_prompt_cases.py --run-prompt-quality -q
```

These save the structured model output under `results` for review.

Results are written after every run to a timestamped file such as
`tests/prompts/results/basic-2026-09-18-14-30-00.yaml`. Set
`PROMPT_OUTPUT_FILE` to use another output file. YAML comments beginning with
`#` are copied to the output header.