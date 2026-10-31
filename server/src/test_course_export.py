import asyncio
from utils.course_export_from_db import export_course_from_db
from utils.course_import_to_db import course_to_db
import time
from utils.edit.part_utils import text_to_parts, get_ranked_words, srt_to_text, break_srt



def test_srt_to_sentences():
    srt_file = '../../data/content/srt/1LV0pU2U_hg_el.srt'
    full_text = srt_to_text(srt_file)
    # print("Full text:", full_text)
    sentences, parts = text_to_parts(full_text)
    # print("Sentences:", sentences)
    # print("Parts:", parts)
    ranked_words = get_ranked_words(full_text.split(), 'el', min_rank=550, max_rank=830)
    # print("Ranked words:", ranked_words)
    sentences_to_use = [s for s in sentences if len(s.split()) > 1 and len(s.split()) < 11]
    parts_to_use = [p for p in parts if len(p.split()) > 1 and len(p.split()) < 11]

    print('---- sentences to use ----')
    for s in sentences_to_use:
        print(s)

    print('---- parts to use ----')
    for p in parts_to_use:
        print(p)
    print('---- ranked words ----')
    for w in ranked_words:
        print(w)

    print("Sentences to use:", len(sentences_to_use), "Parts to use:", len(parts_to_use), "words to use", len(ranked_words))
    print("Sentences :", len(sentences), "Parts:", len(parts), "all_words", len(list(set(full_text.split()))))


if __name__ == "__main__":
    # start_time = time.time()
    # asyncio.run(course_to_db("../../data/content/exported_course_from_db.yaml", users_id=1, school_id=1))
    # end_time = time.time()
    # print(f"Execution time: {end_time - start_time} seconds")
    parts = break_srt('../../data/content/srt/1LV0pU2U_hg_el.srt', second_count=120)
    for p in parts:
        print(len(p.get("text")), p.get("start"),  p.get("end"))
        sentences, parts = text_to_parts(p.get("text"))
        words = get_ranked_words(p.get("text").split(), 'el', min_rank=550, max_rank=830)
        print("Sentences:", len(sentences), "Parts:", len(parts), "Words:", len(words))


    
    