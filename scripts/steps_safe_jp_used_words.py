from utils.db import get_query_results
import yaml
import asyncio
import random
import os 

LESSONS_PER_MODULE = 30

words_in_sentences = set()

MAX_SENTENCE_USE = 3
USED_SENTENCES = {}

words_used_times = {}


def add_words_used_times(word):
    global words_used_times
    if word in words_used_times:
        words_used_times[word] +=1
    else:
        words_used_times[word] =1

def get_words_used_times(words_so_far, max_limit= 1):
    # print("words_used_times:", words_used_times)
    max_use = 0
    max_word = None
    for k, v in words_used_times.items():
        if k not in words_so_far:
            if v >= max_use:
                max_use = v
                max_word = k
    if max_use >= max_limit and max_word is not None:
        return max_word
    return None

def get_next_words_to_use(words, words_so_far,  max_limit = 2):
    words_to_use =  get_words_used_times(words_so_far, max_limit)
    if words_to_use is not None and words_to_use in words:
        words.remove(words_to_use)
        print(f"reusing word {words_to_use} used {words_used_times[words_to_use]} times")
        return words_to_use
    if len(words) > 0:
        return words.pop(0)
    return None
    
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
    and rank > 320
    and 
    (w_count1_3>3 
    or w_count4_5 >2 
    or w_count6_9 >1 
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
    or w_count6_9 >5 
    or w_count10_20 >5)
    order by rank 
    offset 35
    """
    res = await get_query_results(sql, (lang,))
    return [r['word'] for r in res]

async def get_sentences_for_words(lang,to_lang,  word,min_words, max_words = 0, word_num = 1):
    sql = f"""
    select lang.text as text, sentences.text as to_text, trans.id as id, trans.to_id as to_id, lang.len_c as len_c, lang.word1 as word1, lang.word2 as word2, lang.word3 as word3
    from content_raw.sentence_elements lang
    join  content_raw.translation_links  trans
    on trans.id = lang.id and trans.lang = %s and trans.to_lang = %s
    join content_raw.sentences sentences
    on sentences.id = trans.to_id
    where sentences.lang = %s 
    and (lang.word1 = %s )
    order by lang.len_c asc
    limit 30
    """
    res = await get_query_results(sql, (lang, to_lang,to_lang, word))
    sentences  =  [{"text": r['text'], "to_text": r['to_text'], "id": r['id'], "to_id": r['to_id'], "word1": r['word1'], "word2": r['word2'], "word3": r['word3']} for r in res]
    for s in sentences:
        if s.get('word2'):
            add_words_used_times(s.get('word2'))
        if s.get('word3'):
            add_words_used_times(s.get('word3'))
    return sentences[:10]

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
        return 1,8
    elif words_so_far < 5000:
        return 1,10
    else:
        return 1,30


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
    
    print (words[:10])
    print(f"total words: {len(words)}")
    words_so_far = set()
    i =1
    lesson_no = 1
    unused_words = []
    # words = words[:100]
    while len(words) > 0:
        lesson_words = []
        sentences = []
        min_words, max_words = get_min_max_words_for_sentences(len(words_so_far))
        while len(sentences) < 10:
            w = get_next_words_to_use(words, words_so_far, max_limit=1)
            if w is None:
                break
            w_sentences = await get_sentences_for_words(lang, to_lang, w, min_words, max_words)
            if len(w_sentences) > 0:
                sentences.extend(w_sentences)
                lesson_words.append(w)
                words_so_far.add(w)
            else:
                print(f"no sentences for {w}")
                unused_words.append(w)
        if len(lesson_words) >2:
            lesson_title = f"Lesson {lesson_no}: {', '.join(lesson_words[:2])} ..."
        else:
            lesson_title = f"Lesson {lesson_no}: {', '.join(lesson_words)}"
        lesson_no += 1
        lesson = {
            'lesson': lesson_title,
            'words': lesson_words,
            'sentences': sentences,
            'weight': lesson_no,
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
            lesson_no = 1
        i+=1
    modules.append(module)
    print("unused words:", len(unused_words))
    yaml.safe_dump({'modules': modules}, open(f"../data/content/ja/v3/{lang}_{to_lang}_course{r}.yaml", "w"), allow_unicode=True)

    
if __name__ == "__main__":
    os.environ['POSTGRES_PORT'] = "5433"
    asyncio.run(generate_course_by_rank("ja", "en", rank=False))
    