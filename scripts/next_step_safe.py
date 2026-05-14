import yaml
from db import get_query_results
import random
import asyncio
words_for_recognize = set()
lesson_words = set()


def add_words_for_recognize(word):
    if len(word) > 3:
        words_for_recognize.add(word)


def add_lesson_words(word):
    if len(word) > 3:
        lesson_words.add(word)


async def get_sentences_voice(lang, sentence_id):
    sql = f"""SELECT recording FROM content_raw.audio WHERE lang = %s and id = {sentence_id}"""
    res = await get_query_results(sql, (lang,))
    if len(res) > 0:
        for r in res:
            return r.get('recording')
    return "" 

def simple_exercise(sentence:dict):
    options = []
    words = []

    return {
        'type': 'simple',    
        'sentence_id': sentence.get('id'),
        'sentence_to_id': sentence.get('id'),
        'options': options,
        'words': words,
        'voice': None,
    } 

def identify_words_exercise(sentence:dict):
    options = []
    words = []
    return {
        'type': 'simple',    
        'sentence_id': sentence.get('id'),
        'sentence_to_id': sentence.get('id'),
        'options': options,
        'words': words,
        'voice': None,
    } 

def understand_voice(sentence:dict):
    options = []
    words = []
    return {
        'type': 'understand_voice',    
        'sentence_id': sentence.get('id'),
        'sentence_to_id': sentence.get('id'),
        'options': options,
        'words': words,
        'voice': None,
    } 



async def gen_exercise(lang, to_lang, id, to_id, sentences_count):
    query = f"""
    select 
        lang.text as text, 
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
    
    for r in res:
        audio = await get_sentences_voice(lang, id)
        text, word1, word2, word3, options, to_text, to_options, id, to_id = r
        op = [{"text":o} for o in to_options]
        op.append({"text": to_text, "correct": True})
        random.shuffle(op)
        ex.append({
            'type': 'simple',    
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
    sentences_count = len(sentences)
    exercises = []
    for s in sentences:
        ex = await gen_exercise('ar', 'en', s.get('id'), s.get('to_id'), sentences_count)
        exercises.extend(ex)
    return {
        'lesson': l.get('lesson'),
        'title': "learning " + ", ".join(l.get('words', [])),
        'words': words,
        'exercises': exercises
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



async def gen_course(lang, to_lang, rank = False):
    module = yaml.safe_load(open(f'../data/content/{lang}_{to_lang}_course_short{"_by_rank" if rank else ""}.yaml', 'r'))
    modules = module.get('modules', [])
    gen_modules = []
    for m in modules:
        gen_m = await gen_module(m)
        gen_modules.append(gen_m)

        # module_no = int(m.get('module'))
        # print("module_no", module_no)
        # for l in m.get('lessons', {}):
        #     lesson_no = int(l.get('lesson').split()[1])
        #     print ("lesson_no", lesson_no)
        #     sentences = l.get('sentences', [])
        #     print("number of sentences", len(sentences))
    

    yaml.safe_dump({'modules': gen_modules}, open(f"../data/content/{lang}_{to_lang}_course_gen{'_by_rank' if rank else ''}.yaml", "w"), allow_unicode=True)

if __name__ == '__main__':
    asyncio.run(gen_course('ar', 'en', rank = False))