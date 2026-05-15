--select lang, count(*) from content_raw.sentence_elements_simple1  group by 1
select count(*) from content_raw.words 
where lang = 'ar'
and rank < 1000
and 
(w_count1_3> 4 
or w_count4_5 >3 
or w_count6_9 >2 
or w_count10_20 >0)
order by w_count1_3  desc, w_count4_5 desc, w_count6_9  desc, w_count10_20 desc 






select lang.*, sentences.*
from content_raw.sentence_elements_simple2 lang
join  content_raw.translation_links  trans
on trans.id = lang.id and trans.lang = 'ar' and trans.to_lang = 'en'
join content_raw.sentences sentences
on sentences.id = trans.to_id 
group by lang.text, sentences.text






create index idx_sentence_elements_simple2_lang on content_raw.sentence_elements_simple2 (lang, word1, word2, word3, len_elm);