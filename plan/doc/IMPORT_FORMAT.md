# Import Format 

## Latest structure
```yaml 
title:  Lesson 2: もちろん
weight: 2
---
type: simple
text: これは逃してはならない絶好の機会だと彼は思った。
text_alt1: これのがしてはならないぜっこうきかいおもっ
text_alt2: kore nogashi tehanaranai zekkou kikai omotsu 
text_alt3: コレノガシテハナラナイゼッコウキカイオモッ
word1: 絶好
word2: 逃し
word3: 機会
sentence_id: 2879032332
to_sentence_id: 434349098
weight: 6
ruby_text: {"hiragana": [{"text": "\u3053\u308c"}, {"text": "\u9003\u3057", "ruby": "\u306e\u304c\u3057"}, {"text": "\u3066\u306f\u306a\u3089\u306a\u3044"}, {"text": "\u7d76\u597d", "ruby": "\u305c\u3063\u3053\u3046"}, {"text": "\u6a5f\u4f1a", "ruby": "\u304d\u304b\u3044"}, {"text": "\u601d\u3063", "ruby": "\u304a\u3082\u3063"}], "katakana": [{"text": "\u3053\u308c", "ruby": "\u30b3\u30ec"}, {"text": "\u9003\u3057", "ruby": "\u30ce\u30ac\u30b7"}, {"text": "\u3066\u306f\u306a\u3089\u306a\u3044", "ruby": "\u30c6\u30cf\u30ca\u30e9\u30ca\u30a4"}, {"text": "\u7d76\u597d", "ruby": "\u30bc\u30c3\u30b3\u30a6"}, {"text": "\u6a5f\u4f1a", "ruby": "\u30ad\u30ab\u30a4"}, {"text": "\u601d\u3063", "ruby": "\u30aa\u30e2\u30c3"}], "romanji": [{"text": "\u3053\u308c", "ruby": "kore"}, {"text": "\u9003\u3057", "ruby": "nogashi"}, {"text": "\u3066\u306f\u306a\u3089\u306a\u3044", "ruby": "tehanaranai"}, {"text": "\u7d76\u597d", "ruby": "zekkou"}, {"text": "\u6a5f\u4f1a", "ruby": "kikai"}, {"text": "\u601d\u3063", "ruby": "omotsu"}]}
annotations: [{"word": "\u6a5f\u4f1a", "translation": "\u05d4\u05d6\u05d3\u05de\u05e0\u05d5\u05d9\u05d5\u05ea"}]
[+] הוא חש שזו הזדמנות טובה מדי מכדי שיחמיץ אותה.
[-] טום שאל את מרי אם היא רוצה ללכת לקולנוע.
[-] כשהיא הייתה סטודנטית, היא הלכה לדיסקוטק רק פעם אחת.
---
```

### YAML Alternative 

```YAML
---
text: これは逃してはならない絶好の機会だと彼は思った。
text_alt1: これのがしてはならないぜっこうきかいおもっ
text_alt2: kore nogashi tehanaranai zekkou kikai omotsu 
text_alt3: コレノガシテハナラナイゼッコウキカイオモッ
word1: 絶好
word2: 逃し
word3: 機会
ruby_text: 
    hiragana:
        - text: これは
        - text: 逃
          ruby: は
annotation:
    - word: some word
      meaning: some meaning
      transliteration: some transliteration
      audio_link: https://....
options:
    - text:  הוא חש שזו הזדמנות טובה מדי מכדי שיחמיץ אותה.
      correct: true
    - text:  טום שאל את מרי אם היא רוצה ללכת לקולנוע.
    - text:  כשהיא הייתה סטודנטית, היא הלכה לדיסקוטק רק פעם אחת.
---
```YAML Simplified - Option 1 
---
text: これは逃してはならない絶好の機会だと彼は思った。
text_alt1: これのがしてはならないぜっこうきかいおもっ
text_alt2: kore nogashi tehanaranai zekkou kikai omotsu 
text_alt3: コレノガシテハナラナイゼッコウキカイオモッ
word1: 絶好
word2: 逃し
word3: 機会
base: これは
base: 逃
ruby: は
annotation: some word
meaning: some meaning
transliteration: some transliteration
audio_link: https://....
annotation: some word
meaning: some meaning
transliteration: some transliteration
audio_link: https://....
option:  הוא חש שזו הזדמנות טובה מדי מכדי שיחמיץ אותה.
correct: true
option:  טום שאל את מרי אם היא רוצה ללכת לקולנוע.
option:  כשהיא הייתה סטודנטית, היא הלכה לדיסקוטק רק פעם אחת.
---
```
This option is a real yaml 
However you can not use yaml lib to read it as order is important 
- correct refers to the last options 
- ruby refers to preceding base



### Idea and considerations  

we have now a combination of pseudo YAML and and some JSON
maybe for AI it would be easier to have only yaml  
The problem with YAML is that it is strict and if we let users edit it we may get lots of errors 
Is there anything like a forgiving YAML format - that tries the best guess?

When I look in the example above where we replace json with yaml - it makes sense but it could cause lots of errors 
when edited by non technical people. 
We can have the following options 
import format - full yaml intended for AI 
simplified format for people 
However in any case we would like that people will update the yaml files and and then we can have the problem again
Breaking the yaml into multiple sections verifies that you may have a mistake in one section but it will not affect other elements 



