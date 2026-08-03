"""
Yes — two levels: rule-of-thumb estimation for planning, and real usage tracking once you're live.

**Quick estimation rule:** ~4 characters ≈ 1 token (English). For pre-launch budgeting, Anthropic also has a `count_tokens` endpoint you can call with your actual prompt to get an exact number before sending it — better than guessing.

**Current pricing (per million tokens, as of Aug 2026):**

- Claude Sonnet 5: $2 input / $10 output (through Aug 31, 2026; rises to $3/$15 after)
- Claude Haiku 4.5: $1 input / $5 output
- Claude Opus 5: $5 input / $25 output
- Gemini 3.6 Flash: ~$1.50 input / $7.50 output
- Gemini 3.1 Pro: $2 input / $12 output

Cache hits cost 10% of input price, and Batch API cuts both input/output by 50% — worth using if generation isn't real-time (e.g., pre-generating a content bank overnight).

**Worked example for your use case:** say each generation call is a system prompt + few-shot examples (~800 input tokens) producing a set of exercises (~500 output tokens), using Sonnet 5:

- Input: 800 × $2/1M = $0.0016
- Output: 500 × $10/1M = $0.005
- **~$0.0066 per generation**

At 10,000 generations/day that's ~$66/day (~$2,000/month). Switching to Haiku 4.5 for simpler exercise types cuts that to roughly $33/month for the same volume — and if your system prompt is large and reused across calls, prompt caching drops the input cost further.

**Practical recommendation:** don't hand-estimate for production — log `usage.input_tokens` / `usage.output_tokens` from every API response (both Claude and Gemini return this), and build a running dashboard. That gives you real cost-per-generation instead of a guess, and lets you catch prompt bloat early (e.g., if few-shot examples grow unnoticed).

Sources:
- [Pricing - Claude Platform Docs](https://platform.claude.com/docs/en/about-claude/pricing)
- [Gemini pricing in 2026](https://www.cloudzero.com/blog/gemini-pricing/)
- [Gemini API Pricing (August 2026)](https://benchlm.ai/google/api-pricing)
"""


def estimate_cost(prompt:str, lang:str = 'en') -> float:
    pass 

def estimate_tokens(prompt:str, lang:str='en') -> float:
    # Quick estimation rule: ~4 characters ≈ 1 token (English)
    return len(prompt) / 4


