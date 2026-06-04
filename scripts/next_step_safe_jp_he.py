import json

import yaml
from utils.db import get_query_results
import random
import asyncio
words_for_recognize = set()
words_for_recognize_split = set()
lesson_words = set()
import sys
import unicodedata
from multiprocessing import Pool
import os


dictionary = {}


def is_hiragana(char):
    """Check if a character is Hiragana"""
    return '\u3040' <= char <= '\u309F'

def is_katakana(char):
    """Check if a character is Katakana"""
    return ('\u30A0' <= char <= '\u30FF') or ('\u31F0' <= char <= '\u31FF')

def is_kanji(char):
    """Check if a character is Kanji"""
    return ('\u4E00' <= char <= '\u9FAF') or \
           ('\u3400' <= char <= '\u4DBF') or \
           ('\uF900' <= char <= '\uFAFF')


def has_kanji_or_hiragana(word):
    """Check if a word contains at least one Kanji or Hiragana character"""
    for char in word:
        if is_kanji(char) or is_hiragana(char):
            return True
    return False


async def load_dictionary():
    global dictionary
    sql = f"""SELECT * FROM content_raw.secondary_words_translation"""
    results = await get_query_results(sql, ())
    for r in results:
        word = r.get('word')
        translation = r.get('to_to_word')
        if has_kanji_or_hiragana(word):
            dictionary[word] = translation
            print (f"added word {word} to dictionary with translation {translation}")
        else:
            print(f"skipping word {word} as it does not contain kanji or hiragana")
def add_words_for_recognize(word):
    if len(word) > 3:
        words_for_recognize.add(word)


def add_lesson_words(word):
    if len(word) > 3:
        lesson_words.add(word)


def add_lesson_words_split(text):
    words = text.split()
    for w in words:
        if len(w) > 3:

            words_for_recognize_split.add(w)

async def get_sentences_voice(lang, sentence_id):
    # prefer azure voices 
    sql = f"""SELECT recording, audio_engine 
    FROM content_raw.audio 
    WHERE lang = %s and id = {sentence_id}
    order by audio_engine
    """
    res = await get_query_results(sql, (lang,))
    if len(res) > 0:
        for r in res:
            return r.get('recording')
    return "" 


async def get_alt(elements):
    hira = ''
    kana = ''
    romaji = ''
    for e in elements:
        hira += e.get('hira', '') or e.get('text', '')
        kana += e.get('kana', '') or e.get('text', '')
        romaji += e.get('roma', '')
    return hira, romaji, kana


def get_ruby(elements):
    hira = []
    kana = []
    romanji = []
    for e in elements:
        if e.get('hira'):
            hira.append({'text': e.get('text'), 'ruby': e.get('hira', '')})
        else:
            hira.append({'text': e.get('text', '')})
        if e.get('kana'):
            kana.append({'text': e.get('text'), 'ruby': e.get('kana', '')})
        else:
            kana.append({'text': e.get('text', '')})
        if e.get('roma'):
            romanji.append({'text': e.get('text'), 'ruby': e.get('roma', '')})
        else:
            romanji.append({'text': e.get('text', '')})
    return {"hiragana": hira, "katakana": kana, "romanji": romanji}

async def gen_exercise(lang, to_lang, id, to_id, weight):
    global dictionary
    lang_sql = f"""
    SELECT text, elements, word1, word2, word3, words, options
    FROM content_raw.sentence_elements
    WHERE lang = %s and id = %s
    """
    res_lang = await get_query_results(lang_sql, (lang, id))
    to_lang_sql = f"""
    SELECT text as to_text, options as to_options
    FROM content_raw.sentences
    WHERE lang = %s and id = %s
    """
    res_to_lang = await get_query_results(to_lang_sql, (to_lang, to_id))

    if len(res_lang) == 0 or len(res_to_lang) == 0:
        return None
    r = {**res_lang[0], **res_to_lang[0]}
    audio = await get_sentences_voice(lang, id)
    text = r.get('text')
    hira, romaji, kana = await get_alt(r.get('elements', []))
    word1 = r.get('word1')
    word2 = r.get('word2')
    word3 = r.get('word3')
    words = r.get('words', [])
    options = r.get('options', [])
    to_text = r.get('to_text')
    to_options = r.get('to_options', [])
    annotations  = []
    if word1 and dictionary.get(word1):
        annotations.append({"word": word1, "translation": dictionary.get(word1)})
    if word2  and dictionary.get(word2):
        annotations.append({"word": word2, "translation": dictionary.get(word2)})
    if word3  and dictionary.get(word3):
        annotations.append({"word": word3, "translation": dictionary.get(word3)})
    
    words_for_recognize.add(word1)
    words_for_recognize.add(word2)
    words_for_recognize.add(word3)
    random.shuffle(options)
    number_of_options = random.randint(2,3)
    options = options[:number_of_options]
    random.shuffle(to_options)
    to_options = to_options[:number_of_options]
    op = [{"text":o} for o in to_options]
    op.append({"text": to_text, "correct": True})
    ruby_text = get_ruby(r.get('elements', []))

    random.shuffle(op)
    rnd= random.randint(0,10)
    if rnd < 2:
        if audio:
            if len(words_for_recognize)> 150 and weight > 7 and len(words) >= 3:
                    w_correct = [word1, word2, word3]
                    w_wrong = random.sample(list(words_for_recognize), k=7)
                    all_words = list(set(w_correct + w_wrong))
                    opt = [{"text": w, "correct": w in w_correct} for w in all_words]
                    random.shuffle(opt)
                    opt = opt[:8]
                    ex = {
                        'type': 'recognize',
                        'text': text,
                        'text_alt1': hira,
                        'text_alt2': romaji,
                        'text_alt3': kana,
                        'to_text': to_text,
                        'options': opt,
                        'voice': audio,
                        'sentence_id': id,
                        'sentence_to_id': to_id,
                        'word1': word1, 
                        'word2': word2, 
                        'word3': word3,
                        "sentence_id": id,
                        "sentence_to_id": to_id,
                        "weight": weight,
                        "ruby_text": ruby_text,
                        "annotations": annotations
                    }
                    return ex
    if rnd > 8 and len(words_for_recognize_split) > 150 and weight > 7:
        op = [{"text":o} for o in options]
        op.append({"text": text, "correct": True})
        ex = {
            'type': 'read',    
            'text': to_text,
            'text_alt1': hira,
            'text_alt2': romaji,
            'text_alt3': kana,
            'options': op,
            'voice': audio,
            'sentence_id': id,
            'sentence_to_id': to_id,
            'word1': word1, 
            'word2': word2, 
            'word3': word3,
            'sentence_id': id,
            'sentence_to_id': to_id,
            'weight': weight,
            'ruby_text': ruby_text,
            'annotations': annotations
        }
        return ex
    else:
        ex = {
        'type': 'simple',    
        'text': text,
        'text_alt1': hira,
        'text_alt2': romaji,
        'text_alt3': kana,
        'options': op,
        'voice': audio,
        'sentence_id': id,
        'sentence_to_id': to_id,
        'weight': weight,
        'word1': word1, 
        'word2': word2, 
        'word3': word3,
        'ruby_text': ruby_text,
        'annotations': annotations
    }
    return ex

async def gen_lesson(l:dict):
    sentences = l.get('sentences', [])
    words = l.get('words', [])
    for w in words:
        add_lesson_words(w)
    sentences_count = len(sentences)
    exercises = []
    i = 0
    for s in sentences:
        i += 1
        ex = await gen_exercise('ja', 'en', s.get('id'), s.get('to_id'), i)
        if ex:
            exercises.append(ex)
    return {
        'lesson': l.get('lesson'),
        'title': "learning " + ", ".join(l.get('words', [])),
        'words': words,
        'exercises': exercises,
        'words_so_far': list(lesson_words),
    }

async def gen_module(m:dict):
    lessons = m.get('lessons', [])
    gen_lessons = []
    module_words = []
    for l in lessons:
        gen_l = await gen_lesson(l)
        words = gen_l.get('words', [])
        # module_words.extend(words)
        gen_lessons.append(gen_l)
        # except Exception as e:
        #     print(f"error generating lesson {l.get('lesson')}: {e}")
        #     continue
    return {
        'module': m.get('module'),
        'lessons': gen_lessons,
        # 'words': module_words,
    }




async def gen_and_save_module(m:dict):
    print(f"generating module {m.get('module')}")
    module_no = int(m.get('module'))
    os.makedirs(f"../data/content/ja_he/v3/module_{module_no}", exist_ok=True)
    if len(os.listdir(f"../data/content/ja_he/v3/module_{module_no}")) > 1:
        print(f"module {m.get('module')} already exists, skipping")
        return
    gen_m =  await gen_module(m)
    with open(f"../data/content/ja_he/v3/module_{module_no}/module.yaml", 'w') as f:
        f.write(f"module: {module_no}\n")
        f.write(f"weight: {module_no}\n")
    i = 1
    for lesson in gen_m.get('lessons', []):
        # for key, value in lesson.items():
        #     print(f"{key}: {len(value)} {type(value)}")
        lesson_no = i
        weight = lesson.get('weight',lesson_no )
        title = lesson.get('title', '')
        with open(f"../data/content/ja_he/v3/module_{module_no}/lesson_{lesson_no}.txt", 'w') as f:
            title = lesson.get('lesson', '')
            f.write(f"title: {title}\n")
            f.write(f"weight: {weight}\n")
            for exercise in lesson.get('exercises', []):
                # print(f"{exercise}")
                f.write("---\n")
                f.write(f"type: {exercise.get('type', '')}\n")
                f.write(f"text: {exercise.get('text')}\n")
                if exercise.get('text_alt1'):
                    f.write(f"text_alt1: {exercise.get('text_alt1')}\n")
                if exercise.get('text_alt2'):
                    f.write(f"text_alt2: {exercise.get('text_alt2')}\n")
                if exercise.get('text_alt3'):
                    f.write(f"text_alt3: {exercise.get('text_alt3')}\n")
                options = exercise.get('options', [])
                if exercise.get('voice'):
                    f.write(f"voice: {exercise.get('voice')}\n")
                if exercise.get('word1'):
                    f.write(f"word1: {exercise.get('word1')}\n")
                if exercise.get('word2'):
                    f.write(f"word2: {exercise.get('word2')}\n")
                if exercise.get('word3'):
                    f.write(f"word3: {exercise.get('word3')}\n")
                if exercise.get('sentence_id'):
                    f.write(f"sentence_id: {exercise.get('sentence_id')}\n")
                if exercise.get('sentence_to_id'):
                    f.write(f"to_sentence_id: {exercise.get('sentence_to_id')}\n")
                f.write(f"weight: {exercise.get('weight', i)}\n")
                f.write(f"ruby_text: {json.dumps(exercise.get('ruby_text'))}\n")
                f.write(f"annotations: {json.dumps(exercise.get('annotations'))}\n")
                for o in options:
                    prefix = "[-]"
                    if o.get('correct'):
                        prefix = "[+]"
                    f.write(f"{prefix} {o.get('text')}\n")
        i += 1

def g_module(m:dict):
    asyncio.run(gen_and_save_module(m))

async def gen_course(lang, to_lang, load_path):
    await load_dictionary()
    module = yaml.safe_load(open(load_path, 'r'))
    modules = module.get('modules', [])
    for m in modules:
        await gen_and_save_module(m)
        # try:
        #     await gen_and_save_module(m)
        # except Exception as e:            
        #     print(f"error generating module {m.get('module')}: {e}")
        #     continue

    # with Pool(processes=len(modules)) as pool:
    #     pool.map(g_module, modules)
    # g_module(modules[0])
if __name__ == '__main__':
    os.environ["POSTGRES_PORT"] = "5433"
    asyncio.run(gen_course('ja', 'he', '../data/content/ja_he/ja_he_course.yaml'))
    