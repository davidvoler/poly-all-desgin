from utils.db import get_query_results, run_query
from pydantic import BaseModel
"""
Utility functions for generating sentences, translations, and exercises.
We have the following ways to generate sentences 
"""



class GenerateOptions(BaseModel):
    generate_by:str = 'model' # model, corpus
    translate:str = 'google' # model, google, azure 
    max_w_count: int = 5
    min_w_count: int = 2





def gen_sentences(word:str, min_w_count:int, max_w_count:int)-> list[str]:
   # generate sentences for a word
   return []

def gen_translations(lang:str, to_lang:str, sentence:str) -> str:
   # translate a single sentence
   return ''

def sentence_info(sentence:str) -> dict:
   # get sentence info
   return {}

def gen_exercise(sentence:str, translations:str, exercise_type:str) -> dict:
   # generate an exercise
   return {}


def gen_exercise_for_words(words:list[str]) -> list[dict]:
    pass 


