

create index idx_audio_lang_id on content_raw.audio (lang, id);


create index to_lang_to_id on content_raw.translation_links (to_lang, to_id)


create index lang_word1 on content_raw.sentence_elements (lang, word1)


create table content_raw.secondary_words_translation (
    id int8 NOT NULL,
    lang varchar(12) NOT NULL,
    word varchar(300) NOT NULL,
    to_id int8 NOT NULL,
    to_lang varchar(12) NOT NULL,
    to_word varchar(300) NOT NULL,
    to_to_id int8 NOT NULL,
    to_to_lang varchar(12) NOT NULL,
    to_to_word varchar(300) NOT NULL,
    PRIMARY KEY (id, to_id, to_to_id)
);




insert into content_raw.secondary_words_translation
select se.id as id, 'ja' as lang,  w.word as word, s.id as to_id, 'en' as to_lang, s.text as to_word , s1.id as to_to_id, 'he' as to_to_lang,  s1.text as to_to_word 
from content_raw.words  w
join content_raw.sentence_elements se 
on w.word = se.text
join content_raw.translation_links tl  on se.id = tl.id and tl.lang = 'ja' and tl.to_lang = 'en'
join content_raw.sentences s on tl.to_id = s.id
join content_raw.translation_links tl1 on tl1.id = s.id and tl1.to_lang ='he' 
join content_raw.sentences s1 on tl1.to_id = s1.id 
where w.lang = 'ja' and se.lang = 'ja'
group by 1,2,3,4,5,6,7,8,9
on conflict(id,to_id,to_to_id) do nothing