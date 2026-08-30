import json
from datetime import datetime
from urllib import request
from models.auth import SchoolUser
from utils.auth_deps import current_ai_school_user
from utils.generate import (
    generate_words, 
    generate_sentences,
    generate_translated_sentence_distractors)

from models.edit.generate_poc_new import (
    Course,
    CourseOption,
    CourseWord,
    GenerateForWords,
    Exercise,
    Lesson,
    Sentence,
    Sentences
)
from models.edit.exercise import ExerciseEdit,ExerciseType, Options
from utils.generate_exercise import (
    gen_single_choice_exercise,
    gen_identify_words
)

from fastapi import APIRouter, Depends, HTTPException
router = APIRouter()



async def _update_course(course:Course):
    """
    Updates an existing course based on the provided request.
    """
    sql = f"""
    UPDATE course_simple.course
    SET lang = %s,
        to_lang = %s,
        title = %s,
        description = %s,
        status = %s,
        level = %s,
        metadata = %s
    WHERE course_id = %s AND user_id = %s AND school_id = %s
    RETURNING course_id
        """
    params = (
            request.lang,
            request.to_lang,
            request.title,
            request.description,
            request.status,
            request.level or '',
            json.dumps({course.options.to_dict()}),
            request.course_id,
            school_user.user_id,
            school_user.school_id,
        )

    result = await get_query_results(sql, params)
    return course

async def _save_sentences(sentences:list):
    pass 

@router.post("/create_course", response_model=Course)
async def create_course(request: Course, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Creates a new course based on the provided request.
    """
    if not request.title:
        now = datetime.now()
        request.title = f"Course {request.lang or 'Unknown'} to {request.to_lang or 'Unknown'} school {school_user.school_name or 'Unknown'} speakers {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    
    sql = f"""
    INSERT INTO course_simple.course (lang, to_lang, user_id, school_id, title, description, status, level, metadata)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    RETURNING course_id
    """
    params = (
        request.lang,
        request.to_lang,
        school_user.user_id,
        school_user.school_id,
        request.title,
        request.description,
        'draft',
        request.level or '',
        json.dumps({course.options.to_dict()}),
    )
    course_id = await get_query_results(sql, params)
    course_id = course_id[0]['course_id'] if course_id else 0
    course.course_id = course_id
    return course


@router.post("/update_course", response_model=Course)
async def update_course(course: Course, school_user: SchoolUser = Depends(current_ai_school_user)):
    result = await _update_course(course)
    if not result:
        raise HTTPException(status_code=404, detail="Course not found")
    return course


@router.post("/generate_words_list", response_model=Course)
async def generate_words_list(course: Course, school_user: SchoolUser = Depends(current_ai_school_user)):
    """ Generate a words list for a given course.
    """
    words_so_far = [w.word for w in course.words] or []
    provider = course.options.provider
    model = course.options.model
    content_source = course.options.content_source
    words = await generate_words(course.lang, course.to_lang, words_so_far=words_so_far, level=course.level, 
                           content_source=content_source, provider=provider, model=model, max_words=course.options.max_sentences_words)
    max_weight = 0
    for w in course.words:
        max_weight = max(max_weight, w.weight)
    i = max_weight
    for w in words:
        course.words.append(CourseWord(word=w, weight=i, used=0))
        i+=1
    await _update_course(course)
    return course

@router.post("/sentences_for_word", response_model=list[Sentence])
async def sentences_for_word(generate: GenerateForWords, word: str, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Returns a list of sentences for a word
    TODO: 
    pass to this function 
    - min number of words 
    - max number of words 
    - number of sentences
    from course.options
    """
    course = generate.course
    words = generate.words
    max_words = course.options.max_words_per_sentence
    content_source = course.options.content_source
    provider = course.options.provider
    model = course.options.model
    results = []
    sentences_per_word = generate.num_elements//len(words)
    for i, w in enumerate(words):
        if i == len(words) - 1:
            num_sentences = generate.num_elements - len(results)
        else:
            num_sentences = sentences_per_word
            num_sentences = sentences_per_word
        sentences = await generate_sentences(lang=course.lang, 
                                             to_lang=course.to_lang, 
                                             word=w, 
                                             level=course.level, 
                                             content_source=content_source, 
                                             provider=provider, 
                                             model=model, 
                                             max_words=max_words, 
                                             num_sentences=num_sentences)
        results.extend([Sentence(sentences=s, word=w) for s in sentences])
    #TODO: update the sentences in some table 
    return results

@router.post("/exercise_for_word", response_model=list[ExerciseEdit])
async def exercise_for_word(generate: GenerateForWords, word: str, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    we create exercises for words 
    """
    course = generate.course
    words = generate.words
    provider = course.options.provider
    model = course.options.model
    content_source = course.options.content_source
    max_words = course.options.max_words_per_sentence
    num_sentences = generate.num_elements
    sentences_per_word = num_sentences // len(words)
    exercises = []
    for i, w in enumerate(words):
        num_sentences = sentences_per_word
        if i == len(words) - 1:
            num_sentences = generate.num_elements - len(exercises)
        sentenes_with_distractors = await generate_translated_sentence_distractors(
            lang = course.lang, 
            to_lang = course.to_lang, 
            word=w, 
            level=course.level, 
            content_source=content_source, 
            provider=provider, 
            model=model, 
            max_words=max_words, 
            num_sentences=course.options.max_sentences_words)
        for s in sentenes_with_distractors:
            sentence = s.get('sentence')
            translation = s.get('translation')
            distractors = s.get('distractors')
            exercises.append(gen_single_choice_exercise(sentence=sentence, translation=translation, distractors=distractors))
    return exercises

