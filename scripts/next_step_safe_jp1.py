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


async def gen_exercise(lang, to_lang, id, to_id, sentences_count):
    
    
    
    query = f"""
    select 
        lang.text as text,
        lang.elements, 
        lang.word1 as word1,
        lang.word2 as word2,
        lang.word3 as word3,
        lang.words,
        lang.options as options,
        sentences.text as to_text, 
        sentences.options as to_options,
        trans.id as id, 
        trans.to_id as to_id
    from content_raw.sentence_elements lang
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
    # print(f"sentence count: {len(sent_trans)}")
    random.shuffle(sent_trans)
    r = sent_trans[0]
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
    # print(type(to_options), to_options)
    words_for_recognize.add(word1)
    words_for_recognize.add(word2)
    words_for_recognize.add(word3)
    random.shuffle(options)
    number_of_options = random.randint(2,4)
    options = options[:number_of_options]
    random.shuffle(to_options)
    to_options = to_options[:number_of_options]
    op = [{"text":o} for o in to_options]
    op.append({"text": to_text, "correct": True})
    random.shuffle(op)
    rnd= random.randint(0,10)
    if rnd < 1:
        if audio:
            if len(words_for_recognize)> 800:
                if len(words) >= 3:
                    w_correct = (word1, word2, word3)
                    w_wrong = random.sample(list(words_for_recognize), k=7)
                    all_words = list(set(w_correct + w_wrong))
                    opt = [{"text": w, "correct": w in w_correct} for w in all_words]
                    random.shuffle(opt)
                    opt = opt[:8]
                    ex.append({
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
                    })
                    return ex
    if rnd > 9 and len(words_for_recognize_split) > 1000:
        op = [{"text":o} for o in options]
        op.append({"text": text, "correct": True})
        ex.append({
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
        })
        return ex
    else:
        ex.append({
        'type': 'simple',    
        'text': text,
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
        ex = await gen_exercise('ja', 'en', s.get('id'), s.get('to_id'), sentences_count)
        # print(ex)
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
        try:
            gen_l = await gen_lesson(l)
            # words = gen_l.get('words', [])
            # module_words.extend(words)
            gen_lessons.append(gen_l)
        except Exception as e:
            print(f"error generating lesson {l.get('lesson')}: {e}")
            continue
    return {
        'module': m.get('module'),
        'lessons': gen_lessons
    }




async def gen_and_save_module(m:dict):
    print(f"generating module {m.get('module')}")
    module_no = int(m.get('module'))
    if len(os.listdir(f"../data/content/ja/v1/module_{module_no}")) > 0:
        print(f"module {m.get('module')} already exists, skipping")
        return
    gen_m =  await gen_module(m)
    os.makedirs(f"../data/content/ja/v1/module_{module_no}", exist_ok=True)
    i = 1
    for lesson in gen_m.get('lessons', []):
        # for key, value in lesson.items():
        #     print(f"{key}: {len(value)} {type(value)}")
        lesson_no = i
        weight = lesson.get('weight',lesson_no )

        title = lesson.get('title', '')
        with open(f"../data/content/ja/v1/module_{module_no}/lesson_{lesson_no}.txt", 'w') as f:
            title = lesson.get('lesson', '')
            f.write(f"title: {title}\n")
            f.write(f"weight: {weight}\n")
            for exercise in lesson.get('exercises', []):
                # print(f"{exercise}")
                f.write(f"---{exercise.get('type', '')}\n")
                f.write(f"{exercise.get('text')}\n")
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
                for o in options:
                    prefix = "[-]"
                    if o.get('correct'):
                        prefix = "[+]"
                    f.write(f"{prefix} {o.get('text')}\n")
        i += 1

def g_module(m:dict):
    asyncio.run(gen_and_save_module(m))

async def gen_course(lang, to_lang, load_path):
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
    asyncio.run(gen_course('ja', 'en', '../data/content/ja/v1/ja_en_course.yaml'))