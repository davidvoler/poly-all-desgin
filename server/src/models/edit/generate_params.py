from pydantic import BaseModel
from enum import Enum

class ContentSource(str, Enum):
    AI = "ai"
    CORPUS = "corpus"

class AiProvider(str, Enum):
    OLLAMA = "ollama"
    OPENAI = "openai"
    CLAUDE = "claude"

class CorpusNames(str, Enum):
    TATOEBA = "tatoeba"
    MIXED = "mixed"
    BIBLE = "bible"

class CourseGenParams(BaseModel):
    # source 
    content_source: ContentSource | None = ContentSource.AI
    corpus_name: CorpusNames | None = CorpusNames.TATOEBA
    model: AiProvider | None = AiProvider.OLLAMA
    # sentence and exercise generate
    max_sentences_words: int | None = 7
    min_sentences_words: int | None = 1
    distractor_similarity: float | None = 0.5
    # exercise percent types to generate
    single_choice: float | None = 0.9
    multiple_choice: float | None = 0.1
    identify_words: float | None = 0.1
    description: float | None = 0.0




    

