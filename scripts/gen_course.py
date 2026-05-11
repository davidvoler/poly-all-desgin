

def words_per_modules():
    pass

def get_words_per_lesson(module_no):
    pass

def gen_greetings():
    pass 

def gen_modules(words:list[str]):
    pass

def gen_lesson(words:list[str]):
    pass

def gen_exercises(words:list[str]):
    pass


def create_exercise_listen(words:list[str]):
    pass

def create_exercise_annotation(words:list[str]):
    pass

def create_exercise_read(words:list[str]):
    pass

def create_exercise_to_lang(words:list[str]):
    pass

def gen_exercise(sentences:dict):
    """
    generate exercise based on the sentence
    TODO: add random - for some exercise types
    """
    w_count = sentences.get('word_count', 0)
    if w_count == 1:
        pass
        #single word exercise
    elif w_count == 2:
        pass
    elif w_count == 3:
        pass
    else:
        pass


async def gen_course():
    pass

