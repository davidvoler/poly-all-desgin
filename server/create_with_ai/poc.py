#UI/Prompt
""" UI Prompt Is mainly done in flutter 
We can try and detect language using the language_detector package in flutter.
https://pub.dev/packages/language_detector/example
Simple calculation of costs can be also done in flutter
"""

#EnrichmentLayer

def enrichment(prompt: str) -> str:
    """Add results format.
    Return the enriched prompt.
    """
    pass

#Cache
def get_from_cache(words: list[str] = []) -> dict:
    #Get from cache
    pass


#ExternalModel

def get_model_response(prompt: str, provider: str = 'claude', model:str = 'default') -> dict:
    """Get response from external model.
    
    Returns a dictionary containing the model's response.
    """
    pass


#Translation
def translate_text(text: list[str], target_lang: str, source_lang: str = 'auto') -> list[dict]:
    #Translates list of sentences to target language
    pass

#TextToSpeech
def test_to_mp3(text: str, lang: str, voice: str = 'default') -> str:
    """
    Converts text to mp3 using text-to-speech 
    Save to a location 
    Save to the database
    Returns the path to the generated mp3 file.
    """
    pass

#GenExercise

def generate_exercise(sentences: list[str]) -> dict:
    """
    Generates exercises based on the provided sentences.
    Save the Exercise to the database - as draft

    Returns a dictionary containing the generated exercises.
    """
    pass

#SelectWords
def select_words(lang:str, to_lang:str, limit: int) -> list[str]:
    """Makes a list of words for the current context.
    Returns a list of words.
    """
    pass

#InternalLogic
def sentence_details(sentence: str, lang: str) -> dict:
    """
    Analyzes a sentence and returns its details.
    Returns a dictionary containing the sentence details.
    """
    pass


#CostsEvaluator

def estimate_cost(prompt:str, lang: str) -> float:
    pass 

def estimate_tokens(prompt:str, lang: str) -> float:
    # Quick estimation rule: ~4 characters ≈ 1 token (English)
    return len(prompt) / 4

