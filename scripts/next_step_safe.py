import yaml
from db import get_query_results
import random
import asyncio
words_for_recognize = set()
words_for_recognize_split = set()
lesson_words = set()
import sys
import unicodedata
from multiprocessing import Pool


_PUNCT = "".join(
    chr(i) for i in range(sys.maxunicode)
    if unicodedata.category(chr(i)).startswith("P")
)

def strip_punctuation(word):
    return word.strip(_PUNCT)

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





async def gen_exercise(lang, to_lang, id, to_id, sentences_count):
    query = f"""
    select 
        lang.text as text,
        lang.text_alt1, 
        lang.text_alt2, 
        lang.word1 as word1,
        lang.word2 as word2,
        lang.word3 as word3,
        lang.options as options,
        sentences.text as to_text, 
        sentences.options as to_options,
        trans.id as id, 
        trans.to_id as to_id
    from content_raw.sentence_elements_simple2 lang
    join  content_raw.translation_links  trans
    on trans.id = lang.id and trans.lang = %s and trans.to_lang = %s
    join content_raw.sentences sentences
    on sentences.id = trans.to_id
    where sentences.id = %s and lang.id = %s
    """
    res = await get_query_results(query, (lang, to_lang, to_id, id))
    ex = []
    if len(res) == 0:
        return []
    sent_trans = []
    for r in res:
        sent_trans.append(r)
    print(f"sentence count: {len(sent_trans)}")
    random.shuffle(sent_trans)
    r = sent_trans[0]
    audio = await get_sentences_voice(lang, id)
    text = r.get('text')
    text_alt1 = r.get('text_alt1')
    text_alt2 = r.get('text_alt2')
    word1 = r.get('word1')
    word2 = r.get('word2')
    word3 = r.get('word3')
    options = r.get('options', [])
    to_text = r.get('to_text')
    to_options = r.get('to_options', [])
    # print(type(to_options), to_options)
    random.shuffle(options)
    options = options[:4]
    random.shuffle(to_options)
    to_options = to_options[:4]
    op = [{"text":o} for o in to_options]
    op.append({"text": to_text, "correct": True})
    split_words = text.split()
    split_words = [strip_punctuation(w) for w in split_words]
    for w in split_words:
        add_words_for_recognize(w)
    random.shuffle(op)
    rnd= random.randint(0,10)
    if rnd < 2:
        if audio:
            if len(words_for_recognize)> 10:
                if len(split_words) >= 3:
                    w_correct = random.sample(split_words, k=2)
                    w_wrong = random.sample(list(words_for_recognize), k=4)
                    all_words = list(set(w_correct + w_wrong))
                    opt = [{"text": w, "correct": w in w_correct} for w in all_words]
                    ex.append({
                        'type': 'recognize',
                        'text': text,
                        'to_text': to_text,
                        'options': opt,
                        'voice': audio,
                        'sentence_id': id,
                        'sentence_to_id': to_id,
                        'word1': word1, 
                        'word2': word2, 
                        'word3': word3,
                    })
    elif rnd > 8:
        op = [{"text":o} for o in options]
        op.append({"text": text, "correct": True})
        ex.append({
            'type': 'read',    
            'text': to_text,
            'options': op,
            'voice': audio,
            'sentence_id': id,
            'sentence_to_id': to_id,
            'word1': word1, 
            'word2': word2, 
            'word3': word3,
        })
    else:
        ex.append({
        'type': 'simple',    
        'text': text_alt1,
        'options': op,
        'voice': audio,
        'sentence_id': id,
        'sentence_to_id': to_id,
        'word1': word1, 
        'word2': word2, 
        'word3': word3,
    })
    return ex


async def gen_lesson(l:dict):
    sentences = l.get('sentences', [])
    words = l.get('words', [])
    for w in words:
        add_lesson_words(w)
    sentences_count = len(sentences)
    exercises = []
    for s in sentences:
        ex = await gen_exercise('ar', 'en', s.get('id'), s.get('to_id'), sentences_count)
        exercises.extend(ex)
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
        module_words.extend(words)
        gen_lessons.append(gen_l)
    return {
        'module': m.get('module'),
        'lessons': gen_lessons
    }


async def gen_and_save_module(m:dict):
    gen_m =  await gen_module(m)
    module_no = int(m.get('module'))
    yaml.safe_dump({'modules': [gen_m]}, open(f"../data/content/gen_v2/module_{module_no}.yaml", "w"), allow_unicode=True)
def g_module(m:dict):
    asyncio.run(gen_and_save_module(m))

def gen_course(lang, to_lang, rank = False):
    module = yaml.safe_load(open(f'../data/content/gen_v3/{lang}_{to_lang}_course.yaml', 'r'))
    modules = module.get('modules', [])[:2]
    with Pool(processes=len(modules)) as pool:
        pool.map(g_module, modules)
if __name__ == '__main__':
    asyncio.run(gen_course('ar', 'en', rank = False))