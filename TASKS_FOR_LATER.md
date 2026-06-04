*** Word translation + audio API integration (annotations) ***

Goal: replace the demo's hardcoded _AnnWord translations + the 🔊 snackbar
stub with REAL per-word translation + audio, so annotations can be generated
for any word/language. (We will pick options below and implement later.)

Reference (tested live, working):
  - Lingva (Google Translate proxy, path-style — matches the old URL pattern):
      translation: GET https://lingva.ml/api/v1/{from}/{to}/{word}  -> {"translation": "..."}
      audio (TTS): GET https://lingva.ml/api/v1/audio/{lang}/{word} -> {"audio":[mp3 byte ints]}
    Gotchas: audio is a JSON int array (decode to bytes for audioplayers);
    gives translation only (NO reading/romaji); public instances flaky/self-host.

   Decision points (write options now, pick later):

   - [ ] A. Translation provider
     - [ ] A1. Lingva (lingva.ml) — free, path-style {from}/{to}/{word}, matches
           the URL you remembered; unofficial Google proxy, self-hostable.
     - [ ] A2. Wiktionary / Wiktextract (kaikki.org) — free bulk JSON; gives
           translations + reading/IPA + audio links + POS (richest for
           annotations) but heavier to host (dump per language).
     - [ ] A3. Google Cloud Translate — official, paid, reliable; needs API key.
     - [ ] A4. DeepL — official, paid, high quality; fewer languages than Google.

   - [ ] B. Audio (word pronunciation) provider
     - [ ] B1. Lingva TTS audio endpoint (synthesized, same service as A1).
     - [ ] B2. Google Cloud Text-to-Speech — official, paid, many voices.
     - [ ] B3. Forvo — real native-speaker recordings, paid API (best quality).
     - [ ] B4. Wiktionary/Commons audio files (free, real speakers, coverage gaps).

   - [ ] C. Reading / romaji / furigana source (needed for JA readings; Lingva
         does NOT provide this)
     - [ ] C1. Wiktextract/kaikki (has readings) — pairs well if A2 chosen.
     - [ ] C2. A kana/romaji converter lib server-side (e.g. kuroshiro-style).
     - [ ] C3. Skip readings for now — translation + audio only.

   - [ ] D. Where the call happens
     - [ ] D1. Server proxy endpoint (e.g. GET /api/v1/translate/{from}/{to}/{word}
           + /api/v1/translate/audio/{lang}/{word}) — avoids CORS, decodes the
           audio array, caches results, swaps providers/instances in one place.
           (Recommended.)
     - [ ] D2. Client calls the provider directly — simpler, but CORS issues on
           web + provider URL/keys leak to the client.

   - [ ] E. Caching / persistence (translations + audio are stable per word)
     - [ ] E1. DB table (e.g. content.word_annotation(lang, to_lang, word,
           translation, reading, audio bytes/url)) populated on first lookup —
           cheap, offline-friendly, removes runtime dep on flaky instances.
     - [ ] E2. In-memory/process cache only — simplest, lost on restart.
     - [ ] E3. No cache — call provider every time (dev only).

   - [ ] F. Audio storage (if caching audio)
     - [ ] F1. Store bytes in DB / object storage and serve from our audio host.
     - [ ] F2. Store just the provider URL and proxy on demand.




==========================================================================
*** MODEL PLAN — annotated text + ruby text (data design) ***
==========================================================================

Goal: one structure that the UI can render directly (no server-side
formatting), that carries (a) ruby/transliteration shown ABOVE each word
and (b) per-word annotation (translation + audio) shown in a tooltip, and
that handles the Japanese case of 3 script versions sharing ONE set of
word annotations.

------------------------------------------------------------------
1. CORE IDEA — a sentence is a flat LIST OF TOKENS
------------------------------------------------------------------
The UI already wants exactly this (see _RubyAnnWord in annotated_page.dart):
the widget just iterates tokens and renders, for each one:
  - the base glyphs,
  - an optional reading line above it (ruby),
  - a highlight + tooltip when the token carries a translation.

So the runtime model is just `List<AnnToken>`. Nothing nested, nothing the
UI has to compute.

A token (one word / run):
    text   (String, required)   base glyphs to show on the line
    ruby   (String?)            reading shown above (furigana / translit)
    tr     (String?)            translation — its PRESENCE means the token
                                is highlighted + tappable
    audio  (String?)            per-word audio url (optional; tooltip play)

JSON (compact keys to keep the blob small):
    { "t": "日本語", "r": "にほんご", "tr": "Japanese language",
      "a": "ja/w/nihongo.mp3" }
    { "t": "を" }                       // plain word, no ruby, not tappable

A whole annotated sentence = a JSON array of these token objects.

------------------------------------------------------------------
2. THE JAPANESE 3-VERSION PROBLEM — annotations shared (line 579)
------------------------------------------------------------------
Japanese needs 3 renderings of the SAME sentence:
    v1  Kanji + furigana   base=私    ruby=わたし
    v2  Hiragana           base=わたし ruby=none
    v3  Romaji             base=watashi ruby=none
…but the word annotation (tr/audio) is identical across all three.

Decision points (resolving per workflow rule):

  - How to store the 3 versions + shared annotation:
    - [selected] ONE token list; each token carries a `forms` map of the
      per-script surface + a single shared `ruby`/`tr`/`audio`. The active
      script is chosen by the existing textAlternativeSlot / RubyMode
      setting. Zero duplication of translations; the UI picks
      forms[activeScript] for the base and shows `ruby` only when the
      active script is the kanji one.

          { "forms": {"kanji":"私","hira":"わたし","romaji":"watashi"},
            "ruby": "わたし", "tr": "I; me", "a": "ja/w/watashi.mp3" }
          { "forms": {"kanji":"は","hira":"は","romaji":"wa"} }

      Languages with a single script (Arabic plain/diacritic/translit, etc.)
      just use one `forms` key — or the flat `text` form from §1, which is
      the `forms`-of-one degenerate case. So §1 and §2 are the SAME model:
      `text` is sugar for `forms` with a single entry.

    - [ ] THREE independent flat token lists (one per version), each fully
      self-contained per §1. Simplest possible UI (just pick a list) but
      duplicates every translation 3× and risks drift on edit. Rejected:
      violates "annotation shared in all versions".

  - Dart shape:
    - [selected] 
          class AnnToken {
            final Map<String,String> forms;   // {'kanji':..,'hira':..,'romaji':..}
            final String? ruby;                // reading over the kanji form
            final String? translation;
            final String? audio;
            bool get annotated => translation != null;
            String surface(String script) => forms[script] ?? forms.values.first;
          }
          // sentence = List<AnnToken>; carries an ordered list of the script
          //            keys it provides (e.g. ['kanji','hira','romaji']).
      The existing RubySegment / _RubyAnnWord widgets stay as the pure-UI
      render layer; AnnToken is the data layer that feeds them.

------------------------------------------------------------------
3. STORAGE — how it rides on the exercise (no server formatting, line 580)
------------------------------------------------------------------
Decision points:
  - [selected] New `annotated jsonb` column on course_simple.exercise holding
    the token list + the script-key order, e.g.
        { "scripts": ["kanji","hira","romaji"],
          "tokens": [ {...}, {...} ] }
    Server stores & returns it verbatim — never parses or reformats it.
    Keep `sentence` + `sentence_alt1/2/3` as-is for back-compat and for
    exercises that have no annotation data; they are derivable by joining a
    script's surfaces but we don't force it.
  - [ ] Cram it into the existing `options` jsonb — rejected, overloads a
    field with unrelated meaning.

  Client: `Exercise.annotated` → `List<AnnToken>?` (null when absent → fall
  back to today's flat-string rendering). quiz_page picks base script from
  textAlternativeSlot/RubyMode exactly like it does today.

------------------------------------------------------------------
4. AUTHORING TEXT FORMAT (lines 561, 581)
------------------------------------------------------------------
One token per line, columns = the data, blank = none. A header line names
the columns so single-script languages stay short. `#` comments, blank line
separates sentences.

    # ja_en — lesson 1
    @scripts kanji hira romaji
    @translation Every day I study Japanese and go to the library.
    # kanji | hira | romaji | ruby | tr
    私    | わたし   | watashi  | わたし   | I; me
    は    | は       | wa       |         |
    毎日  | まいにち | mainichi | まいにち | every day
    日本語| にほんご | nihongo  | にほんご | the Japanese language
    を    | を       | o        |         |
    勉強  | べんきょう| benkyō  | べんきょう| study
    …

Single-script language (Italian) collapses to two meaningful columns:

    @scripts base
    @translation I was looking for my dog
    # base | tr
    Stavo cercando | I was looking for
    il mio cane    | my dog

Rules: column order follows `@scripts` then `ruby` then `tr` (then optional
`audio`). The importer (folder_to_db) parses rows → builds the §2 token list
→ writes the `annotated` jsonb. No transformation happens at request time.

------------------------------------------------------------------
5. OPEN / TO VERIFY (carried from the discussion above)
------------------------------------------------------------------
- [ ] Can ruby (kanji→furigana) + hira/romaji be auto-generated reliably?
  (e.g. fugashi/MeCab + jaconv). If yes the author only writes kanji + tr
  and the importer fills the rest; if not, columns are hand-authored.
- [ ] Audio source: per-word clips vs. reuse lingva.ml TTS at runtime.
- [ ] Whether to keep sentence_alt1/2/3 long-term or derive them from
  `annotated.tokens` and drop the columns.







