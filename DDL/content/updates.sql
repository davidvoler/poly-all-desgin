

create index idx_audio_lang_id on content_raw.audio (lang, id);


create index to_lang_to_id on content_raw.translation_links (to_lang, to_id)


create index lang_word1 on content_raw.sentence_elements (lang, word1)