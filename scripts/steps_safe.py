from db import get_query_results
import yaml
import asyncio
import random


LESSONS_PER_MODULE = 30

MAX_SENTENCE_USE = 1
USED_SENTENCES = {}


def add_sentences_to_used(s):
    global USED_SENTENCES
    if s in USED_SENTENCES:
        USED_SENTENCES[s] += 1
    else:
        USED_SENTENCES[s] = 1
    return USED_SENTENCES[s] - 1
    


def get_lessons_per_module(lesson_no):
    if lesson_no < 100:
        return 25
    elif lesson_no < 250:
        return 35
    elif lesson_no < 500:
        return 45
    elif lesson_no < 750:
        return 60
    elif lesson_no < 1000:
        return 70
    else:
        return 100


async def get_all_words(lang:str):
    sql = """
    select word from content_raw.words 
    where lang = %s
    and rank < 1000
    and rank > 450
    and 
    (w_count1_3>5 
    or w_count4_5 >4 
    or w_count6_9 >3 
    or w_count10_20 >0)
    order by w_count1_3  desc, w_count4_5 desc, w_count6_9  desc, w_count10_20 desc 
    """
    res =  await get_query_results(sql, (lang,))
    return [r['word'] for r in res]

async def get_all_words_by_rank(lang:str):
    sql = """
    select word, rank from content_raw.words 
    where lang = %s
    and rank < 1000
    and 
    (w_count1_3>5 
    or w_count4_5 >4 
    or w_count6_9 >3 
    or w_count10_20 >0)
    order by rank 
    offset 35
    """
    res = await get_query_results(sql, (lang,))
    return [r['word'] for r in res]




async def get_sentences_for_words(lang,to_lang,  word,min_words, max_words = 0, word_num = 1):
    sql = f"""
    select lang.text as text, sentences.text as to_text, trans.id as id, trans.to_id as to_id
    from content_raw.sentence_elements_simple2 lang
    join  content_raw.translation_links  trans
    on trans.id = lang.id and trans.lang = %s and trans.to_lang = %s
    join content_raw.sentences sentences
    on sentences.id = trans.to_id
    where sentences.lang = %s 
    and (lang.word1 = %s or lang.word2 = %s or lang.word3 = %s)
    """
    res = await get_query_results(sql, (lang, to_lang,to_lang, word, word, word))
    # res =  [(r['text'], r['to_text'], r['id'], r['to_id']) for r in res]
    selected_sentences = []
    for r in res:
        txt = r.get('text')
        num_words = len(txt.split())
        if num_words < min_words or (max_words > 0 and num_words > max_words):
            continue
        if add_sentences_to_used(r['id']) < MAX_SENTENCE_USE:
            selected_sentences.append(r)
    random.shuffle(selected_sentences)
    return selected_sentences[:10]


def words_per_lesson(words_count):
    if words_count < 500:
        return 1
    elif words_count < 800:
        return 2
    elif words_count < 1200:
        return 3
    elif words_count < 1500:
        return 4
    elif words_count < 2000:
        return 5
    elif words_count < 2500:
        return 6
    elif words_count < 3000:
        return 10
    elif words_count < 4000:
        return 15
    else:
        return 20

def is_arabic(text):
    for ch in text:
        if '\u0600' <= ch <= '\u06FF' or '\u0750' <= ch <= '\u077F' or '\u08A0' <= ch <= '\u08FF':
            return True
    return False

def get_sort_for_sentences():
    if lesson_no < 700:
        return "order by len_c"
    elif lesson_no < 1400:
        return "order by len_elm "
    elif lesson_no < 2100:
        return ""

def get_min_max_words_for_sentences(words_so_far):
    if words_so_far < 300:
        return 1,3
    elif words_so_far < 600:
        return 1,4
    elif words_so_far < 1200:
        return 1,5
    elif words_so_far < 1800:
        return 1,6
    elif words_so_far < 3000:
        return 2,8
    elif words_so_far < 5000:
        return 3,10
    else:
        return 4,30

async def generate_course_by_rank(lang: str, to_lang:str, rank = False):
    r = "_by_rank" if rank else ""
    modules = []
    module_no = 1
    module = {
        'module': module_no,
        'lessons': []
    }
    if rank:
        words = await get_all_words_by_rank(lang)
    else:
        words = await get_all_words(lang)
    
    # print (words[:10])
    words_so_far = []
    i =1
    words_to_use = []
    for w in words:
        if  is_arabic(w):
            words_to_use.append(w)
    words = words_to_use
    
    unused_words = []
    # words = words[:100]
    while len(words) > 0:
        lesson_words = []
        sentences = []
        min_words, max_words = get_min_max_words_for_sentences(len(words_so_far))
        while len(sentences) < 10:
            try:
                w = words.pop(0)
            except IndexError:
                break
            w_sentences = await get_sentences_for_words(lang, to_lang, w, min_words, max_words)
            if len(w_sentences) > 0:
                sentences.extend(w_sentences)
                lesson_words.append(w)
                words_so_far.append(w)
            else:
                print(f"no sentences for {w}")
                unused_words.append(w)
        if len(lesson_words) >4:
            lesson_title = f"words: {', '.join(lesson_words[:3])} ..."
        else:
            lesson_title = f"words: {', '.join(lesson_words)}"
        lesson = {
            'lesson': lesson_title,
            'words': lesson_words,
            'sentences': sentences
        }
        
        module['lessons'].append(lesson)
        lessons_per_module = get_lessons_per_module(i)
        if i % lessons_per_module == 0:
            modules.append(module)
            module_no += 1
            module = {
                'module': module_no,
                'lessons': []
            }
        i+=1
    modules.append(module)
    print("unused words:", len(unused_words))
    yaml.safe_dump({'modules': modules}, open(f"../data/content/gen_v3/{lang}_{to_lang}_course{r}.yaml", "w"), allow_unicode=True)

    
if __name__ == "__main__":
    asyncio.run(generate_course_by_rank("ar", "en", rank=False))
    