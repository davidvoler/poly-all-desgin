"""Mock "AI" content generation for the Create-with-AI copilot — ported
from plan/design_experiments/create_with_ai_poc/assets/store.js so the
real backend and the HTML/JS prototype agree on the same curated
vocabulary. There is no real LLM call here (see TASKS.md "Planning the
api" — that's a deliberate follow-up once this architecture is in place);
unknown languages fall back to obviously-labelled placeholder content."""
import hashlib
import random

VOCAB: dict[str, list[dict]] = {
    "japanese": [
        {"word": "こんにちは", "gloss": "hello", "sentence": "こんにちは、元気ですか?", "sentence_gloss": "Hello, how are you?"},
        {"word": "ありがとう", "gloss": "thank you", "sentence": "どうもありがとうございます。", "sentence_gloss": "Thank you very much."},
        {"word": "水", "gloss": "water", "sentence": "水を一杯ください。", "sentence_gloss": "One glass of water, please."},
        {"word": "猫", "gloss": "cat", "sentence": "猫が好きです。", "sentence_gloss": "I like cats."},
        {"word": "犬", "gloss": "dog", "sentence": "犬と散歩します。", "sentence_gloss": "I walk with the dog."},
        {"word": "家", "gloss": "house", "sentence": "これは私の家です。", "sentence_gloss": "This is my house."},
        {"word": "友達", "gloss": "friend", "sentence": "彼は私の友達です。", "sentence_gloss": "He is my friend."},
        {"word": "食べる", "gloss": "to eat", "sentence": "朝ごはんを食べます。", "sentence_gloss": "I eat breakfast."},
        {"word": "飲む", "gloss": "to drink", "sentence": "コーヒーを飲みます。", "sentence_gloss": "I drink coffee."},
        {"word": "おはよう", "gloss": "good morning", "sentence": "おはようございます。", "sentence_gloss": "Good morning."},
        {"word": "さようなら", "gloss": "goodbye", "sentence": "さようなら、また明日。", "sentence_gloss": "Goodbye, see you tomorrow."},
        {"word": "はい", "gloss": "yes", "sentence": "はい、そうです。", "sentence_gloss": "Yes, that is right."},
        {"word": "いいえ", "gloss": "no", "sentence": "いいえ、違います。", "sentence_gloss": "No, that is not right."},
        {"word": "学校", "gloss": "school", "sentence": "毎日学校に行きます。", "sentence_gloss": "I go to school every day."},
    ],
    "hebrew": [
        {"word": "שלום", "gloss": "hello / peace", "sentence": "שלום, מה שלומך?", "sentence_gloss": "Hello, how are you?"},
        {"word": "תודה", "gloss": "thank you", "sentence": "תודה רבה לך.", "sentence_gloss": "Thank you very much."},
        {"word": "מים", "gloss": "water", "sentence": "אני רוצה כוס מים.", "sentence_gloss": "I want a glass of water."},
        {"word": "חתול", "gloss": "cat", "sentence": "אני אוהב חתולים.", "sentence_gloss": "I like cats."},
        {"word": "כלב", "gloss": "dog", "sentence": "הכלב שלי גדול.", "sentence_gloss": "My dog is big."},
        {"word": "בית", "gloss": "house", "sentence": "זה הבית שלי.", "sentence_gloss": "This is my house."},
        {"word": "חבר", "gloss": "friend", "sentence": "הוא חבר טוב.", "sentence_gloss": "He is a good friend."},
        {"word": "לאכול", "gloss": "to eat", "sentence": "אני אוכל ארוחת בוקר.", "sentence_gloss": "I eat breakfast."},
        {"word": "לשתות", "gloss": "to drink", "sentence": "אני שותה קפה.", "sentence_gloss": "I drink coffee."},
        {"word": "בוקר טוב", "gloss": "good morning", "sentence": "בוקר טוב לכולם.", "sentence_gloss": "Good morning everyone."},
        {"word": "להתראות", "gloss": "goodbye", "sentence": "להתראות, נתראה מחר.", "sentence_gloss": "Goodbye, see you tomorrow."},
        {"word": "כן", "gloss": "yes", "sentence": "כן, זה נכון.", "sentence_gloss": "Yes, that is correct."},
        {"word": "לא", "gloss": "no", "sentence": "לא, זה לא נכון.", "sentence_gloss": "No, that is not correct."},
        {"word": "בית ספר", "gloss": "school", "sentence": "אני הולך לבית הספר כל יום.", "sentence_gloss": "I go to school every day."},
    ],
    "spanish": [
        {"word": "hola", "gloss": "hello", "sentence": "Hola, ¿cómo estás?", "sentence_gloss": "Hello, how are you?"},
        {"word": "gracias", "gloss": "thank you", "sentence": "Muchas gracias.", "sentence_gloss": "Thank you very much."},
        {"word": "agua", "gloss": "water", "sentence": "Quiero un vaso de agua.", "sentence_gloss": "I want a glass of water."},
        {"word": "gato", "gloss": "cat", "sentence": "Me gustan los gatos.", "sentence_gloss": "I like cats."},
        {"word": "perro", "gloss": "dog", "sentence": "Mi perro es grande.", "sentence_gloss": "My dog is big."},
        {"word": "casa", "gloss": "house", "sentence": "Esta es mi casa.", "sentence_gloss": "This is my house."},
        {"word": "amigo", "gloss": "friend", "sentence": "Él es mi amigo.", "sentence_gloss": "He is my friend."},
        {"word": "comer", "gloss": "to eat", "sentence": "Como el desayuno.", "sentence_gloss": "I eat breakfast."},
        {"word": "beber", "gloss": "to drink", "sentence": "Bebo café.", "sentence_gloss": "I drink coffee."},
        {"word": "buenos días", "gloss": "good morning", "sentence": "Buenos días a todos.", "sentence_gloss": "Good morning everyone."},
        {"word": "adiós", "gloss": "goodbye", "sentence": "Adiós, hasta mañana.", "sentence_gloss": "Goodbye, see you tomorrow."},
        {"word": "sí", "gloss": "yes", "sentence": "Sí, es correcto.", "sentence_gloss": "Yes, that is correct."},
        {"word": "no", "gloss": "no", "sentence": "No es correcto.", "sentence_gloss": "That is not correct."},
        {"word": "escuela", "gloss": "school", "sentence": "Voy a la escuela todos los días.", "sentence_gloss": "I go to school every day."},
    ],
}


def _vocab_for(lang: str | None) -> list[dict]:
    bank = VOCAB.get((lang or "").strip().lower())
    if bank:
        return bank
    return [
        {
            "word": f"{lang or 'Word'} #{i + 1}",
            "gloss": f"demo gloss {i + 1}",
            "sentence": f"(demo) Example sentence using word #{i + 1}.",
            "sentence_gloss": "(demo) Example sentence, translated.",
        }
        for i in range(14)
    ]


def generate_words(lang: str | None, existing_words: list[str], count: int = 12) -> list[dict]:
    """Up to `count` new {word, gloss, sentence, sentence_gloss} dicts,
    skipping words already in `existing_words`."""
    bank = _vocab_for(lang)
    already = set(existing_words)
    picked = [v for v in bank if v["word"] not in already][:count]
    return picked


def generate_exercise_options(correct: str, distractor_pool: list[str], seed: int) -> list[str]:
    """A single_choice option set: `correct` plus up to 2 distractors
    pulled from `distractor_pool`, shuffled."""
    distractors: list[str] = []
    pool = [w for w in distractor_pool if w != correct]
    for j in range(len(pool)):
        pick = pool[(seed + j) % len(pool)]
        if pick not in distractors:
            distractors.append(pick)
        if len(distractors) >= 2:
            break
    options = [correct] + distractors
    random.shuffle(options)
    return options


def sentence_for_word(word_row: dict) -> tuple[str, str]:
    """(text, gloss) draft sentence for a course_word row — its own
    example if the curated bank had one, otherwise an obvious placeholder."""
    text = word_row.get("example_sentence") or f'(demo) Sentence for "{word_row["word"]}".'
    gloss = word_row.get("example_gloss") or "(demo) translated sentence."
    return text, gloss


def exercise_prompt_for_gloss(gloss: str | None) -> str:
    if gloss:
        return f'Which word means "{gloss.rstrip(".")}"'
    return "Choose the correct word."


def sentence_id_for(lang: str, text: str) -> int:
    """Deterministic content-addressable id for a sentence — a hash of
    "lang:text", masked to 53 bits so it stays a JS-safe integer and
    round-trips through Flutter web's JSON without precision loss."""
    digest = hashlib.sha256(f"{lang}:{text}".encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big") & 0x1FFFFFFFFFFFFF


def mock_usage(unit_count: int) -> tuple[int, float]:
    """Fake token/cost usage for a generation call, scaled by how much
    content came back — mirrors PromptResponse.actual_tokens/actual_cost
    (and the JS POC's identical mockUsage in assets/store.js) until a real
    LLM call lands here."""
    tokens = round(80 + unit_count * 35 + random.random() * 40)
    cost = tokens * 0.0000025
    return tokens, cost
