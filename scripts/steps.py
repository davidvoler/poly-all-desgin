from db import get_query_results
import asyncio
import random

LESSONS_PER_MODULE = 10


def get_greetings_words():
    return [
        "مرحبا",
        "أهلا",
        "السلام عليكم",
        "صباح الخير",
        "مساء الخير",
        "كيف حالك؟",            
    ]

async def get_all_words(lang:str):
    sql = """
    select word from content_raw.words 
    where lang = %s
    and rank < 1000
    and 
    (w_count1_3>5 
    or w_count4_5 >4 
    or w_count6_9 >3 
    or w_count10_20 >1)
    order by w_count1_3  desc, w_count4_5 desc, w_count6_9  desc, w_count10_20 desc 
    offset 50
    """
    return await get_query_results(sql, (lang,))

async def get_all_words_by_rank(lang:str):
    sql = """
    select word, rank from content_raw.words 
    where lang = %s
    and rank < 1000
    and 
    (w_count1_3>5 
    or w_count4_5 >4 
    or w_count6_9 >3 
    or w_count10_20 >1)
    order by rank 
    offset 35
    """
    res = await get_query_results(sql, (lang,))
    return [r['word'] for r in res]

async def get_sentences_for_words(lang,to_lang,  word, max_words = 0):
    sql = f"""
    select lang.text as text, sentences.text as to_text, trans.id as id, trans.to_id as to_id
    from content_raw.sentence_elements_simple2 lang
    join  content_raw.translation_links  trans
    on trans.id = lang.id and trans.lang = %s and trans.to_lang = %s
    join content_raw.sentences sentences
    on sentences.id = trans.to_id
    where sentences.lang = %s 
    and (lang.word1 = %s or lang.word2 = %s)
    limit 30
    """
    res = await get_query_results(sql, (lang, to_lang,to_lang, word, word))
    # res =  [(r['text'], r['to_text'], r['id'], r['to_id']) for r in res]
    selected_sentences = []
    for r in res:
        txt = r['text']
        if max_words > 0 and len(txt.split()) > max_words:
            continue
        selected_sentences.append((r['text'], r['to_text'], r['id'], r['to_id']))
    random.shuffle(selected_sentences)
    return selected_sentences[:12]


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



def get_sort_for_sentences():
    if lesson_no < 700:
        return "order by len_c"
    elif lesson_no < 1400:
        return "order by len_elm "
    elif lesson_no < 2100:
        return ""

def get_max_words_for_sentences(words_so_far):
    if words_so_far < 200:
        return 3
    elif words_so_far < 400:
        return 4
    elif words_so_far < 600:
        return 5
    elif words_so_far < 800:
        return 6
    elif words_so_far < 1000:
        return 8
    elif words_so_far < 1200:
        return 10
    else:
        return 0

def get_sentence_audio(sentences_id, lang):
    pass


async def generate_course(lang: str, to_lang:str):
    module = 1
    words = await get_all_words(lang)
    words_so_far = []
    i =1
    with open(f"{lang}_{to_lang}_course.txt", "w") as f:
        while len(words) > 0:
            wc = words_per_lesson(len(words_so_far))
            words_so_far += words[:wc]
            lesson_words = words[:wc]
            words = words[wc:]
            if i % LESSONS_PER_MODULE == 0:
                module += 1
            f.write(f"AR-EN Module {module} - Lesson {i} words: {lesson_words} words so far {len(words_so_far)} \n ")
            i+=1

        
async def generate_course_by_rank(lang: str, to_lang:str, rank = False):
    r = "_by_rank" if rank else ""
    with open(f"{lang}_{to_lang}_course{r}.yaml", "w") as f:
        
        module = 1
        f.write(f"module: {module} \n")
        if rank:
            words = await get_all_words_by_rank(lang)
        else:
            words = await get_all_words(lang)
        
        # print (words[:10])
        words_so_far = []
        i =1
        while len(words) > 0:
            
            wc = words_per_lesson(len(words_so_far))
            words_so_far += words[:wc]
            lesson_words = words[:wc]
            sentences = []
            for w in lesson_words:
                sentences += await get_sentences_for_words(lang, to_lang, w, max_words = get_max_words_for_sentences(len(words_so_far)))
            # print(sentences)
            lesson_words = words[:wc]
            words = words[wc:]
            if i % LESSONS_PER_MODULE == 0:
                module += 1
                f.write(f"module: {module} \n")
            f.write(f"\tLesson: {i}\n ")
            f.write(f"\t\twords:\n")
            for w in lesson_words:
                f.write(f"\t\t- {w}\n")                 
            f.write(f"\t\tsentences:\n")

            for s in sentences:
                f.write(f"\t\t- {lang}_id: {s[2]}\n")
                f.write(f"\t\t  {lang}_text: {s[0]}\n")
                f.write(f"\t\t  {to_lang}_id: {s[3]}\n")
                f.write(f"\t\t  {to_lang}_text: {s[1]}\n")
            i+=1

if __name__ == "__main__":
    # asyncio.run(generate_course("ar", "en"))
    asyncio.run(generate_course_by_rank("ar", "en", rank=True))
    