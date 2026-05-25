

-- get lessons with user progress for a specific course
--# add course name and module name to the results

SELECT a.course,a.module,a.lesson_id,a.lesson_name, b.completed
FROM content.lessons a
LEFT JOIN user_data.results b ON a.id = b.lesson_id AND b.user_id = :user_id
WHERE a.course_id = :course_id
ORDER BY a.course, a.module, a.weight;


-- get user words 
SELECT count(a.word) FROM (
SELECT word, sum(correct) as sum_correct
FROM  user_data.results 
GROUP BY word
) as a WHERE  a.sum_correct > 0

-- get user sentences
SELECT count(a.sentence) FROM (
SELECT sentence, sum(correct) as sum_correct
FROM  user_data.results 
WHERE lang= :lang
GROUP BY sentence
) as a WHERE  a.sum_correct > 0

-- get users lessons 
SELECT count(distinct lesson_id) 
FROM user_data.results 
WHERE lang=:lang
AND user_id = :user_id



------------- get user course progress -----------------
-- get course lesson count
SELECT count(*) FROM content.lessons WHERE course_id = :course_id
-- get user completed lesson count
SELECT count(distinct lesson_id) as completed_lessons
FROM user_data.results 
WHERE lang=:lang
AND user_id = :user_id
AND completed = true
----------------------------------------------------------



-- get words with multiple words in results
SELECT count(a.word) FROM (
SELECT word1 as word, sum(correct) as sum_correct
FROM  user_data.results
WHERE user_id = :user_id
AND lang = :lang 
GROUP BY word
UNION ALL
SELECT word2 as word, sum(correct) as sum_correct
FROM  user_data.results
WHERE user_id = :user_id            
AND lang = :lang
GROUP BY word
UNION ALL
SELECT word3 as word, sum(correct) as sum_correct
FROM  user_data.results
WHERE user_id = :user_id            
AND lang = :lang
GROUP BY word
) as a WHERE  a.sum_correct > 0
